-- ═══════════════════════════════════════════════════════════════
-- Batch 2 (lanjutan) — GRANT akses tabel untuk role authenticated
-- & service_role.
--
-- Kenapa perlu: di Supabase versi baru, tabel yang dibuat lewat SQL
-- tidak otomatis dapat hak akses untuk role authenticated. Tanpa
-- GRANT, RLS bahkan tidak pernah dievaluasi → error 42501
-- "permission denied for table ..." (terlihat saat uji RLS).
-- RLS tetap menjadi penyaring baris; GRANT hanya membuka gerbang tabel.
--
-- ATURAN: semua migrasi berikutnya WAJIB menyertakan GRANT sendiri.
-- Terapkan di SQL Editor SETELAH 20261111000003_quota.sql.
-- ═══════════════════════════════════════════════════════════════

-- authenticated (termasuk pengguna anonim): CRUD untuk data miliknya,
-- RLS membatasi barisnya hanya ke data sendiri.
grant select, insert, update, delete on public.children to authenticated;
grant select, insert, update, delete on public.growth_measurements to authenticated;
grant select, insert, update, delete on public.food_logs to authenticated;
grant select, insert, update, delete on public.chat_messages to authenticated;
grant select, insert, update, delete on public.user_consents to authenticated;

-- ai_usage: user hanya boleh MEMBACA jatah miliknya (tulis = service_role).
grant select on public.ai_usage to authenticated;

-- service_role (Edge Functions; TUJUAN: operasi server-side, bypass RLS).
grant all on public.children to service_role;
grant all on public.growth_measurements to service_role;
grant all on public.food_logs to service_role;
grant all on public.chat_messages to service_role;
grant all on public.user_consents to service_role;
grant all on public.ai_usage to service_role;
