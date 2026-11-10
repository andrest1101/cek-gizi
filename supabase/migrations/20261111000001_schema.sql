-- ═══════════════════════════════════════════════════════════════
-- Batch 2 — Skema awal (PRD §5.2)
-- Dibuat dari PRD.md persis; JANGAN ubah lewat dashboard — semua
-- perubahan skema berjalan lewat file migrasi.
-- Terapkan di Supabase SQL Editor SEBELUM RLS & quota (no. 2 & 3).
-- ═══════════════════════════════════════════════════════════════

create table public.children (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nickname text not null check (char_length(nickname) between 1 and 30),
  birth_date date not null,
  sex text not null check (sex in ('male','female')),
  avatar_key text not null default 'sprout',
  created_at timestamptz not null default now()
);

create table public.growth_measurements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  measured_on date not null,
  weight_kg numeric(4,1) not null check (weight_kg between 1 and 30),
  length_height_cm numeric(4,1) not null check (length_height_cm between 35 and 130),
  measure_mode text not null check (measure_mode in ('lying','standing')),
  age_months int not null check (age_months between 0 and 60),
  haz numeric(5,2), waz numeric(5,2), whz numeric(5,2),
  status_haz text, status_waz text, status_whz text,
  ref_version text not null,
  note text check (char_length(note) <= 200),
  created_at timestamptz not null default now(),
  unique (child_id, measured_on)
);

create table public.food_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  eaten_at timestamptz not null,
  meal_type text not null check (meal_type in ('breakfast','lunch','dinner','snack')),
  source text not null check (source in ('scan','manual','recipe')),
  items jsonb not null default '[]',   -- [{name, groups[], portion}]
  groups text[] not null default '{}'
    check (groups <@ array['breast_milk','grains_tubers','legumes_nuts','dairy',
                           'flesh','eggs','vit_a_fruit_veg','other_fruit_veg']),
  created_at timestamptz not null default now()
);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  child_id uuid references public.children(id) on delete set null,
  role text not null check (role in ('user','assistant')),
  content text not null check (char_length(content) <= 4000),
  safety_flag text not null default 'none' check (safety_flag in ('none','refer_doctor','emergency')),
  created_at timestamptz not null default now()
);

create table public.user_consents (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  version text not null,
  accepted_at timestamptz not null default now(),
  primary key (user_id, version)
);

create table public.ai_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  scan_count int not null default 0,
  chat_count int not null default 0,
  primary key (user_id, day)
);

create index on public.growth_measurements (child_id, measured_on);
create index on public.food_logs (child_id, eaten_at);

-- Catatan PRD §5.2: validasi "tanggal tidak di masa depan" dilakukan di
-- aplikasi, bukan CHECK constraint (fungsi waktu tidak cocok untuk constraint).
