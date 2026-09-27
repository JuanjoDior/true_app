-- Reglas de acceso del flujo de revisión y publicación (CRP-01).
--
-- Tres actores: visitante anónimo, Iván (autor de borradores) y el revisor.
-- Cada bloque cambia de rol con `set local role` y fija `sub` en los claims
-- del JWT, que es lo que lee `auth.uid()` en las políticas.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- Filas afectadas por una sentencia, ejecutada con el rol actual: RLS
-- filtra en silencio (0 filas) en vez de lanzar un error.
create function pg_temp.affected(p_sql text)
returns int
language plpgsql
as $$
declare
  n int;
begin
  execute p_sql;
  get diagnostics n = row_count;
  return n;
end;
$$;

-- ---------------------------------------------------------------- datos base
insert into auth.users (id, email, aud, role) values
  ('11111111-1111-1111-1111-111111111111', 'ivan@example.test', 'authenticated', 'authenticated'),
  ('22222222-2222-2222-2222-222222222222', 'otro@example.test', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'revisor@example.test', 'authenticated', 'authenticated');

insert into public.reviewers (user_id)
values ('33333333-3333-3333-3333-333333333333');

insert into public.cases (slug, payload)
values ('zodiac', '{"slug": "zodiac", "title": "Zodiac"}');

-- Otro borrador ya publicado (de "otro"), para probar que no se pisa.
insert into public.drafts (id, owner, payload, status, published_slug) values
  ('draft-otro', '22222222-2222-2222-2222-222222222222', '{"title": "Otro"}', 'published', 'caso-otro');
insert into public.cases (slug, payload, source_draft_id)
values ('caso-otro', '{"slug": "caso-otro", "title": "Otro"}', 'draft-otro');

-- ------------------------------------------------------------------ anónimo
set local role anon;
select set_config('request.jwt.claims', '{"role": "anon"}', true);

select is((select count(*) from public.cases)::int, 2,
  'anon lee los casos publicados');
select throws_ok('select * from public.drafts', '42501', null,
  'anon no puede leer borradores');
select throws_ok($$insert into public.cases (slug, payload) values ('x', '{"slug": "x"}')$$,
  '42501', null, 'anon no puede publicar casos');
select throws_ok('select * from public.reviewers', '42501', null,
  'anon no puede leer la lista de revisores');

-- --------------------------------------------------------------------- Iván
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select lives_ok($$insert into public.drafts (id, payload) values ('draft-ivan', '{"title": "Caso nuevo"}')$$,
  'Iván crea su borrador');
select is((select owner from public.drafts where id = 'draft-ivan'),
  '11111111-1111-1111-1111-111111111111'::uuid,
  'el dueño se asigna solo a quien lo crea');
select is((select status::text from public.drafts where id = 'draft-ivan'), 'draft',
  'un borrador nuevo empieza en estado draft');
select throws_ok($$insert into public.drafts (id, owner, payload) values ('draft-x', '22222222-2222-2222-2222-222222222222', '{}')$$,
  '42501', null, 'Iván no puede crear borradores a nombre de otro');
select throws_ok($$insert into public.drafts (id, payload, status) values ('draft-y', '{}', 'published')$$,
  '42501', null, 'Iván no puede crear un borrador ya publicado');
select is((select count(*) from public.drafts where id = 'draft-otro')::int, 0,
  'Iván no ve borradores de otros');
select throws_ok('select * from public.reviewers', '42501', null,
  'Iván no puede leer la lista de revisores');
select throws_ok($$insert into public.cases (slug, payload) values ('x', '{"slug": "x"}')$$,
  '42501', null, 'Iván no puede publicar escribiendo en cases');
select throws_ok($$update public.cases set payload = '{"slug": "zodiac"}' where slug = 'zodiac'$$,
  '42501', null, 'Iván no puede modificar casos publicados');
select throws_ok($$delete from public.cases where slug = 'zodiac'$$,
  '42501', null, 'Iván no puede borrar casos publicados');
select throws_ok($$update public.drafts set published_slug = 'zodiac' where id = 'draft-ivan'$$,
  '42501', null, 'Iván no puede fijar el slug publicado');

select lives_ok($$select public.submit_draft('draft-ivan')$$,
  'Iván envía su borrador a revisión');
select is((select status::text from public.drafts where id = 'draft-ivan'), 'in_review',
  'el borrador queda en revisión');
select throws_ok($$select public.submit_draft('draft-ivan')$$, '55000', null,
  'no se puede reenviar un borrador que ya está en revisión');
select is(pg_temp.affected($q$update public.drafts set payload = '{"title": "Cambio"}' where id = 'draft-ivan'$q$), 0,
  'Iván no puede editar un borrador mientras está en revisión');
select is(pg_temp.affected($q$delete from public.drafts where id = 'draft-ivan'$q$), 0,
  'Iván no puede borrar un borrador mientras está en revisión');
select throws_ok($$select public.approve_draft('draft-ivan', '{"slug": "caso-nuevo"}')$$,
  '42501', null, 'Iván no puede aprobar');
select throws_ok($$select public.return_draft('draft-ivan')$$,
  '42501', null, 'Iván no puede devolver');
select throws_ok($$select public.unpublish_case('zodiac')$$,
  '42501', null, 'Iván no puede despublicar');

-- ------------------------------------------------------------ otro usuario
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);

select is((select count(*) from public.drafts where id = 'draft-ivan')::int, 0,
  'otro usuario no ve el borrador de Iván');
select throws_ok($$select public.submit_draft('draft-ivan')$$, '42501', null,
  'otro usuario no puede enviar el borrador de Iván');

-- ------------------------------------------------------------------ revisor
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true);

select is((select count(*) from public.drafts where id = 'draft-ivan')::int, 1,
  'el revisor ve los borradores enviados');
select is(pg_temp.affected($q$update public.drafts set status = 'published' where id = 'draft-ivan'$q$), 0,
  'el revisor no cambia estados escribiendo directamente');
select is((select status::text from public.drafts where id = 'draft-ivan'), 'in_review',
  'el estado sigue intacto tras el intento');
select lives_ok($$select public.return_draft('draft-ivan')$$,
  'el revisor devuelve el borrador');
select is((select status::text from public.drafts where id = 'draft-ivan'), 'returned',
  'el borrador queda devuelto');
select throws_ok($$select public.approve_draft('draft-ivan', '{"slug": "caso-nuevo"}')$$,
  '55000', null, 'sólo se aprueba lo que está en revisión');

-- Iván corrige y reenvía.
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select is(pg_temp.affected($q$update public.drafts set payload = '{"title": "Caso nuevo v2"}' where id = 'draft-ivan'$q$), 1,
  'Iván puede corregir un borrador devuelto');
select lives_ok($$select public.submit_draft('draft-ivan')$$,
  'Iván reenvía el borrador corregido');

-- El revisor aprueba.
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true);
select throws_ok($$select public.approve_draft('draft-ivan', '{"slug": "caso-otro", "title": "Pisa"}')$$,
  '55000', null, 'no se puede pisar un caso publicado desde otro borrador');
select throws_ok($$select public.approve_draft('draft-ivan', '{"title": "Sin slug"}')$$,
  '22023', null, 'aprobar exige un slug en el caso');
select lives_ok($$select public.approve_draft('draft-ivan', '{"slug": "caso-nuevo", "title": "Caso nuevo v2"}')$$,
  'el revisor aprueba');
select is((select payload->>'title' from public.cases where slug = 'caso-nuevo'), 'Caso nuevo v2',
  'el caso aprobado queda publicado');
select is((select published_by from public.cases where slug = 'caso-nuevo'),
  '33333333-3333-3333-3333-333333333333'::uuid,
  'la publicación registra quién aprobó');
select is((select status::text || ':' || published_slug from public.drafts where id = 'draft-ivan'),
  'published:caso-nuevo', 'el borrador queda publicado con su slug');

-- Iván edita un caso publicado: vuelve a borrador, la versión publicada sigue.
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
select throws_ok($$update public.drafts set payload = '{"title": "v3"}' where id = 'draft-ivan'$$,
  '42501', null, 'editar un publicado sin volver a borrador no está permitido');
select lives_ok($$update public.drafts set payload = '{"title": "Caso nuevo v3"}', status = 'draft' where id = 'draft-ivan'$$,
  'Iván edita el caso publicado volviendo a borrador');
select is((select payload->>'title' from public.cases where slug = 'caso-nuevo'), 'Caso nuevo v2',
  'la versión publicada no cambia hasta que se apruebe la nueva');
select lives_ok($$select public.submit_draft('draft-ivan')$$, 'Iván reenvía la edición');

reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true);
select throws_ok($$select public.approve_draft('draft-ivan', '{"slug": "otro-slug"}')$$,
  '22023', null, 'una edición se publica con el mismo slug');
select lives_ok($$select public.approve_draft('draft-ivan', '{"slug": "caso-nuevo", "title": "Caso nuevo v3"}')$$,
  'el revisor aprueba la edición');
select is((select payload->>'title' from public.cases where slug = 'caso-nuevo'), 'Caso nuevo v3',
  'la edición aprobada sustituye al caso publicado');
select is((select count(*) from public.cases where slug = 'caso-nuevo')::int, 1,
  'la edición no duplica el caso');

select lives_ok($$select public.unpublish_case('caso-nuevo')$$, 'el revisor despublica');
select is((select count(*) from public.cases where slug = 'caso-nuevo')::int, 0,
  'el caso despublicado desaparece de la web');
select is((select status::text || ':' || coalesce(published_slug, '-') from public.drafts where id = 'draft-ivan'),
  'draft:-', 'el borrador vuelve a borrador sin slug publicado');
select throws_ok($$select public.unpublish_case('no-existe')$$, 'P0002', null,
  'despublicar un caso inexistente avisa');

select * from finish();
rollback;
