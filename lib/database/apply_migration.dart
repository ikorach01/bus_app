import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

Future<void> main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  try {
    // Read the migration file
    final migrationFile = await File('lib/database/migrations/20250424_driver_routes_update.sql').readAsString();

    // Execute the migration
    final response = await Supabase.instance.client.rpc('execute_sql', params: {
      'sql': migrationFile,
    });

    print('Migration completed successfully: $response');
  } catch (e) {
    print('Error applying migration: $e');
  }
}
