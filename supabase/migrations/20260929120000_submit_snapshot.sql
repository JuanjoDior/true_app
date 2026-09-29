-- Envío atómico de un snapshot a revisión (CRP-04b).
--
-- Los borradores se editan en local; sólo «Enviar a revisión» manda una copia
-- exacta a Supabase. El cliente ya no escribe `drafts`: crear o reemplazar la
-- fila remota pasa por `submit_draft_snapshot`.

alter table public.drafts add column submission_id uuid;
comment on column public.drafts.submission_id is
  'Identificador de la última entrega aceptada; permite reintentar un envío sin duplicarlo.';

drop function public.submit_draft(text);

-- Iván ya no escribe borradores directamente: sólo lee los suyos.
drop policy "cada autor crea sus borradores" on public.drafts;
drop policy "cada autor edita sus borradores fuera de revisión" on public.drafts;
drop policy "cada autor borra sus borradores fuera de revisión" on public.drafts;
revoke insert, update, delete on public.drafts from authenticated;

-- La validación del payload aquí es mínima (forma, tamaño, identidad y
-- título): la validación completa del expediente sigue en el cliente.
create function public.submit_draft_snapshot(
  p_draft_id text,
  p_submission_id uuid,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_inserted int;
  v_draft public.drafts%rowtype;
begin
  if v_uid is null then
    raise exception 'a session is required to submit a draft' using errcode = '42501';
  end if;

  if p_draft_id is null or char_length(p_draft_id) not between 1 and 100 then
    raise exception 'invalid draft id' using errcode = '22023';
  end if;
  if p_submission_id is null then
    raise exception 'a submission id is required' using errcode = '22023';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'payload must be a JSON object' using errcode = '22023';
  end if;
  if octet_length(p_payload::text) > 500000 then
    raise exception 'payload is larger than 500000 bytes' using errcode = '22023';
  end if;
  if p_payload ->> 'draftId' is distinct from p_draft_id then
    raise exception 'payload draftId does not match the draft id' using errcode = '22023';
  end if;
  if jsonb_typeof(p_payload -> 'title') is distinct from 'string'
     or btrim(p_payload ->> 'title') = '' then
    raise exception 'payload needs a non-empty title' using errcode = '22023';
  end if;

  -- Crear sin carreras: dos envíos simultáneos del mismo id no se pisan; el
  -- perdedor cae al `select ... for update`, que espera al ganador.
  insert into public.drafts (id, owner, payload, status, submission_id, submitted_at)
  values (p_draft_id, v_uid, p_payload, 'in_review', p_submission_id, now())
  on conflict (id) do nothing;
  get diagnostics v_inserted = row_count;

  select * into v_draft from public.drafts where id = p_draft_id for update;

  -- Mismo mensaje para "no existe" y "es de otro": no revela existencia.
  if not found or v_draft.owner <> v_uid then
    raise exception 'draft % not found for this user', p_draft_id using errcode = '42501';
  end if;

  if v_inserted = 0 then
    if v_draft.submission_id = p_submission_id then
      -- Reintento de una entrega ya aceptada: estado actual, sin modificar.
      if v_draft.payload <> p_payload then
        raise exception 'submission % was already accepted with a different payload',
          p_submission_id using errcode = '22023';
      end if;
    elsif v_draft.status = 'in_review' then
      raise exception 'draft % is already in review', p_draft_id using errcode = '55000';
    else
      update public.drafts
      set payload = p_payload,
          status = 'in_review',
          submission_id = p_submission_id,
          submitted_at = now()
      where id = p_draft_id
      returning * into v_draft;
    end if;
  end if;

  return jsonb_build_object('status', v_draft.status, 'submitted_at', v_draft.submitted_at);
end;
$$;

revoke execute on function public.submit_draft_snapshot(text, uuid, jsonb) from public, anon;
grant execute on function public.submit_draft_snapshot(text, uuid, jsonb) to authenticated;
