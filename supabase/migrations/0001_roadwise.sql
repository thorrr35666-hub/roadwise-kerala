-- RoadWise Kerala initial schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now()
);
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, display_name) values (new.id, coalesce(new.raw_user_meta_data->>'display_name',''))
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created_roadwise on auth.users;
create trigger on_auth_user_created_roadwise after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists public.signs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null check(category in ('Regulatory','Warning','Informatory')),
  shape text not null default 'Unknown',
  colour text not null default 'See official standard',
  meaning text not null,
  typical_location text not null default '',
  standard_reference text not null default 'Verify against current official IRC publication',
  is_published boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.markings (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'Carriageway',
  appearance text not null default '',
  meaning text not null,
  typical_location text not null default '',
  common_defects text not null default '',
  standard_reference text not null default 'Verify against current official IRC publication',
  is_published boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.road_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  defect_type text not null,
  severity text not null default 'Needs review',
  location_text text not null,
  description text,
  latitude double precision,
  longitude double precision,
  photo_path text,
  status text not null default 'submitted' check(status in ('submitted','under_review','resolved','rejected')),
  admin_notes text,
  created_at timestamptz not null default now(),
  constraint latitude_range check(latitude is null or latitude between -90 and 90),
  constraint longitude_range check(longitude is null or longitude between -180 and 180)
);

alter table public.profiles enable row level security;
alter table public.signs enable row level security;
alter table public.markings enable row level security;
alter table public.road_reports enable row level security;

-- Role helper. Keep role changes restricted to trusted project owners.
create or replace function public.is_roadwise_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;
revoke all on function public.is_roadwise_admin() from public;
grant execute on function public.is_roadwise_admin() to authenticated;

create policy "profiles read own or admin" on public.profiles for select to authenticated
using (id = auth.uid() or public.is_roadwise_admin());
create policy "profiles update own basic profile" on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid() and role = 'user');

create policy "published signs readable" on public.signs for select to anon, authenticated
using (is_published = true or public.is_roadwise_admin());
create policy "admins insert signs" on public.signs for insert to authenticated
with check (public.is_roadwise_admin());
create policy "admins update signs" on public.signs for update to authenticated
using (public.is_roadwise_admin()) with check (public.is_roadwise_admin());
create policy "admins delete signs" on public.signs for delete to authenticated
using (public.is_roadwise_admin());

create policy "published markings readable" on public.markings for select to anon, authenticated
using (is_published = true or public.is_roadwise_admin());
create policy "admins insert markings" on public.markings for insert to authenticated
with check (public.is_roadwise_admin());
create policy "admins update markings" on public.markings for update to authenticated
using (public.is_roadwise_admin()) with check (public.is_roadwise_admin());
create policy "admins delete markings" on public.markings for delete to authenticated
using (public.is_roadwise_admin());

create policy "reporter reads own reports or admin reads all" on public.road_reports for select to authenticated
using (reporter_id = auth.uid() or public.is_roadwise_admin());
create policy "authenticated user submits own report" on public.road_reports for insert to authenticated
with check (reporter_id = auth.uid() and status = 'submitted');
create policy "admin updates reports" on public.road_reports for update to authenticated
using (public.is_roadwise_admin()) with check (public.is_roadwise_admin());
create policy "admin deletes reports" on public.road_reports for delete to authenticated
using (public.is_roadwise_admin());

grant select on public.signs, public.markings to anon, authenticated;
grant insert, update, delete on public.signs, public.markings to authenticated;
grant select, insert, update, delete on public.road_reports to authenticated;
grant select, update on public.profiles to authenticated;

-- Private image bucket. Paths must be prefixed with the authenticated user's UUID.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('road-report-photos','road-report-photos',false,10485760,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy "users upload report photos in own folder" on storage.objects for insert to authenticated
with check (bucket_id = 'road-report-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users read their own report photos or admins" on storage.objects for select to authenticated
using (bucket_id = 'road-report-photos' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_roadwise_admin()));
create policy "admins delete report photos" on storage.objects for delete to authenticated
using (bucket_id = 'road-report-photos' and public.is_roadwise_admin());

-- Seed data. This is educational starter content; verify against current official publications.
insert into public.signs(name,category,shape,colour,meaning,typical_location,standard_reference) values
('STOP','Regulatory','Octagon','Red / white','Come to a complete stop at the stop line and proceed only when safe.','Junctions and approaches where stopping is required.','Verify current IRC:67 requirements and site-specific placement.'),
('Give Way','Regulatory','Inverted triangle','Red / white','Slow down and yield to traffic on the priority road.','Approaches where traffic must yield.','Verify current IRC:67 requirements and site-specific placement.'),
('Speed Limit','Regulatory','Circle','Red / white','Do not exceed the speed shown on the authorised sign.','Locations designated by the competent road authority.','Use the authorised speed value; verify current IRC:67.'),
('No Entry','Regulatory','Circle','Red / white','Vehicles must not enter from this direction.','One-way entries and restricted approaches.','Verify current IRC:67 and applicable traffic orders.'),
('Right Curve','Warning','Triangle','Red / white / black','A curve to the right lies ahead; adjust speed and position.','Curve approaches with adequate advance warning.','Verify current IRC:67 and site geometry.'),
('School Ahead','Warning','Triangle','Red / white / black','Children may cross or move near the carriageway.','School approaches and designated school zones.','Verify current IRC:67 and crossing conditions.'),
('Pedestrian Crossing','Warning','Triangle','Red / white / black','Watch for pedestrians crossing the road.','Approaches to designated pedestrian crossings.','Coordinate signs and markings per current standards.'),
('Hospital','Informatory','Rectangle','Blue / white','Indicates a hospital or medical facility.','Routes where a facility can be accessed.','Verify current IRC:67 sign layout and destination information.')
on conflict do nothing;

insert into public.markings(name,category,appearance,meaning,typical_location,common_defects,standard_reference) values
('Broken centre line','Carriageway','Broken white line','Separates traffic streams according to road layout. Crossing rules depend on context and applicable rules.','Road sections where lane separation and permitted crossing are appropriate.','Faded segments; inconsistent gaps; poor wet/night visibility.','Verify current IRC:35 edition and amendments.'),
('Continuous centre line','Carriageway','Continuous line','Indicates a restriction on crossing or lane movement according to applicable layout and rules.','Locations requiring separation and restricted crossing.','Worn line; interruptions where continuity is required.','Verify current IRC:35 and approved road design.'),
('Stop line','Junction / crossing','Broad transverse line','Indicates where a vehicle must stop at a controlled approach.','Signalised junctions and stop-controlled approaches.','Faded line; poor placement; resurfacing obscures marking.','Verify current IRC:35 and coordinate with signals/signs.'),
('Pedestrian crossing','Crossing','Parallel white bars','Marks a pedestrian crossing area.','Designated crossings near junctions, schools and pedestrian desire lines.','Faded bars; low visibility; vehicles obstructing sight lines.','Verify current IRC:35 and ensure safe crossing design.')
on conflict do nothing;
