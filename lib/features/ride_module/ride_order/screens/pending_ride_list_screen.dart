import 'package:fasta_deliveries_delivery/common/widgets/custom_button_widget.dart';
import 'package:fasta_deliveries_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:fasta_deliveries_delivery/features/profile/controllers/profile_controller.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/controllers/driver_ride_controller.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/domain/models/driver_ride.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/screens/driver_trip_screen.dart';
import 'package:fasta_deliveries_delivery/helper/price_converter_helper.dart';
import 'package:fasta_deliveries_delivery/util/dimensions.dart';
import 'package:fasta_deliveries_delivery/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Ride requests near the driver (their zone and vehicle type). Accepting opens the trip.
class RideRequestScreen extends StatefulWidget {
  final Function onTap;
  final bool? fromMapScreen;
  const RideRequestScreen({super.key, required this.onTap, this.fromMapScreen = false});
  @override
  RideRequestScreenState createState() => RideRequestScreenState();
}

class RideRequestScreenState extends State<RideRequestScreen> {
  final DriverRideController _rides = Get.find<DriverRideController>();

  @override
  void initState() {
    super.initState();
    _rides.loadRequests(showLoading: true);
    _rides.loadMyRides();
    _rides.startPolling();
  }

  @override
  void dispose() {
    _rides.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ride_request'.tr), centerTitle: true),
      body: GetBuilder<DriverRideController>(builder: (rides) {
        final current = rides.currentRide;
        final online = Get.find<ProfileController>().profileModel?.active == 1;

        return RefreshIndicator(
          onRefresh: rides.refreshAll,
          child: ListView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            children: [
              if (current != null) ...[
                Card(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text('You have a ride in progress', style: robotoBold),
                    subtitle: Text(current.destinationAddress ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.to(() => DriverTripScreen(rideId: current.id)),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ],
              if (!online)
                _Empty(icon: Icons.power_settings_new, text: 'You are offline. Go online on the home screen to get ride requests.')
              else if (rides.loadingRequests && rides.requests.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (rides.requests.isEmpty)
                _Empty(icon: Icons.local_taxi, text: 'No ride requests right now. New ones appear here automatically.')
              else
                for (final ride in rides.requests) ...[
                  _RequestCard(
                    ride: ride,
                    busy: rides.busy,
                    blocked: current != null,
                    onAccept: () async {
                      if (await rides.accept(ride.id)) {
                        Get.to(() => DriverTripScreen(rideId: ride.id));
                      } else {
                        showCustomSnackBar(rides.error);
                        rides.loadRequests();
                      }
                    },
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                ],
            ],
          ),
        );
      }),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final DriverRide ride;
  final bool busy;
  final bool blocked;
  final VoidCallback onAccept;
  const _RequestCard({required this.ride, required this.busy, required this.blocked, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final details = [
      if (ride.distanceKm != null) '${ride.distanceKm!.toStringAsFixed(1)} km',
      if (ride.minutes != null) '${ride.minutes!.round()} min',
    ].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(PriceConverterHelper.convertPrice(ride.fare), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge))),
            if (details.isNotEmpty) Text(details, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(children: [const Icon(Icons.my_location, size: 16), const SizedBox(width: 6), Expanded(child: Text(ride.pickupAddress ?? ''))]),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.location_on, size: 16), const SizedBox(width: 6), Expanded(child: Text(ride.destinationAddress ?? ''))]),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          CustomButtonWidget(
            buttonText: blocked ? 'Finish your current ride first' : 'accept'.tr,
            isLoading: busy,
            onPressed: blocked ? null : onAccept,
          ),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Icon(icon, size: 48, color: Theme.of(context).hintColor),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Text(text, textAlign: TextAlign.center, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
      ]),
    );
  }
}
