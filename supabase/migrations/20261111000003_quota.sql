-- ═══════════════════════════════════════════════════════════════
-- Batch 2 — Kuota AI atomik (PRD §5.4)
-- Terapkan SETELAH 20261111000002_rls.sql.
-- ═══════════════════════════════════════════════════════════════

create or replace function public.consume_ai_quota(p_user uuid, p_kind text, p_limit int)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_day date := (now() at time zone 'Asia/Jakarta')::date; v_count int;
begin
  insert into ai_usage(user_id, day) values (p_user, v_day) on conflict do nothing;
  if p_kind = 'scan' then
    update ai_usage set scan_count = scan_count + 1
      where user_id = p_user and day = v_day and scan_count < p_limit returning scan_count into v_count;
  elsif p_kind = 'chat' then
    update ai_usage set chat_count = chat_count + 1
      where user_id = p_user and day = v_day and chat_count < p_limit returning chat_count into v_count;
  else raise exception 'invalid kind';
  end if;
  return v_count is not null;
end $$;

revoke all on function public.consume_ai_quota(uuid, text, int) from public, anon, authenticated;
grant execute on function public.consume_ai_quota(uuid, text, int) to service_role;
