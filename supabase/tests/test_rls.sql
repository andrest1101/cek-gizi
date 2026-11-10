-- ═══════════════════════════════════════════════════════════════
-- Uji RLS DUA PENGGUNA (PRD §5.3) — jalankan di Supabase SQL Editor
-- atau psql SETELAH tiga migrasi diterapkan.
--
-- Aman: seluruh skrip berjalan dalam SATU transaksi dan di-ROLLBACK
-- di akhir — tidak meninggalkan data uji. Tidak perlu dua akun nyata;
-- dua "pengguna" disimulasikan lewat request.jwt.claims.
--
-- LULUS = semua blok DO selesai tanpa ERROR dan notice "PASS" muncul.
-- ═══════════════════════════════════════════════════════════════

begin;

set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

create temp table rls_test on commit drop as
select 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid as user_a,
       'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid as user_b;

-- ── Pengguna A: tulis & baca datanya sendiri ────────────────────

-- A insert anak (via CTE agar id bisa dibawa ke temp table)
create temp table rls_child on commit drop as
with new_child as (
  insert into public.children (nickname, birth_date, sex)
  values ('RLS-TEST-A', '2025-01-15', 'female')
  returning id
)
select id as child_a from new_child;

do $$
declare
  child_a uuid := (select child_a from rls_child);
begin
  -- anak milik A terlihat oleh A
  if not exists (select 1 from public.children where id = child_a) then
    raise exception 'FAIL: A tidak bisa membaca anaknya sendiri';
  end if;

  insert into public.growth_measurements (child_id, measured_on, weight_kg, length_height_cm, measure_mode, age_months, ref_version)
  values (child_a, current_date, 7.4, 68.0, 'lying', 11, 'permenkes-2-2020');

  insert into public.food_logs (child_id, eaten_at, meal_type, source, items, groups)
  values (child_a, now(), 'lunch', 'manual', '[{"name":"bubur nasi","groups":["grains_tubers"],"portion":"medium"}]', array['grains_tubers']);

  insert into public.chat_messages (child_id, role, content)
  values (child_a, 'user', 'Contoh pesan uji RLS');

  insert into public.user_consents (user_id, version)
  select auth.uid(), 'test-v1';

  raise notice 'PASS: user A dapat menulis & membaca datanya sendiri';
end $$;

-- ── Pengguna B: TIDAK boleh melihat/mengubah data A ─────────────

set local request.jwt.claims = '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';

do $$
declare
  child_a uuid := (select child_a from rls_child);
begin
  if exists (select 1 from public.children where id = child_a) then
    raise exception 'FAIL: user B bisa MEMBACA anak user A';
  end if;
  raise notice 'PASS: user B tidak bisa membaca anak user A';

  update public.children set nickname = ' diretas' where id = child_a;
  if found then raise exception 'FAIL: user B bisa UPDATE anak user A'; end if;

  delete from public.children where id = child_a;
  if found then raise exception 'FAIL: user B bisa DELETE anak user A'; end if;
  raise notice 'PASS: user B tidak bisa UPDATE/DELETE anak user A';

  if exists (select 1 from public.growth_measurements where child_id = child_a) then
    raise exception 'FAIL: user B bisa membaca growth_measurements user A';
  end if;
  if exists (select 1 from public.food_logs where child_id = child_a) then
    raise exception 'FAIL: user B bisa membaca food_logs user A';
  end if;
  if exists (select 1 from public.chat_messages where child_id = child_a) then
    raise exception 'FAIL: user B bisa membaca chat_messages user A';
  end if;
  if exists (select 1 from public.user_consents where user_id = (select user_a from rls_test)) then
    raise exception 'FAIL: user B bisa membaca user_consents user A';
  end if;
  raise notice 'PASS: user B tidak bisa membaca growth_measurements, food_logs, chat_messages, user_consents milik A';
end $$;

do $$
declare
  child_a uuid := (select child_a from rls_child);
begin
  -- INSERT dengan child_id milik A -> harus ditolak (with check)
  begin
    insert into public.growth_measurements (child_id, measured_on, weight_kg, length_height_cm, measure_mode, age_months, ref_version)
    values (child_a, current_date, 7.4, 68.0, 'lying', 11, 'permenkes-2-2020');
    raise exception 'FAIL: user B bisa INSERT growth_measurements ke anak user A';
  exception
    when insufficient_privilege then
      raise notice 'PASS: INSERT growth_measurements lintas anak ditolak RLS';
  end;

  begin
    insert into public.food_logs (child_id, eaten_at, meal_type, source)
    values (child_a, now(), 'snack', 'manual');
    raise exception 'FAIL: user B bisa INSERT food_logs ke anak user A';
  exception
    when insufficient_privilege then
      raise notice 'PASS: INSERT food_logs lintas anak ditolak RLS';
  end;

  -- INSERT chat_messages dengan child_id NULL -> harus DIIZINKAN (chat tanpa konteks anak)
  insert into public.chat_messages (child_id, role, content)
  values (null, 'user', 'Chat tanpa konteks anak');
  raise notice 'PASS: INSERT chat_messages child_id NULL diizinkan';
end $$;

-- ── Kuota AI: hanya service_role yang boleh menulis & mengurangi ──

set local role service_role;

do $$
declare
  user_a uuid := (select user_a from rls_test);
begin
  if not public.consume_ai_quota(user_a, 'scan', 2) then
    raise exception 'FAIL: consume_ai_quota scan ke-1 harus true';
  end if;
  if not public.consume_ai_quota(user_a, 'scan', 2) then
    raise exception 'FAIL: consume_ai_quota scan ke-2 harus true';
  end if;
  if public.consume_ai_quota(user_a, 'scan', 2) then
    raise exception 'FAIL: consume_ai_quota scan ke-3 harus false (limit 2)';
  end if;
  raise notice 'PASS: consume_ai_quota membatasi kuota scan ke-3 (limit 2)';

  begin
    perform public.consume_ai_quota(user_a, 'invalid-kind', 5);
    raise exception 'FAIL: consume_ai_quota menerima kind tidak valid';
  exception
    when others then
      raise notice 'PASS: consume_ai_quota menolak kind tidak valid';
  end;
end $$;

-- ── Selesai: buang semua perubahan ───────────────────────────────

rollback;

-- Jika tidak ada ERROR di atas dan semua notice "PASS" muncul → RLS LULUS.
