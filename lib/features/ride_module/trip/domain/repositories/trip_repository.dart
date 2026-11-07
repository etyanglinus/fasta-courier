import 'package:shared_preferences/shared_preferences.dart';
import 'package:fasta_deliveries_delivery/api/api_client.dart';
import 'trip_repository_interface.dart';

class TripRepository implements TripRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  TripRepository({required this.sharedPreferences, required this.apiClient});
}
