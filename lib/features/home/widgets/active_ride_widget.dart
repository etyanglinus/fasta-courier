import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/controllers/driver_ride_controller.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/domain/models/driver_ride.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/screens/driver_trip_screen.dart';
import 'package:fasta_deliveries_delivery/helper/price_converter_helper.dart';
import 'package:fasta_deliveries_delivery/util/dimensions.dart';
import 'package:fasta_deliveries_delivery/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// On the home screen: the ride the driver is on, one tap from its trip screen.
class ActiveRideWidget extends StatelessWidget {
  const ActiveRideWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DriverRideController>(builder: (rides) {
      final ride = rides.currentRide;
      if (ride == null) return const SizedBox();
      final step = switch (ride.status) {
        DriverRide.accepted => 'Drive to the pickup',
        DriverRide.ongoing => 'On the trip',
        _ => 'Collect payment',
      };
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Card(
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
          color: Theme.of(context).primaryColor,
          child: ListTile(
            leading: const Icon(Icons.directions_car, color: Colors.white),
            title: Text(step, style: robotoBold.copyWith(color: Colors.white)),
            subtitle: Text(
              '${ride.destinationAddress ?? ''} · ${PriceConverterHelper.convertPrice(ride.fare)}',
              style: robotoRegular.copyWith(color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () => Get.to(() => DriverTripScreen(rideId: ride.id)),
          ),
        ),
      );
    });
  }
}
