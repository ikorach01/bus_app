-- Function to check if an email exists in auth.users
create or replace function public.check_email_exists(check_email text)
returns boolean
language plpgsql
security definer
as $$
declare
  email_exists boolean;
begin
  select exists(
    select 1 
    from auth.users 
    where email = check_email
  ) into email_exists;
  
  return email_exists;
end;
$$;
