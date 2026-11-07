import 'package:fasta_deliveries_delivery/features/ride_module/safety/domain/repositories/safety_alert_repository_interface.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/safety/domain/services/safety_alert_service_interface.dart';

class SafetyAlertService implements SafetyAlertServiceInterface {
  final SafetyAlertRepositoryInterface safetyAlertRepositoryInterface;
  SafetyAlertService({required this.safetyAlertRepositoryInterface});
}
