-- Reset existing policies
DROP POLICY IF EXISTS "Allow user insertion" ON users;
DROP POLICY IF EXISTS "Allow user updates" ON users;
DROP POLICY IF EXISTS "Allow user to view their data" ON users;
DROP POLICY IF EXISTS "Admin can view all users" ON users;
DROP POLICY IF EXISTS "Admin access" ON users;

-- Enable RLS on the users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 1. Basic insert policy for authenticated users
CREATE POLICY "users_insert_policy"
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = id AND
    role IN ('user', 'driver', 'admin')
);

-- 2. Basic select policy
CREATE POLICY "users_select_policy"
ON public.users
FOR SELECT
TO authenticated
USING (
    auth.uid() = id OR
    EXISTS (
        SELECT 1
        FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND (auth.users.raw_app_meta_data->>'role')::text = 'admin'
    )
);

-- 3. Basic update policy
CREATE POLICY "users_update_policy"
ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (
    auth.uid() = id AND
    role IN ('user', 'driver', 'admin')
);

-- 4. Service role policy (no recursion)
CREATE POLICY "service_role_policy"
ON public.users
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Verify role constraint
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS role_check;
ALTER TABLE public.users ADD CONSTRAINT role_check 
CHECK (role IN ('user', 'driver', 'admin'));

-- Grant necessary permissions
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.users TO service_role;
