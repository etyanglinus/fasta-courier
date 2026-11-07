import 'package:get/get.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/leaderboard/domain/services/leader_board_service_interface.dart';

class LeaderBoardController extends GetxController implements GetxService {
  final LeaderBoardServiceInterface leaderBoardServiceInterface;
  LeaderBoardController({required this.leaderBoardServiceInterface});
}
