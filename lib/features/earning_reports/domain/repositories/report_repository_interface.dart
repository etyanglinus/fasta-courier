import 'package:fasta_deliveries_delivery/features/earning_reports/domain/models/earning_report_model.dart';
import 'package:fasta_deliveries_delivery/interface/repository_interface.dart';

abstract class EarningReportRepositoryInterface implements RepositoryInterface {
  Future<EarningReportModel?> getEarningReport({
    required int offset,
    required String? from,
    required String? to,
    required bool isDelivery,
  });
}
