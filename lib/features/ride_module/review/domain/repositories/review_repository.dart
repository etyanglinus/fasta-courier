import 'package:get/get_connect/http/src/response/response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fasta_deliveries_delivery/api/api_client.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/review/domain/repositories/review_repository_interface.dart';
import 'package:fasta_deliveries_delivery/util/app_constants.dart';

class ReviewRepository implements ReviewRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  ReviewRepository({required this.apiClient, required this.sharedPreferences});
}
