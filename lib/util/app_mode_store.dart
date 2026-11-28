import 'package:fasta_deliveries_delivery/util/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which screens the courier app shows: deliveries or rides.
///
/// It used to be fixed at build time (`AppConstants.appMode`), so one APK could only ever be
/// a delivery app or a ride app. Now the signed-in account decides: the login response says
/// `account_type` ('delivery' or 'ride'), and before sign-in the "Join as …" link chosen
/// decides which registration form opens. Kept in SharedPreferences so the app starts in the
/// right mode, and so the notification topics match the account.
class AppModeStore {
  AppModeStore._();

  static const String _key = 'fasta_app_mode';
  static AppMode _current = AppMode.delivery;
  static SharedPreferences? _prefs;

  static AppMode get current => _current;

  static void load(SharedPreferences prefs) {
    _prefs = prefs;
    _current = prefs.getString(_key) == AppMode.ride.name ? AppMode.ride : AppMode.delivery;
  }

  static Future<void> set(AppMode mode) async {
    _current = mode;
    await _prefs?.setString(_key, mode.name);
  }

  /// The login response's `account_type`; anything but 'ride' means deliveries.
  static AppMode fromAccountType(Object? accountType) =>
      accountType?.toString() == 'ride' ? AppMode.ride : AppMode.delivery;
}
