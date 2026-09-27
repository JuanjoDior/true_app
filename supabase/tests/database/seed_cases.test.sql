-- Carga única del catálogo (CRP-02): los 16 casos de cases.json, en su orden,
-- visibles para un visitante anónimo y sin borrador de origen.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

select is((select count(*) from public.cases)::int, 16,
  'la migración carga los 16 casos del catálogo');

select is(
  (select array_agg(slug order by sort_order) from public.cases),
  array['zodiac', 'blackdahlia', 'jonbenet', 'tylenol', 'lizzie', 'btk',
        'goldenstate', 'mccann', 'ripper', 'isdal', 'hinterkaifeck', 'kercher',
        'dyatlov', 'somerton', 'caso-asunta', 'camarena'],
  'sort_order conserva el orden de cases.json');

select is((select count(*) from public.cases where source_draft_id is not null)::int, 0,
  'ningún caso cargado viene de un borrador');

select is(
  (select count(*) from public.cases
   where payload ? 'title' and jsonb_typeof(payload -> 'sources') = 'array')::int,
  16,
  'el payload se guarda completo, con sus campos anidados');

set local role anon;
select set_config('request.jwt.claims', '{"role": "anon"}', true);

select is((select count(*) from public.cases)::int, 16,
  'un visitante anónimo ve los 16 casos');

select * from finish();
rollback;
