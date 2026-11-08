import 'package:fasta_deliveries_delivery/common/models/response_model.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fasta_deliveries_delivery/api/api_client.dart';
import 'package:fasta_deliveries_delivery/features/delivery_module/order/domain/models/ignore_model.dart';
import 'package:fasta_deliveries_delivery/features/delivery_module/order/domain/models/order_count_model.dart';
import 'package:fasta_deliveries_delivery/features/delivery_module/order/domain/models/parcel_cancellation_reasons_model.dart';
import 'package:fasta_deliveries_delivery/features/delivery_module/order/domain/models/update_status_body_model.dart';
import 'package:fasta_deliveries_delivery/features/delivery_module/order/domain/models/update_status_body_model.dart';
import 'package:fasta_deliveries_delivery/interface/repository_interface.dart';

abstract class OrderRepositoryInterface implements RepositoryInterface {
  Future<dynamic> getCancelReasons();
  Future<dynamic> getCompletedOrderList(
    int offset, {
    String orderStatus = 'all',
  });
  Future<dynamic> getCurrentOrders(int offset, {String orderStatus = 'all'});
  Future<dynamic> getLatestOrders();
  Future<dynamic> updateOrderStatus(
    UpdateStatusBodyModel updateStatusBody,
    List<MultipartBody> proofAttachment,
  );
  Future<dynamic> getOrderDetails(int? orderID);
  Future<dynamic> acceptOrder(int? orderID);
  Future<ResponseModel> reportCannotCarry(int? orderID, String reason, String note);
  List<IgnoreModel> getIgnoreList();
  void setIgnoreList(List<IgnoreModel> ignoreList);
  Future<ParcelCancellationReasonsModel?> getParcelCancellationReasons({
    required bool isBeforePickup,
  });
  Future<bool> addParcelReturnDate({
    required int orderId,
    required String returnDate,
  });
  Future<bool> submitParcelReturn({
    required int orderId,
    required String orderStatus,
    required int returnOtp,
  });
  Future<List<OrderCountModel>?> getOrderCount(String type);
  Future<Response?> getDirection({
    required LatLng origin,
    required LatLng destination,
  });
}
