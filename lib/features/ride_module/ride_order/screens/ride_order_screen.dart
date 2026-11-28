import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/controllers/driver_ride_controller.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/domain/models/driver_ride.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/screens/driver_trip_screen.dart';
import 'package:fasta_deliveries_delivery/helper/price_converter_helper.dart';
import 'package:fasta_deliveries_delivery/util/dimensions.dart';
import 'package:fasta_deliveries_delivery/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The driver's open rides (on the way, on the trip, or cash still to record). Finished,
/// paid rides are in the income statement and earning report.
class RideOrderScreen extends StatefulWidget {
  const RideOrderScreen({super.key});

  @override
  State<RideOrderScreen> createState() => _RideOrderScreenState();
}

class _RideOrderScreenState extends State<RideOrderScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<DriverRideController>().loadMyRides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('my_rides'.tr), centerTitle: true),
      body: GetBuilder<DriverRideController>(builder: (rides) {
        final open = rides.myRides.where((r) => r.isOpen).toList();
        return RefreshIndicator(
          onRefresh: rides.loadMyRides,
          child: open.isEmpty
              ? ListView(children: [
                  const SizedBox(height: 120),
                  Center(child: Text('No open rides. Finished rides are in your income statement.', style: robotoRegular, textAlign: TextAlign.center)),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  itemCount: open.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Dimensions.paddingSizeSmall),
                  itemBuilder: (_, i) => _RideTile(ride: open[i]),
                ),
        );
      }),
    );
  }
}

class _RideTile extends StatelessWidget {
  final DriverRide ride;
  const _RideTile({required this.ride});

  @override
  Widget build(BuildContext context) {
    final status = switch (ride.status) {
      DriverRide.accepted => 'Going to pickup',
      DriverRide.ongoing => 'On the trip',
      _ => 'Collect payment',
    };
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(ride.destinationAddress ?? '', style: robotoMedium),
        subtitle: Text('$status · ${PriceConverterHelper.convertPrice(ride.fare)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.to(() => DriverTripScreen(rideId: ride.id)),
      ),
    );
  }
}
