-- First, drop existing conflicting policies
DROP POLICY IF EXISTS "Enable insert for admins" ON public.users;
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Allow users to insert their own data" ON public.users;
DROP POLICY IF EXISTS "Enable read access for admins" ON public.users;

-- Enable RLS on the users table if not already enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows users to insert their own data
CREATE POLICY "Allow users to insert their own data"
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Create a policy that allows admins to insert any user data
CREATE POLICY "Enable insert for admins"
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Create a policy that allows users to view their own data
CREATE POLICY "Users can view their own data"
ON public.users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Create a policy that allows users to update their own data
CREATE POLICY "Users can update their own data"
ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Create a policy that allows admins to view all users
CREATE POLICY "Admins can view all users"
ON public.users
FOR SELECT
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM public.users WHERE role = 'admin'
  ) OR auth.uid() = id
);

-- Create a stored procedure to help with user creation
CREATE OR REPLACE FUNCTION create_user(
  user_id UUID,
  user_email TEXT,
  user_phone TEXT DEFAULT NULL,
  user_role TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  INSERT INTO public.users (id, email, phone, role, created_at)
  VALUES (user_id, user_email, user_phone, user_role, NOW())
  ON CONFLICT (id) DO UPDATE
  SET 
    email = EXCLUDED.email,
    phone = COALESCE(EXCLUDED.phone, users.phone),
    role = COALESCE(EXCLUDED.role, users.role),
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add a special policy to allow the stored procedure to work
CREATE POLICY "Allow function to create users"
ON public.users
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Ensure the users table has the correct structure
-- Run this if you need to create or modify the users table
/*
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL,
  phone TEXT,
  role TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);
*/
