import 'package:fasta_deliveries_delivery/api/api_client.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/controllers/driver_ride_controller.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/domain/models/driver_ride.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The backend's rider view of a ride (RideController::serialize), inside the API envelope.
Map<String, dynamic> ride(String id, {String status = 'pending', String payment = 'unpaid', String? method, bool customer = true}) => {
      'id': id, 'ref_id': 'r-$id', 'type': 'ride_request', 'current_status': status,
      'pickup_address': 'Westlands', 'destination_address': 'CBD',
      'pickup_coordinates': {'type': 'Point', 'coordinates': [36.82, -1.28]},
      'destination_coordinates': {'type': 'Point', 'coordinates': [36.8, -1.3]},
      'estimated_fare': '600', 'total_fare': '600', 'estimated_distance': 5.2, 'estimated_time': '15',
      'payment_method': method, 'payment_status': payment, 'otp': null, 'paid_fare': '0',
      'created_at': '2026-11-29T08:00:00.000000Z',
      'customer': customer ? {'id': 3, 'first_name': 'Amina', 'last_name': 'K', 'phone': status == 'pending' ? null : '+254711000000'} : null,
    };

Response envelope(dynamic data, {int status = 200}) => Response(statusCode: status, body: {
      'identical_code': 'default_200', 'message': 'Success',
      'content': {'response_code': 'success', 'message': 'Success', 'data': data, 'total_size': data is List ? data.length : 1},
      'errors': [],
    });

Response refused(int status, String message) => Response(statusCode: status, body: {
      'identical_code': 'x', 'message': 'x', 'content': null, 'errors': [{'code': 'x', 'message': message}],
    });

class FakeApi extends ApiClient {
  FakeApi(SharedPreferences prefs) : super(appBaseUrl: 'https://api.test', sharedPreferences: prefs);
  final Map<String, Response> answers = {};
  final List<String> calls = [];

  Response _answer(String uri) {
    for (final e in answers.entries) {
      if (uri.contains(e.key)) return e.value;
    }
    return const Response(statusCode: 404);
  }

  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) async {
    calls.add(uri);
    return _answer(uri);
  }

  @override
  Future<Response> postData(String uri, dynamic body, {Map<String, String>? headers, bool handleError = true}) async {
    calls.add('$uri $body');
    return _answer(uri);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeApi api;
  late DriverRideController rides;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = FakeApi(await SharedPreferences.getInstance());
    rides = DriverRideController(apiClient: api);
  });

  test('the model reads the rider view of a ride', () {
    final r = DriverRide.tryParse(ride('a', status: 'accepted'))!;
    expect(r.fare, 600);
    expect(r.distanceKm, 5.2);
    expect(r.customerName, 'Amina K');
    expect(r.customerPhone, '+254711000000');
    expect(r.pickup!.lat, -1.28);
    expect(r.pickup!.lng, 36.82);
    expect(r.pickup!.directions.toString(), contains('destination=-1.28,36.82'));
    expect(r.isOpen, isTrue);
    expect(DriverRide.tryParse(ride('b', status: 'completed', payment: 'paid'))!.isOpen, isFalse);
    expect(DriverRide.tryParse(ride('c', status: 'completed'))!.isOpen, isTrue, reason: 'cash still to record');
  });

  test('requests load, and accepting moves the ride to my rides', () async {
    api.answers['pending-ride-list'] = envelope([ride('a'), ride('b')]);
    api.answers['all-ride-list'] = envelope([]);
    await rides.refreshAll();
    expect(rides.requests.map((r) => r.id), ['a', 'b']);
    expect(rides.currentRide, isNull);

    api.answers['trip-action'] = envelope(ride('a', status: 'accepted'));
    expect(await rides.accept('a'), isTrue);
    expect(rides.requests.map((r) => r.id), ['b']);
    expect(rides.currentRide!.id, 'a');
    expect(api.calls.last, contains('action: accept'));
  });

  test('a ride someone else took explains why', () async {
    api.answers['trip-action'] = refused(409, 'Finish the current ride first.');
    expect(await rides.accept('a'), isFalse);
    expect(rides.error, 'Finish the current ride first.');
    api.answers['trip-action'] = const Response(statusCode: 404, body: {'identical_code': 'default_404', 'message': 'Not found', 'content': null, 'errors': []});
    expect(await rides.accept('a'), isFalse);
    expect(rides.error, 'Someone else took this ride.');
  });

  test('pickup code, finish and cash walk the ride to paid', () async {
    api.answers['match-otp'] = refused(422, 'The pickup code is incorrect.');
    expect(await rides.start('a', '111111'), isFalse);
    expect(rides.error, 'The pickup code is incorrect.');

    api.answers['match-otp'] = envelope(ride('a', status: 'ongoing'));
    expect(await rides.start('a', ' 482913 '), isTrue);
    expect(api.calls.last, contains('otp: 482913'));
    expect(rides.currentRide!.status, DriverRide.ongoing);

    api.answers['update-status'] = envelope(ride('a', status: 'completed'));
    expect(await rides.finish('a'), isTrue);
    expect(rides.currentRide!.status, DriverRide.completed);

    api.answers['ride/payment'] = envelope(ride('a', status: 'completed', payment: 'paid', method: 'cash'));
    expect(await rides.cashReceived('a'), isTrue);
    expect(rides.currentRide, isNull, reason: 'paid: nothing left to do');
    expect(rides.ride('a')!.isPaid, isTrue);
  });

  test('polling stops only when the last screen stops it', () {
    rides.startPolling();
    rides.startPolling();
    rides.stopPolling();
    rides.stopPolling();
    rides.stopPolling(); // extra stop is harmless
  });
}
