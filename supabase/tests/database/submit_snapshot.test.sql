-- Envío atómico de un snapshot a revisión (CRP-04b).
--
-- `submit_draft_snapshot` es la única vía para que un borrador llegue a
-- Supabase: crea o reemplaza la fila como `in_review` en una sola operación,
-- ligada al usuario de la sesión e idempotente por `submission_id`.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- now() es fijo dentro de la transacción, así que para probar "no modifica" se
-- fija un submitted_at antiguo como superusuario y se comprueba que sobrevive.

delete from public.cases;

insert into auth.users (id, email, aud, role) values
  ('11111111-1111-1111-1111-111111111111', 'ivan@example.test', 'authenticated', 'authenticated'),
  ('22222222-2222-2222-2222-222222222222', 'otro@example.test', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'revisor@example.test', 'authenticated', 'authenticated');

insert into public.reviewers (user_id)
values ('33333333-3333-3333-3333-333333333333');

-- Borrador ajeno ya existente (de "otro").
insert into public.drafts (id, owner, payload, status) values
  ('draft-otro', '22222222-2222-2222-2222-222222222222',
   '{"draftId": "draft-otro", "title": "Otro"}', 'draft');

-- ------------------------------------------------------------------- anon
set local role anon;
select set_config('request.jwt.claims', '{"role": "anon"}', true);
select throws_ok(
  $$select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000001', '{"draftId": "draft-a", "title": "A"}')$$,
  '42501', null, 'anon no puede ejecutar el envío');

-- ------------------------------------------------- sesión sin usuario (sub)
reset role;
set local role authenticated;
select set_config('request.jwt.claims', '{"role": "authenticated"}', true);
select throws_ok(
  $$select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000001', '{"draftId": "draft-a", "title": "A"}')$$,
  '42501', null, 'sin usuario identificado el envío falla');

-- --------------------------------------------------------------------- Iván
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select is(
  (select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000001',
    '{"draftId": "draft-a", "title": "A v1"}') ->> 'status'),
  'in_review', 'el primer envío devuelve in_review');
select is((select count(*) from public.drafts where id = 'draft-a')::int, 1,
  'el primer envío crea la fila');
select is((select status::text from public.drafts where id = 'draft-a'), 'in_review',
  'la fila creada queda en revisión');
select is((select owner from public.drafts where id = 'draft-a'),
  '11111111-1111-1111-1111-111111111111'::uuid, 'el dueño es quien envía');
select is((select submission_id from public.drafts where id = 'draft-a'),
  'aaaaaaaa-0000-0000-0000-000000000001'::uuid, 'se guarda el submission_id');
select isnt((select submitted_at from public.drafts where id = 'draft-a'), null,
  'se guarda submitted_at');

-- Reintento tras perder la respuesta: mismo submission_id, mismo payload.
reset role;
update public.drafts set submitted_at = '2020-01-01T00:00:00Z' where id = 'draft-a';
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select is(
  ((select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000001',
    '{"title": "A v1", "draftId": "draft-a"}') ->> 'submitted_at')::timestamptz),
  '2020-01-01T00:00:00Z'::timestamptz, 'el reintento idempotente devuelve el submitted_at actual');
select is((select count(*) from public.drafts where id = 'draft-a')::int, 1,
  'el reintento no duplica la fila');
select is((select submitted_at from public.drafts where id = 'draft-a'),
  '2020-01-01T00:00:00Z'::timestamptz, 'el reintento no modifica submitted_at');

select throws_ok(
  $$select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000001', '{"draftId": "draft-a", "title": "A distinto"}')$$,
  '22023', null, 'mismo submission_id con otro payload falla');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000002', '{"draftId": "draft-a", "title": "A v2"}')$$,
  '55000', null, 'otro submission_id mientras está en revisión falla');
select is((select payload ->> 'title' from public.drafts where id = 'draft-a'), 'A v1',
  'el envío rechazado no toca el payload');

-- Aislamiento: otro usuario.
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);
select throws_ok(
  $$select public.submit_draft_snapshot('draft-a', 'bbbbbbbb-0000-0000-0000-000000000001', '{"draftId": "draft-a", "title": "Robo"}')$$,
  '42501', null, 'otro usuario no puede enviar sobre el borrador de Iván');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000001', '{"draftId": "draft-a", "title": "A v1"}')$$,
  '42501', null, 'otro usuario no recibe el estado de un envío idempotente ajeno');
select is((select count(*) from public.drafts where id = 'draft-a')::int, 0,
  'otro usuario no ve el borrador de Iván');

-- Revisor: lee, pero no usa la función sobre borradores ajenos.
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true);
select is((select count(*) from public.drafts where id = 'draft-a')::int, 1,
  'el revisor lee lo que está en revisión');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-a', 'cccccccc-0000-0000-0000-000000000001', '{"draftId": "draft-a", "title": "Revisor"}')$$,
  '42501', null, 'el revisor no puede enviar sobre el borrador de Iván');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-otro', 'cccccccc-0000-0000-0000-000000000002', '{"draftId": "draft-otro", "title": "Revisor"}')$$,
  '42501', null, 'el revisor no puede enviar sobre borradores de otro autor');
select lives_ok($$select public.return_draft('draft-a')$$, 'el revisor devuelve');

-- Reenvío tras devolver.
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select is(
  (select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000001',
    '{"draftId": "draft-a", "title": "A v1"}') ->> 'status'),
  'returned', 'reintentar un envío ya aceptado devuelve el estado actual (devuelto)');
select is((select status::text from public.drafts where id = 'draft-a'), 'returned',
  'el reintento idempotente no reabre un borrador devuelto');

select is(
  (select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000003',
    '{"draftId": "draft-a", "title": "A v2"}') ->> 'status'),
  'in_review', 'reenviar tras devolver vuelve a revisión');
select is((select payload ->> 'title' from public.drafts where id = 'draft-a'), 'A v2',
  'el reenvío reemplaza el payload');
select is((select submission_id from public.drafts where id = 'draft-a'),
  'aaaaaaaa-0000-0000-0000-000000000003'::uuid, 'el reenvío guarda el nuevo submission_id');
select cmp_ok((select submitted_at from public.drafts where id = 'draft-a'), '>',
  '2020-01-01T00:00:00Z'::timestamptz, 'el reenvío renueva submitted_at');

-- Publicado: el reenvío conserva slug y caso.
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true);
select lives_ok($$select public.approve_draft('draft-a', '{"slug": "caso-a", "title": "A v2"}')$$,
  'el revisor aprueba');

reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select is(
  (select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000003',
    '{"draftId": "draft-a", "title": "A v2"}') ->> 'status'),
  'published', 'reintentar un envío ya publicado devuelve published sin tocar nada');
select is(
  (select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000004',
    '{"draftId": "draft-a", "title": "A v3"}') ->> 'status'),
  'in_review', 'reenviar un publicado vuelve a revisión');
select is((select published_slug from public.drafts where id = 'draft-a'), 'caso-a',
  'el reenvío conserva published_slug');
select is((select payload ->> 'title' from public.cases where slug = 'caso-a'), 'A v2',
  'el caso publicado no cambia hasta aprobar la nueva versión');

-- Un borrador en estado draft (p. ej. tras despublicar) también se reemplaza.
reset role;
update public.drafts set status = 'draft' where id = 'draft-a';
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select is(
  (select public.submit_draft_snapshot('draft-a', 'aaaaaaaa-0000-0000-0000-000000000005',
    '{"draftId": "draft-a", "title": "A v4"}') ->> 'status'),
  'in_review', 'un borrador en estado draft se reemplaza y pasa a revisión');

-- ------------------------------------------------------- validación payload
select throws_ok(
  $$select public.submit_draft_snapshot('draft-v', 'dddddddd-0000-0000-0000-000000000001', '{"draftId": "draft-v"}')$$,
  '22023', null, 'payload sin title falla');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-v', 'dddddddd-0000-0000-0000-000000000001', '{"draftId": "draft-v", "title": "  "}')$$,
  '22023', null, 'title vacío falla');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-v', 'dddddddd-0000-0000-0000-000000000001', '{"draftId": "draft-v", "title": 5}')$$,
  '22023', null, 'title que no es texto falla');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-v', 'dddddddd-0000-0000-0000-000000000001', '["draft-v"]')$$,
  '22023', null, 'payload que no es objeto falla');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-v', 'dddddddd-0000-0000-0000-000000000001', null)$$,
  '22023', null, 'payload nulo falla');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-v', 'dddddddd-0000-0000-0000-000000000001', '{"draftId": "otro-id", "title": "V"}')$$,
  '22023', null, 'draftId distinto del id falla');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-v', 'dddddddd-0000-0000-0000-000000000001', '{"title": "V"}')$$,
  '22023', null, 'payload sin draftId falla');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-v', null, '{"draftId": "draft-v", "title": "V"}')$$,
  '22023', null, 'submission_id nulo falla');
select throws_ok(
  $$select public.submit_draft_snapshot('draft-v', 'dddddddd-0000-0000-0000-000000000001',
      jsonb_build_object('draftId', 'draft-v', 'title', 'V', 'pad', repeat('x', 500000)))$$,
  '22023', null, 'payload de más de 500000 bytes falla');
select is((select count(*) from public.drafts where id = 'draft-v')::int, 0,
  'los envíos inválidos no dejan filas');

-- --------------------------------------- escrituras directas ya no existen
select throws_ok($$insert into public.drafts (id, payload) values ('draft-d', '{"draftId": "draft-d", "title": "D"}')$$,
  '42501', null, 'insertar directamente en drafts falla por privilegios');
select throws_ok($$update public.drafts set payload = '{"title": "x"}' where id = 'draft-a'$$,
  '42501', null, 'actualizar directamente drafts falla por privilegios');
select throws_ok($$update public.drafts set status = 'draft' where id = 'draft-a'$$,
  '42501', null, 'cambiar el estado escribiendo la columna falla por privilegios');
select throws_ok($$delete from public.drafts where id = 'draft-a'$$,
  '42501', null, 'borrar directamente en drafts falla por privilegios');
select is((select count(*) from public.drafts)::int, 1,
  'el autor sólo ve lo suyo');

-- ------------------------------------------------------- contrato de SQL
reset role;
select hasnt_function('public', 'submit_draft', array['text'],
  'submit_draft(text) ya no existe');
select ok(not has_table_privilege('authenticated', 'public.drafts', 'insert')
  and not has_table_privilege('authenticated', 'public.drafts', 'update')
  and not has_table_privilege('authenticated', 'public.drafts', 'delete')
  and has_table_privilege('authenticated', 'public.drafts', 'select'),
  'authenticated sólo conserva select sobre drafts');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename = 'drafts')::int, 1,
  'sólo queda la política de lectura en drafts');

select * from finish();
rollback;
