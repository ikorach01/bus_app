-- Drop the existing table if it exists
DROP TABLE IF EXISTS public.user_profiles;

-- Create new user_profiles table
CREATE TABLE public.user_profiles (
    id uuid NOT NULL PRIMARY KEY,
    email text NOT NULL,
    phone text NOT NULL,
    user_type text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_type_check CHECK (user_type IN ('passenger', 'driver', 'admin'))
);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable select for users" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable update for users" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable delete for users" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable select for admins" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable update for admins" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable delete for admins" ON public.user_profiles;

-- Create simple policies
-- Allow any authenticated user to insert data (to avoid circular dependency)
CREATE POLICY "Enable insert for authenticated users"
ON public.user_profiles
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow users to view their own profile
CREATE POLICY "Enable select for users"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Enable update for users"
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Allow users to delete their own profile
CREATE POLICY "Enable delete for users"
ON public.user_profiles
FOR DELETE
TO authenticated
USING (auth.uid() = id);

-- Allow admins to view all profiles
CREATE POLICY "Enable select for admins"
ON public.user_profiles
FOR SELECT
TO service_role
USING (true);

-- Allow admins to update all profiles
CREATE POLICY "Enable update for admins"
ON public.user_profiles
FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);

-- Allow admins to delete all profiles
CREATE POLICY "Enable delete for admins"
ON public.user_profiles
FOR DELETE
TO service_role
USING (true);

-- Grant permissions
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.user_profiles TO service_role;
