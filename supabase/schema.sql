create extension if not exists pgcrypto;

create table public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 80),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'member')),
  joined_at timestamptz not null default now(),
  primary key (family_id, user_id),
  unique (user_id)
);

create table public.family_invites (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  code text not null unique default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
  created_by uuid not null references auth.users(id) on delete restrict,
  expires_at timestamptz not null default now() + interval '7 days',
  accepted_by uuid references auth.users(id) on delete set null,
  accepted_at timestamptz
);

create or replace function public.is_family_member(p_family_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.family_members where family_id = p_family_id and user_id = auth.uid());
$$;

create or replace function public.is_family_admin(p_family_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.family_members where family_id = p_family_id and user_id = auth.uid() and role = 'admin');
$$;

create or replace function public.add_family_owner()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.family_members (family_id, user_id, role) values (new.id, new.created_by, 'admin');
  return new;
end;
$$;

create trigger families_add_owner after insert on public.families for each row execute function public.add_family_owner();

create or replace function public.create_family_invite(p_family_id uuid)
returns table(code text, expires_at timestamptz) language plpgsql security definer set search_path = public as $$
begin
  if not public.is_family_admin(p_family_id) then raise exception 'Somente administradores podem criar convites.'; end if;
  return query insert into public.family_invites (family_id, created_by) values (p_family_id, auth.uid()) returning family_invites.code, family_invites.expires_at;
end;
$$;

create or replace function public.accept_family_invite(p_code text)
returns uuid language plpgsql security definer set search_path = public as $$
declare invite public.family_invites;
begin
  if auth.uid() is null then raise exception 'Faça login para aceitar um convite.'; end if;
  if exists (select 1 from public.family_members where user_id = auth.uid()) then raise exception 'Você já participa de uma família.'; end if;
  select * into invite from public.family_invites where code = upper(trim(p_code)) and accepted_at is null and expires_at > now() for update;
  if invite.id is null then raise exception 'Código inválido ou expirado.'; end if;
  insert into public.family_members (family_id, user_id) values (invite.family_id, auth.uid());
  update public.family_invites set accepted_by = auth.uid(), accepted_at = now() where id = invite.id;
  return invite.family_id;
end;
$$;

alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.family_invites enable row level security;

create policy "members read their family" on public.families for select to authenticated using (public.is_family_member(id));
create policy "users create a family" on public.families for insert to authenticated with check (created_by = auth.uid());
create policy "admins update their family" on public.families for update to authenticated using (public.is_family_admin(id)) with check (public.is_family_admin(id));
create policy "members read family members" on public.family_members for select to authenticated using (public.is_family_member(family_id));

grant usage on schema public to authenticated;
grant select, insert, update on public.families to authenticated;
grant select on public.family_members to authenticated;
grant execute on function public.create_family_invite(uuid) to authenticated;
grant execute on function public.accept_family_invite(text) to authenticated;
