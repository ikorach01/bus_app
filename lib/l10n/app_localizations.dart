import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('ar', ''), // Arabic
  ];

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get settings => Intl.message('Settings', name: 'settings');
  String get notifications => Intl.message('Notifications', name: 'notifications');
  String get delayAlerts => Intl.message('Delay alerts', name: 'delayAlerts');
  String get language => Intl.message('Language', name: 'language');
  String get account => Intl.message('Account', name: 'account');
  String get logout => Intl.message('Logout', name: 'logout');
  String get deleteAccount => Intl.message('Delete account', name: 'deleteAccount');
  String get confirmDelete => Intl.message('Confirm deletion', name: 'confirmDelete');
  String get deleteAccountWarning => Intl.message('Are you sure you want to delete your account? This action cannot be undone.', name: 'deleteAccountWarning');
  String get cancel => Intl.message('Cancel', name: 'cancel');
  String get delete => Intl.message('Delete', name: 'delete');
  String get enabled => Intl.message('enabled', name: 'enabled');
  String get disabled => Intl.message('disabled', name: 'disabled');
  String get logoutFailed => Intl.message('Logout failed', name: 'logoutFailed');
  String get deleteAccountFailed => Intl.message('Delete account failed', name: 'deleteAccountFailed');
  
  // Home page translations
  String get bus => Intl.message('Bus', name: 'bus');
  String get destination => Intl.message('Destination', name: 'destination');
  String get speed => Intl.message('Speed', name: 'speed');
  String get expectedArrival => Intl.message('Expected Arrival', name: 'expectedArrival');
  String get driver => Intl.message('Driver', name: 'driver');
  String get finalDestination => Intl.message('Final Destination', name: 'finalDestination');
  String get close => Intl.message('Close', name: 'close');
  String get selectStation => Intl.message('Select Station', name: 'selectStation');
  String get minutes => Intl.message('minutes', name: 'minutes');
  String get minutesDelay => Intl.message('minutes delay', name: 'minutesDelay');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    Intl.defaultLocale = locale.toString();
    return AppLocalizations();
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}