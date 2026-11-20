-- ════════════════════════════════════════════════════════════════════════
-- UX-5 (Akun) — fungsi hapus akun (PRD §6.8, §9.4).
--
-- Fungsi `delete_account(p_user)` menghapus semua baris milik user lewat
-- `security definer` (service_role). Deletion eksplisit pada level user
-- supaya RLS tidak menjadi titik kritis; `on delete cascade` dari
-- `children` juga masih ada sebagai safety net.
--
-- GRANT: `service_role` mendapat `execute` (memanggil dari Edge Function).
--
-- Petunjuk pemilik: jalankan SQL ini dalam SQL Editor, lalu deploy Edge
-- Function `delete-account` dengan "Verify JWT" = ON.
--
-- ════════════════════════════════════════════════════════════════════════

create or replace function public.delete_account(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public as $$
begin
  delete from public.chat_messages where user_id = p_user;
  delete from public.user_consents where user_id = p_user;
  delete from public.ai_usage where user_id = p_user;
  delete from public.growth_measurements where user_id = p_user;
  delete from public.food_logs where user_id = p_user;
  delete from public.children where user_id = p_user;

  -- Safety net (biasanya sudah terhapus oleh cascade dari children):
  delete from public.chat_messages where user_id = p_user and child_id is null;
end $$;

-- service_role dari Edge Function mengeksekusi:
revoke all on function public.delete_account(uuid) from public, anon, authenticated;
grant execute on function public.delete_account(uuid) to service_role;
