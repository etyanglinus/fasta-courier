import 'dart:async';

import 'package:fasta_deliveries_delivery/api/api_client.dart';
import 'package:fasta_deliveries_delivery/api/api_response_extension.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/domain/models/driver_ride.dart';
import 'package:fasta_deliveries_delivery/util/app_constants.dart';
import 'package:get/get.dart';

/// The driver's ride work: requests near them, the ride they are on, and each step of it
/// (accept → pickup code → finish → cash).
///
/// Live updates for rides are not wired yet, so while a ride screen is open the lists are
/// refreshed every [pollEvery] ([startPolling] / [stopPolling]).
class DriverRideController extends GetxController implements GetxService {
  final ApiClient apiClient;
  DriverRideController({required this.apiClient});

  static const Duration pollEvery = Duration(seconds: 6);

  List<DriverRide> requests = const [];
  List<DriverRide> myRides = const [];
  bool loadingRequests = false;
  bool busy = false;
  String? error;
  Timer? _timer;
  int _pollers = 0;

  /// The ride the driver is on (or must still record cash for), if any.
  DriverRide? get currentRide => myRides.where((r) => r.isOpen).firstOrNull;

  DriverRide? ride(String id) => [...myRides, ...requests].where((r) => r.id == id).firstOrNull;

  Future<void> refreshAll() async {
    await Future.wait([loadRequests(), loadMyRides()]);
  }

  Future<void> loadRequests({bool showLoading = false}) async {
    if (showLoading) {
      loadingRequests = true;
      update();
    }
    final response = await apiClient.getData('${AppConstants.rideRequestList}?limit=30&offset=1', handleError: false);
    if (response.statusCode == 200) requests = _rides(response);
    loadingRequests = false;
    update();
  }

  Future<void> loadMyRides() async {
    final response = await apiClient.getData('${AppConstants.ongoingRideList}?limit=30&offset=1', handleError: false);
    if (response.statusCode == 200) {
      myRides = _rides(response);
      update();
    }
  }

  /// One ride's latest state (also works after it was paid and left the open list).
  Future<DriverRide?> loadRide(String id) async {
    final response = await apiClient.getData('${AppConstants.tripDetails}$id', handleError: false);
    if (response.statusCode != 200) return null;
    final ride = DriverRide.tryParse(_data(response));
    if (ride != null) _put(ride);
    return ride;
  }

  Future<bool> accept(String id) => _step(AppConstants.tripAcceptOrReject, {'ride_request_id': id, 'action': 'accept'},
      fallback: 'Someone else took this ride.', onDone: () => requests = requests.where((r) => r.id != id).toList());

  Future<bool> start(String id, String code) =>
      _step(AppConstants.matchOtp, {'ride_request_id': id, 'otp': code.trim()}, fallback: 'That pickup code is not right.');

  Future<bool> finish(String id) =>
      _step(AppConstants.tripStatusUpdate, {'ride_request_id': id, 'status': 'completed'}, fallback: 'Could not finish the trip.');

  Future<bool> cashReceived(String id) =>
      _step(AppConstants.riderPaymentUri, {'ride_request_id': id, 'payment_method': 'cash'}, fallback: 'Could not record the cash.');

  void startPolling() {
    _pollers++;
    _timer ??= Timer.periodic(pollEvery, (_) => refreshAll());
  }

  void stopPolling() {
    _pollers = (_pollers - 1).clamp(0, 1 << 30);
    if (_pollers == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<bool> _step(String uri, Map<String, dynamic> body, {required String fallback, void Function()? onDone}) async {
    if (busy) return false;
    busy = true;
    error = null;
    update();
    final response = await apiClient.postData(uri, body, handleError: false);
    final ok = response.statusCode == 200;
    if (ok) {
      final ride = DriverRide.tryParse(_data(response));
      if (ride != null) _put(ride);
      onDone?.call();
    } else {
      error = _message(response, fallback);
    }
    busy = false;
    update();
    return ok;
  }

  void _put(DriverRide ride) {
    final others = myRides.where((r) => r.id != ride.id).toList();
    myRides = ride.status == DriverRide.pending ? others : [ride, ...others];
  }

  /// Ride endpoints answer `{response_code, message, data: …}` inside the envelope.
  static dynamic _data(Response response) {
    final content = response.content;
    return content is Map && content.containsKey('data') ? content['data'] : content;
  }

  static List<DriverRide> _rides(Response response) {
    final data = _data(response);
    return data is List ? data.map(DriverRide.tryParse).whereType<DriverRide>().toList() : const [];
  }

  static String _message(Response response, String fallback) {
    final body = response.body;
    if (body is Map) {
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty && errors.first is Map && errors.first['message'] != null) {
        return errors.first['message'].toString();
      }
    }
    return response.statusCode == 1 ? (response.statusText ?? fallback) : fallback;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
