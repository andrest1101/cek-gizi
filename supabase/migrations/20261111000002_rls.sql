-- ═══════════════════════════════════════════════════════════════
-- Batch 2 — Row Level Security (PRD §5.3)
-- Semua tabel pakai RLS; pengguna anonim = role `authenticated`.
-- Untuk tabel yang punya child_id, WITH CHECK juga memastikan anak
-- milik pengguna yang sama. Terapkan SETELAH 20261111000001_schema.sql.
-- ═══════════════════════════════════════════════════════════════

-- children: baris hanya miliknya
alter table public.children enable row level security;
create policy "own rows" on public.children for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- growth_measurements: baris miliknya DAN anaknya miliknya
alter table public.growth_measurements enable row level security;
create policy "own rows" on public.growth_measurements for all to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.children c
      where c.id = child_id
        and c.user_id = (select auth.uid())
    )
  );

-- food_logs: baris miliknya DAN anaknya miliknya
alter table public.food_logs enable row level security;
create policy "own rows" on public.food_logs for all to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.children c
      where c.id = child_id
        and c.user_id = (select auth.uid())
    )
  );

-- chat_messages: baris miliknya; child_id boleh NULL (chat tanpa konteks anak)
alter table public.chat_messages enable row level security;
create policy "own rows" on public.chat_messages for all to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and (
      child_id is null
      or exists (
        select 1 from public.children c
        where c.id = child_id
          and c.user_id = (select auth.uid())
      )
    )
  );

-- user_consents: baris hanya miliknya
alter table public.user_consents enable row level security;
create policy "own rows" on public.user_consents for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- ai_usage: user BOLEH MEMBACA jatah miliknya; tulis hanya lewat service_role
alter table public.ai_usage enable row level security;
create policy "read own usage" on public.ai_usage for select to authenticated
  using ((select auth.uid()) = user_id);
