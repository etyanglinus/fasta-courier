import 'package:fasta_deliveries_delivery/util/app_constants.dart';
import 'package:fasta_deliveries_delivery/util/app_mode_store.dart';
import 'package:fasta_deliveries_delivery/util/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a fresh install is a delivery app', () async {
    SharedPreferences.setMockInitialValues({});
    AppModeStore.load(await SharedPreferences.getInstance());
    expect(AppConstants.appMode, AppMode.delivery);
  });

  test('the account type from login decides, and survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    AppModeStore.load(prefs);
    await AppModeStore.set(AppModeStore.fromAccountType('ride'));
    expect(AppConstants.appMode, AppMode.ride);

    AppModeStore.load(prefs); // next start
    expect(AppConstants.appMode, AppMode.ride);

    await AppModeStore.set(AppModeStore.fromAccountType('delivery'));
    expect(AppConstants.appMode, AppMode.delivery);
  });

  test('a missing or unknown account type means deliveries (old backend)', () {
    expect(AppModeStore.fromAccountType(null), AppMode.delivery);
    expect(AppModeStore.fromAccountType('something'), AppMode.delivery);
  });
}
