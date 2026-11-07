import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fasta_deliveries_delivery/api/api_client.dart';
import 'package:fasta_deliveries_delivery/api/api_response_extension.dart';
import 'package:fasta_deliveries_delivery/features/my_account/domain/models/withdraw_method_model.dart';
import 'package:fasta_deliveries_delivery/features/disbursement/domain/repositories/disbursement_repository_interface.dart';
import 'package:fasta_deliveries_delivery/features/disbursement/domain/models/disbursement_method_model.dart'
    as disburse;
import 'package:fasta_deliveries_delivery/features/disbursement/domain/models/disbursement_report_model.dart'
    as report;
import 'package:fasta_deliveries_delivery/util/app_constants.dart';

class DisbursementRepository implements DisbursementRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  DisbursementRepository({
    required this.apiClient,
    required this.sharedPreferences,
  });

  @override
  Future<bool> addWithdraw(Map<String?, String> data) async {
    Response response = await apiClient.postData(
      '${AppConstants.addWithdrawMethodUri}?token=${_getUserToken()}',
      data,
    );
    return ApiClient.isSuccess(response.statusCode);
  }

  @override
  Future<disburse.DisbursementMethodBody?> getList() async {
    disburse.DisbursementMethodBody? disbursementMethodBody;
    Response response = await apiClient.getData(
      '${AppConstants.disbursementMethodListUri}?limit=10&offset=1&token=${_getUserToken()}',
    );
    if (response.statusCode == 200) {
      disbursementMethodBody = disburse.DisbursementMethodBody.fromJson(
        response.content,
      );
    }
    return disbursementMethodBody;
  }

  @override
  Future<bool> makeDefaultMethod(Map<String?, String> data) async {
    Response response = await apiClient.postData(
      '${AppConstants.makeDefaultDisbursementMethodUri}?token=${_getUserToken()}',
      data,
    );
    return ApiClient.isSuccess(response.statusCode);
  }

  @override
  Future<bool> delete(int? id) async {
    Response response = await apiClient.postData(
      '${AppConstants.deleteDisbursementMethodUri}?token=${_getUserToken()}',
      {'_method': 'delete', 'id': id},
    );
    return ApiClient.isSuccess(response.statusCode);
  }

  @override
  Future<report.DisbursementReportModel?> getDisbursementReport(
    int offset,
  ) async {
    report.DisbursementReportModel? disbursementReportModel;
    Response response = await apiClient.getData(
      '${AppConstants.getDisbursementReportUri}?limit=10&offset=$offset&token=${_getUserToken()}',
    );
    if (response.statusCode == 200) {
      disbursementReportModel = report.DisbursementReportModel.fromJson(
        response.content,
      );
    }
    return disbursementReportModel;
  }

  @override
  Future<List<WidthDrawMethodModel>?> getWithdrawMethodList() async {
    List<WidthDrawMethodModel>? widthDrawMethods;
    Response response = await apiClient.getData(
      '${AppConstants.withdrawRequestMethodUri}?token=${_getUserToken()}',
    );
    if (response.statusCode == 200) {
      widthDrawMethods = [];
      for (var method in response.contentList) {
        widthDrawMethods.add(WidthDrawMethodModel.fromJson(method));
      }
    }
    return widthDrawMethods;
  }

  String _getUserToken() {
    return sharedPreferences.getString(AppConstants.token) ?? "";
  }

  @override
  Future<bool> createWithdrawRequest(Map<String?, dynamic> data) async {
    Response response = await apiClient.postData(
      '${AppConstants.withdrawRequest}?token=${_getUserToken()}',
      data,
    );
    return ApiClient.isSuccess(response.statusCode);
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future get(int? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body) {
    throw UnimplementedError();
  }
}
