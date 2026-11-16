-- Migration 006: Self-service account deletion for authenticated users
create or replace function public.delete_own_account()
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  delete from auth.users where id = (select auth.uid());
end;
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
