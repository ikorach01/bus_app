-- Reset existing policies
DROP POLICY IF EXISTS "Allow user insertion" ON users;
DROP POLICY IF EXISTS "Allow user updates" ON users;
DROP POLICY IF EXISTS "Allow user to view their data" ON users;
DROP POLICY IF EXISTS "Admin can view all users" ON users;

-- Enable RLS on the users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 1. Allow insertion for authenticated users
CREATE POLICY "Allow user insertion"
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (true);

-- 2. Allow users to view their own data
CREATE POLICY "Allow user to view their data"
ON public.users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- 3. Allow users to update their own data
CREATE POLICY "Allow user updates"
ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. Allow service role (admin) access without recursion
CREATE POLICY "Admin access"
ON public.users
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Grant necessary permissions
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.users TO service_role;
