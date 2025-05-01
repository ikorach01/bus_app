import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bus_app/features/shared/welcome_page.dart';
import 'package:bus_app/features/user/user_home/home_page.dart';
import 'package:bus_app/features/user/ask_location.dart';
import 'package:bus_app/features/shared/role_selection.dart';
import 'package:bus_app/features/driver/auth/add_information.dart';
import 'package:bus_app/features/driver/driver_home/home_page2.dart';
import 'package:bus_app/features/user/login_page.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bus_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:bus_app/providers/settings_provider.dart';
import 'package:bus_app/features/driver/driver_home/realtime_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global function to test database connection and permissions
Future<void> testDatabaseConnection() async {
  try {
    print('Testing Supabase database connection...');
    final supabase = Supabase.instance.client;
    
    // Test 1: Check if we can query the user_profiles table
    print('Test 1: Querying user_profiles table...');
    try {
      final result = await supabase.from('user_profiles').select('count').limit(1);
      print('User_profiles table query result: $result');
    } catch (e) {
      print('Error querying user_profiles table: $e');
    }
    
    // Test 2: Check database schema
    print('Test 2: Checking database schema...');
    try {
      final tables = await supabase
          .from('information_schema.tables')
          .select('table_name, table_schema')
          .eq('table_schema', 'public');
      print('Available tables: $tables');
    } catch (e) {
      print('Error checking schema: $e');
    }
    
    // Test 3: Check RLS policies
    print('Test 3: Checking RLS policies...');
    try {
      final policies = await supabase
          .from('pg_policies')
          .select('tablename, policyname, cmd, qual')
          .limit(10);
      print('RLS policies: $policies');
    } catch (e) {
      print('Error checking RLS policies: $e');
    }
    
    // Test 4: Try to insert a test record
    print('Test 4: Attempting test insert...');
    try {
      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      await supabase.from('user_profiles').insert({
        'id': testId,
        'email': 'test@example.com',
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Test insert successful');
      
      // Clean up test record
      await supabase.from('user_profiles').delete().eq('id', testId);
      print('Test record deleted');
    } catch (e) {
      print('Error with test insert: $e');
      if (e is PostgrestException) {
        print('PostgrestException code: ${e.code}');
        print('PostgrestException message: ${e.message}');
        print('PostgrestException details: ${e.details}');
      }
    }
    
    print('Database tests completed');
  } catch (e) {
    print('Error during database tests: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rirtlktsgqoadapzhcuk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpcnRsa3RzZ3FvYWRhcHpoY3VrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwNjA5MzIsImV4cCI6MjA1NTYzNjkzMn0.WhfE6GhKsofb_BFmWQ_du3K1a1LdlSZnB3U1_OEPYtM',
  );
  
  // Run database tests
  await testDatabaseConnection();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => RealtimeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  bool _isAppReady = false;
  Widget _initialScreen = const CircularProgressIndicator();

  @override
  void initState() {
    super.initState();
    _initAppLinks();
    _determineInitialScreen();
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAppLink(appLink);
      });
    }

    _appLinks.uriLinkStream.listen((uri) {
      if (mounted) {
        _handleAppLink(uri);
      }
    });

    setState(() {
      _isAppReady = true;
    });
  }

  void _handleAppLink(Uri uri) {
    if (uri.path == '/auth/callback' && _isAppReady) {
      Navigator.pushNamedAndRemoveUntil(context, '/location', (route) => false);
    }
  }

  Future<void> _determineInitialScreen() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try {
        await Supabase.instance.client.auth.refreshSession();
        if (user.emailConfirmedAt != null) {
          // 1. التحقق من SharedPreferences أولاً - هذا أسرع وأكثر أماناً
          final prefs = await SharedPreferences.getInstance();
          final isDriverRegistered = prefs.getBool('driver_${user.id}_registered') ?? false;
          final isPassengerRegistered = prefs.getBool('passenger_${user.id}_registered') ?? false;
          
          print('SharedPreferences check: Driver=$isDriverRegistered, Passenger=$isPassengerRegistered');
          
          // إذا كان لدينا معلومات في SharedPreferences، استخدمها على الفور
          if (isDriverRegistered) {
            print('Using SharedPreferences: User is a registered driver');
            _setInitialScreen(const HomePage2());
            return;
          } else if (isPassengerRegistered) {
            print('Using SharedPreferences: User is a registered passenger');
            _setInitialScreen(const HomePage());
            return;
          }
          
          // 2. إذا لم يكن لدينا معلومات في SharedPreferences، التحقق من جدول drivers
          try {
            print('Checking drivers table');
            final driverResponse = await Supabase.instance.client
                .from('drivers')
                .select('id')
                .eq('id', user.id)
                .maybeSingle();
                
            if (driverResponse != null) {
              // تم العثور على السائق
              print('Driver record found in drivers table');
              await prefs.setBool('driver_${user.id}_registered', true);
              await prefs.setBool('passenger_${user.id}_registered', false);
              _setInitialScreen(const HomePage2());
              return;
            }
          } catch (e) {
            print('Error checking drivers table: $e');
          }
          
          // 3. التحقق من البيانات الوصفية
          final userData = user.userMetadata;
          final userType = userData?['user_type'] as String?;
          
          if (userType == 'driver') {
            print('User metadata indicates user is a driver');
            _setInitialScreen(const AddInformationPage());
            return;
          } else if (userType == 'passenger') {
            print('User metadata indicates user is a passenger');
            await prefs.setBool('passenger_${user.id}_registered', true);
            _setInitialScreen(const HomePage());
            return;
          }
          
          // 4. في النهاية، التحقق من جدول user_profiles
          try {
            print('Last resort: Checking user_profiles table');
            final userProfileResponse = await Supabase.instance.client
                .from('user_profiles')
                .select('user_type')
                .eq('id', user.id)
                .maybeSingle();
            
            if (userProfileResponse != null) {
              final userType = userProfileResponse['user_type'] as String?;
              print('User type from user_profiles: $userType');
              
              // Check role and redirect accordingly
              if (userType == 'driver') {
                // User is a driver, check if already registered
                final prefs = await SharedPreferences.getInstance();
                final isDriverRegistered = prefs.getBool('driver_${user.id}_registered') ?? false;
                
                if (isDriverRegistered) {
                  _setInitialScreen(const HomePage2());
                  print('Driver registered (from SharedPreferences), redirecting to HomePage2');
                  return;
                }
                
                // Check if driver has completed registration in drivers table
                final driverResponse = await Supabase.instance.client
                    .from('drivers')
                    .select('id')
                    .eq('id', user.id);
                
                if (driverResponse != null && driverResponse.isNotEmpty) {
                  // Driver exists in the database, go to HomePage2
                  _setInitialScreen(const HomePage2());
                  print('Driver exists, redirecting to driver HomePage2');
                  await prefs.setBool('driver_${user.id}_registered', true);
                  
                  // Also update user metadata to match user_profiles
                  await Supabase.instance.client.auth.updateUser(UserAttributes(
                    data: {'user_type': 'driver'},
                  ));
                } else {
                  // Driver doesn't exist in database, show registration page
                  _setInitialScreen(const AddInformationPage());
                  print('Driver does not exist, redirecting to AddInformationPage');
                }
              } else if (userType == 'passenger') {
                // User is a passenger
                final prefs = await SharedPreferences.getInstance();
                final isPassengerRegistered = prefs.getBool('passenger_${user.id}_registered') ?? false;
                
                if (isPassengerRegistered) {
                  _setInitialScreen(const HomePage());
                  print('Passenger registered (from SharedPreferences), redirecting to passenger HomePage');
                  return;
                }
                
                // Passenger exists in user_profiles, go to HomePage
                _setInitialScreen(const HomePage());
                print('Passenger exists, redirecting to passenger HomePage');
                await prefs.setBool('passenger_${user.id}_registered', true);
                
                // Also update user metadata to match user_profiles
                await Supabase.instance.client.auth.updateUser(UserAttributes(
                  data: {'user_type': 'passenger'},
                ));
              } else {
                // Role not set or unknown, go to role selection
                final userData = user.userMetadata;
                _setInitialScreen(RoleSelectionPage(
                  userId: user.id,
                  userEmail: user.email ?? '',
                  userPhone: userData?['phone'] as String? ?? '',
                ));
              }
            } else {
              // User profile not found, fallback to checking metadata
              _fallbackToMetadataCheck(user);
            }
          } catch (e) {
            print('Error checking user_profiles table: $e');
            // If there's an error with user_profiles, fallback to metadata
            _fallbackToMetadataCheck(user);
          }
        } else {
          _setInitialScreen(const WelcomePage());
        }
      } catch (e) {
        print('Error refreshing session: $e');
        // If session refresh fails, go to login page
        _setInitialScreen(const LoginPage());
      }
    } else {
      _setInitialScreen(const LoginPage());
    }
  }

  // Fallback method to check user type from metadata if user_profiles check fails
  Future<void> _fallbackToMetadataCheck(User user) async {
    print('Executing fallback to metadata check');

    // ------------------------------------------------------------------------- 
    // STAGE 1: Check driver_profiles table FIRST, since that's the most reliable 
    // ------------------------------------------------------------------------- 
    try {
      // IMPORTANT: First check if driver record exists - this is our most reliable source 
      final driverResponse = await Supabase.instance.client 
          .from('drivers') 
          .select('id') 
          .eq('id', user.id) 
          .maybeSingle(); 
      
      if (driverResponse != null) {
        // The user is DEFINITELY a driver - this takes precedence over anything else 
        print('DRIVER RECORD FOUND! User is definitely a driver'); 
        
        // Update user metadata to set user_type to 'driver' to keep it consistent 
        await Supabase.instance.client.auth.updateUser(UserAttributes( 
          data: {'user_type': 'driver'}, 
        )); 
        
        // Also update user_profiles to ensure consistency 
        try {
          await Supabase.instance.client 
              .from('user_profiles') 
              .upsert({ 
                'id': user.id, 
                'email': user.email ?? '', 
                'phone': user.userMetadata?['phone'] as String? ?? '', 
                'user_type': 'driver', 
                'updated_at': DateTime.now().toIso8601String() 
              }); 
          print('Updated user_profiles to set user_type to driver'); 
        } catch (e) {
          print('Error updating user_profiles: $e'); 
        } 
        
        // Set flag in SharedPreferences 
        final prefs = await SharedPreferences.getInstance(); 
        await prefs.setBool('driver_${user.id}_registered', true); 
        // Clear any passenger flags to prevent confusion 
        await prefs.setBool('passenger_${user.id}_registered', false); 
        
        // Redirect to driver home page 
        _setInitialScreen(const HomePage2()); 
        return; 
      } 
    } catch (e) {
      print('Error checking driver_profiles table: $e'); 
    } 
    
    // ------------------------------------------------------------------------- 
    // STAGE 2: Check user metadata if driver check didn't find anything 
    // ------------------------------------------------------------------------- 
    final userData = user.userMetadata; 
    final userType = userData?['user_type'] as String?; 
    print('User metadata user_type: $userType'); 
    
    if (userType == 'driver') { 
      // User claims to be a driver in metadata, but no driver record found. 
      // Direct to driver registration 
      print('User metadata indicates driver, but no driver record exists'); 
      _setInitialScreen(const AddInformationPage()); 
      return; 
    } 
    
    // ------------------------------------------------------------------------- 
    // STAGE 3: Check user_profiles as final source  
    // ------------------------------------------------------------------------- 
    try {
      final userProfileResponse = await Supabase.instance.client 
          .from('user_profiles') 
          .select('user_type') 
          .eq('id', user.id) 
          .maybeSingle(); 
          
      if (userProfileResponse != null) {
        final dbUserType = userProfileResponse['user_type'] as String?; 
        print('User type from user_profiles fallback check: $dbUserType'); 
        
        if (dbUserType == 'driver') { 
          // User is a driver in user_profiles but has no driver record 
          // They need to complete driver registration 
          print('User marked as driver in profiles but no driver record exists'); 
          _setInitialScreen(const AddInformationPage()); 
          return; 
        } else if (dbUserType == 'passenger') { 
          // User is definitely a passenger 
          final prefs = await SharedPreferences.getInstance(); 
          await prefs.setBool('passenger_${user.id}_registered', true); 
          await prefs.setBool('driver_${user.id}_registered', false); // Clear driver flag 
          
          // Update metadata to match 
          await Supabase.instance.client.auth.updateUser(UserAttributes( 
            data: {'user_type': 'passenger'}, 
          )); 
          
          print('User confirmed as passenger from user_profiles check'); 
          _setInitialScreen(const HomePage()); 
          return; 
        } 
      } 
    } catch (e) {
      print('Error in final user_profiles check: $e'); 
    } 
    
    // ------------------------------------------------------------------------- 
    // STAGE 4: No definitive information found, go to role selection 
    // ------------------------------------------------------------------------- 
    print('No definitive role information found, directing to role selection'); 
    _setInitialScreen(RoleSelectionPage( 
      userId: user.id, 
      userEmail: user.email ?? '', 
      userPhone: userData?['phone'] as String? ?? '', 
    )); 
  }

  void _setInitialScreen(Widget screen) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _initialScreen = screen;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return MaterialApp(
          title: 'Busway',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Instrument Sans',
            brightness: settingsProvider.darkMode ? Brightness.dark : Brightness.light,
          ),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('en', ''), // English, no country code
            const Locale('ar', ''), // Arabic, no country code
          ],
          locale: Locale(settingsProvider.language, ''),
          home: _initialScreen,
          routes: {
            '/location': (context) => const AskLocationScreen(),
            '/home': (context) => const HomePage(),
          },
        );
      }
    );
  }
}