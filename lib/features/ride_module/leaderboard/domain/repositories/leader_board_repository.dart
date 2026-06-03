import 'package:shared_preferences/shared_preferences.dart';
import 'package:fasta_deliveries_delivery/api/api_client.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/leaderboard/domain/repositories/leader_board_repository_interface.dart';

class LeaderBoardRepository implements LeaderBoardRepositoryInterface{
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  LeaderBoardRepository({required this.apiClient, required this.sharedPreferences});
}