-- Drop existing admin select policy
DROP POLICY IF EXISTS "Enable select for admins" ON public.user_profiles;

-- Create new admin select policy that allows admin users to view all profiles
CREATE POLICY "Enable select for admins"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (
  (SELECT user_type FROM public.user_profiles WHERE id = auth.uid()) = 'admin'
);

-- Update other admin policies to use the same condition
DROP POLICY IF EXISTS "Enable update for admins" ON public.user_profiles;
CREATE POLICY "Enable update for admins"
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (
  (SELECT user_type FROM public.user_profiles WHERE id = auth.uid()) = 'admin'
)
WITH CHECK (true);

DROP POLICY IF EXISTS "Enable delete for admins" ON public.user_profiles;
CREATE POLICY "Enable delete for admins"
ON public.user_profiles
FOR DELETE
TO authenticated
USING (
  (SELECT user_type FROM public.user_profiles WHERE id = auth.uid()) = 'admin'
);
