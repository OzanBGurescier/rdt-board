-- =====================================================================
--  RDT Task Board — Supabase schema
--  Paste this whole file into Supabase → SQL Editor → New query → Run.
--  Safe to re-run: it drops and recreates the policies, and the tables
--  are created only if they don't exist yet.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------

-- Who may edit. Add one row per teammate (email must match their login).
create table if not exists public.editors (
  email      text primary key,
  name       text not null,               -- shown in the Owner dropdown
  added_at   timestamptz not null default now()
);

-- Board columns (Backlog, To Do, ...). "position" orders them left→right.
create table if not exists public.board_columns (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 60),
  position   double precision not null default 0,
  created_at timestamptz not null default now()
);

-- Task cards. "position" orders cards top→bottom inside a column.
create table if not exists public.tasks (
  id          uuid primary key default gen_random_uuid(),
  column_id   uuid not null references public.board_columns(id) on delete restrict,
  title       text not null check (char_length(title) between 1 and 200),
  description text not null default '',
  owner       text not null default '',
  due_date    date,
  labels      text[] not null default '{}',
  priority    text not null default 'medium'
              check (priority in ('low','medium','high','urgent')),
  position    double precision not null default 0,
  created_by  text default (auth.jwt() ->> 'email'),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists tasks_column_idx on public.tasks (column_id, position);

-- Keep updated_at current on every edit.
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists tasks_touch on public.tasks;
create trigger tasks_touch before update on public.tasks
for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------
-- 2. "Is the signed-in user an editor?"
--    security definer lets it read the editors table without exposing it.
-- ---------------------------------------------------------------------
create or replace function public.is_editor()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.editors
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

grant execute on function public.is_editor() to anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. Row Level Security
--    Everyone (even logged out) can READ columns and tasks.
--    Only signed-in users listed in public.editors can WRITE.
-- ---------------------------------------------------------------------
alter table public.editors       enable row level security;
alter table public.board_columns enable row level security;
alter table public.tasks         enable row level security;

-- Columns
drop policy if exists "columns: public read"  on public.board_columns;
drop policy if exists "columns: editors write" on public.board_columns;
create policy "columns: public read" on public.board_columns
  for select to anon, authenticated using (true);
create policy "columns: editors write" on public.board_columns
  for all to authenticated using (public.is_editor()) with check (public.is_editor());

-- Tasks
drop policy if exists "tasks: public read"  on public.tasks;
drop policy if exists "tasks: editors write" on public.tasks;
create policy "tasks: public read" on public.tasks
  for select to anon, authenticated using (true);
create policy "tasks: editors write" on public.tasks
  for all to authenticated using (public.is_editor()) with check (public.is_editor());

-- Editors list: only editors can see it (it contains emails).
-- Add/remove editors from the Supabase Table Editor, not from the site.
drop policy if exists "editors: editors read" on public.editors;
create policy "editors: editors read" on public.editors
  for select to authenticated using (public.is_editor());

-- ---------------------------------------------------------------------
-- 4. Live updates (cards move on everyone's screen without refreshing)
-- ---------------------------------------------------------------------
do $$
begin
  begin
    alter publication supabase_realtime add table public.board_columns;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.tasks;
  exception when duplicate_object then null;
  end;
end $$;

-- ---------------------------------------------------------------------
-- 5. Starter columns (only inserted if the board is empty)
-- ---------------------------------------------------------------------
insert into public.board_columns (name, position)
select * from (values
  ('Backlog', 1000), ('To Do', 2000), ('In Progress', 3000),
  ('Review', 4000), ('Done', 5000)
) as v(name, position)
where not exists (select 1 from public.board_columns);

-- ---------------------------------------------------------------------
-- 6. Editors — EDIT THESE, then run this file (or add rows later in
--    Table Editor → editors). Emails must match the accounts you create
--    under Authentication → Users.
-- ---------------------------------------------------------------------
insert into public.editors (email, name) values
  ('ozangurescier@nyu.edu', 'Ozan')
  -- , ('teammate1@nyu.edu', 'Teammate One')
  -- , ('teammate2@nyu.edu', 'Teammate Two')
on conflict (email) do update set name = excluded.name;
