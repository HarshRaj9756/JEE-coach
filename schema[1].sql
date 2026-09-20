create extension if not exists pgcrypto;
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text, email text, target_exam text default 'JEE Main + Advanced', target_date date,
  class_level text, daily_minutes integer default 360, preferred_start_time time default '07:00',
  study_days integer[] default '{1,2,3,4,5,6}',
  subject_priorities jsonb default '[{"subject":"Physics","priority":3},{"subject":"Chemistry","priority":3},{"subject":"Mathematics","priority":3}]'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.daily_logs (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  log_date date not null, goals text default '', lectures_completed integer not null default 0, lecture_minutes integer not null default 0,
  practice_questions integer not null default 0, correct_questions integer not null default 0, revision_minutes integer not null default 0,
  revision_notes text default '', wellbeing integer check (wellbeing between 1 and 5), energy integer check (energy between 1 and 5),
  stress integer check (stress between 1 and 5), blockers text default '', created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(), unique(user_id,log_date)
);
create table if not exists public.schedule_blocks (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  block_date date not null, start_time time not null, end_time time not null, subject text not null, topic text default '', kind text not null default 'Practice',
  status text not null default 'planned' check (status in ('planned','done','skipped')), source text not null default 'planner' check (source in ('planner','manual')),
  notes text default '', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.coach_threads (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'New coaching chat', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.coach_messages (
  id uuid primary key default gen_random_uuid(), thread_id uuid not null references public.coach_threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade, role text not null check (role in ('user','assistant','system')),
  content text not null, created_at timestamptz not null default now()
);
create table if not exists public.coach_attachments (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  thread_id uuid not null references public.coach_threads(id) on delete cascade, message_id uuid references public.coach_messages(id) on delete set null,
  storage_path text not null, file_name text not null, mime_type text not null, size_bytes bigint not null default 0, created_at timestamptz not null default now()
);
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists profiles_updated_at on public.profiles; create trigger profiles_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();
drop trigger if exists daily_logs_updated_at on public.daily_logs; create trigger daily_logs_updated_at before update on public.daily_logs for each row execute procedure public.set_updated_at();
drop trigger if exists schedule_blocks_updated_at on public.schedule_blocks; create trigger schedule_blocks_updated_at before update on public.schedule_blocks for each row execute procedure public.set_updated_at();
drop trigger if exists coach_threads_updated_at on public.coach_threads; create trigger coach_threads_updated_at before update on public.coach_threads for each row execute procedure public.set_updated_at();
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,full_name,email) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'name'),new.email) on conflict(id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users; create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
alter table public.profiles enable row level security; alter table public.daily_logs enable row level security; alter table public.schedule_blocks enable row level security; alter table public.coach_threads enable row level security; alter table public.coach_messages enable row level security; alter table public.coach_attachments enable row level security;
drop policy if exists profiles_select_own on public.profiles; create policy profiles_select_own on public.profiles for select using(auth.uid()=id);
drop policy if exists profiles_insert_own on public.profiles; create policy profiles_insert_own on public.profiles for insert with check(auth.uid()=id);
drop policy if exists profiles_update_own on public.profiles; create policy profiles_update_own on public.profiles for update using(auth.uid()=id) with check(auth.uid()=id);
drop policy if exists daily_logs_own on public.daily_logs; create policy daily_logs_own on public.daily_logs for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists schedule_blocks_own on public.schedule_blocks; create policy schedule_blocks_own on public.schedule_blocks for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists coach_threads_own on public.coach_threads; create policy coach_threads_own on public.coach_threads for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists coach_messages_own on public.coach_messages; create policy coach_messages_own on public.coach_messages for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists coach_attachments_own on public.coach_attachments; create policy coach_attachments_own on public.coach_attachments for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
insert into storage.buckets(id,name,public) values('coach-files','coach-files',false) on conflict(id) do nothing;
drop policy if exists coach_files_select on storage.objects; create policy coach_files_select on storage.objects for select to authenticated using(bucket_id='coach-files' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists coach_files_insert on storage.objects; create policy coach_files_insert on storage.objects for insert to authenticated with check(bucket_id='coach-files' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists coach_files_update on storage.objects; create policy coach_files_update on storage.objects for update to authenticated using(bucket_id='coach-files' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists coach_files_delete on storage.objects; create policy coach_files_delete on storage.objects for delete to authenticated using(bucket_id='coach-files' and (storage.foldername(name))[1]=auth.uid()::text);
create index if not exists daily_logs_user_date_idx on public.daily_logs(user_id,log_date desc); create index if not exists schedule_blocks_user_date_idx on public.schedule_blocks(user_id,block_date,start_time); create index if not exists coach_messages_thread_created_idx on public.coach_messages(thread_id,created_at); create index if not exists coach_attachments_thread_created_idx on public.coach_attachments(thread_id,created_at);
