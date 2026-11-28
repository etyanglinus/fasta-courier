/// A ride as the driver's screens read it: what the backend's rider ride endpoints send
/// (RideController::serialize, rider view). Parsed defensively: a missing value shows blank.
class DriverRide {
  final String id;
  final String status;
  final String? pickupAddress;
  final String? destinationAddress;
  final RidePoint? pickup;
  final RidePoint? destination;
  final double fare;
  final double? distanceKm;
  final double? minutes;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String? createdAt;

  const DriverRide({
    required this.id,
    required this.status,
    this.pickupAddress,
    this.destinationAddress,
    this.pickup,
    this.destination,
    this.fare = 0,
    this.distanceKm,
    this.minutes,
    this.paymentStatus,
    this.paymentMethod,
    this.customerName,
    this.customerPhone,
    this.createdAt,
  });

  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String ongoing = 'ongoing';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  bool get isPaid => paymentStatus == 'paid';

  /// Still needs the driver: on the way, on the trip, or finished but cash not recorded.
  bool get isOpen => status == accepted || status == ongoing || (status == completed && !isPaid);

  static DriverRide? tryParse(dynamic json) {
    if (json is! Map) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final customer = json['customer'];
    String? name;
    if (customer is Map) {
      name = [customer['first_name'], customer['last_name']].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
      if (name.isEmpty) name = null;
    }
    return DriverRide(
      id: id,
      status: json['current_status']?.toString() ?? pending,
      pickupAddress: json['pickup_address']?.toString(),
      destinationAddress: json['destination_address']?.toString(),
      pickup: RidePoint.tryParse(json['pickup_coordinates']),
      destination: RidePoint.tryParse(json['destination_coordinates']),
      fare: _num(json['total_fare'] ?? json['estimated_fare']) ?? 0,
      distanceKm: _num(json['estimated_distance']),
      minutes: _num(json['estimated_time']),
      paymentStatus: json['payment_status']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      customerName: name,
      customerPhone: customer is Map ? customer['phone']?.toString() : null,
      createdAt: json['created_at']?.toString(),
    );
  }
}

/// GeoJSON point: `{type: Point, coordinates: [lng, lat]}`.
class RidePoint {
  final double lat;
  final double lng;
  const RidePoint(this.lat, this.lng);

  static RidePoint? tryParse(dynamic json) {
    if (json is! Map || json['coordinates'] is! List || (json['coordinates'] as List).length < 2) return null;
    final list = json['coordinates'] as List;
    final lng = _num(list[0]);
    final lat = _num(list[1]);
    return lat == null || lng == null ? null : RidePoint(lat, lng);
  }

  /// Turn-by-turn directions in Google Maps (or the browser).
  Uri get directions => Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
}

double? _num(dynamic value) => value == null ? null : (value is num ? value.toDouble() : double.tryParse(value.toString()));
