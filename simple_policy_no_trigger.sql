-- حل بسيط بدون استخدام trigger
-- يسمح للمستخدمين بإدخال بياناتهم في جدول users بعد التحقق من البريد واختيار الدور

-- حذف السياسات الحالية لتجنب التعارض
DROP POLICY IF EXISTS "Allow users to insert their own record" ON users;
DROP POLICY IF EXISTS "Allow users to select their own data" ON users;
DROP POLICY IF EXISTS "Allow users to update their own data" ON users;
DROP POLICY IF EXISTS "Admins can read all users" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert data" ON users;

-- تأكد من تفعيل أمان الصفوف
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- السياسة الأساسية: تسمح للمستخدمين المصادق عليهم بإدخال بياناتهم
-- هذا هو التغيير الرئيسي الذي سيحل المشكلة
CREATE POLICY "Allow authenticated users to insert data"
ON users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- سياسات أخرى بدون تغيير
CREATE POLICY "Allow users to select their own data"
ON users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Allow users to update their own data"
ON users
FOR UPDATE
TO authenticated
USING (auth.uid() = id);

-- قراءة الجميع إذا كان الدور "admin"
CREATE POLICY "Admins can read all users"
ON users
FOR SELECT
TO authenticated
USING (EXISTS (
  SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
));


alter policy "Admins can update all users"
on "public"."users"
to authenticated
using (
  (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'admin'::text))))

);