-- Shift HR schema (applied via Supabase SQL editor, project ref gcxdapfieuqtyushftdz)
-- Safe to re-run.

create extension if not exists pgcrypto;

create table if not exists public.pages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  default_start time,
  default_end time,
  default_break_minutes int not null default 0,
  active boolean not null default true
);

create table if not exists public.staff (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null default 'freelance' check (type in ('regular','freelance')),
  can_edit boolean not null default false,
  edit_pin text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.staff_pages (
  staff_id uuid not null references public.staff(id) on delete cascade,
  page_id uuid not null references public.pages(id) on delete cascade,
  primary key (staff_id, page_id)
);

create table if not exists public.shifts (
  id uuid primary key default gen_random_uuid(),
  work_date date not null,
  page_id uuid references public.pages(id) on delete set null,
  staff_id uuid not null references public.staff(id) on delete cascade,
  start_time time,
  end_time time,
  break_minutes int not null default 0,
  status text not null default 'normal' check (status in ('normal','swapped','sick','off')),
  note text,
  ot_hours numeric not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  id int primary key default 1,
  hr_pin text not null default '0000'
);
insert into public.app_settings (id, hr_pin) values (1, '0000') on conflict (id) do nothing;

alter table public.pages enable row level security;
alter table public.staff enable row level security;
alter table public.staff_pages enable row level security;
alter table public.shifts enable row level security;
alter table public.app_settings enable row level security;

drop policy if exists "public all pages" on public.pages;
drop policy if exists "public all staff" on public.staff;
drop policy if exists "public all staff_pages" on public.staff_pages;
drop policy if exists "public all shifts" on public.shifts;
drop policy if exists "public read settings" on public.app_settings;
drop policy if exists "public update settings" on public.app_settings;

create policy "public all pages" on public.pages for all using (true) with check (true);
create policy "public all staff" on public.staff for all using (true) with check (true);
create policy "public all staff_pages" on public.staff_pages for all using (true) with check (true);
create policy "public all shifts" on public.shifts for all using (true) with check (true);
create policy "public read settings" on public.app_settings for select using (true);
create policy "public update settings" on public.app_settings for update using (true);

alter publication supabase_realtime add table public.shifts;
alter publication supabase_realtime add table public.staff;
alter publication supabase_realtime add table public.pages;
