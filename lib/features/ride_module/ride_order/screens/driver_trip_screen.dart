import 'package:fasta_deliveries_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:fasta_deliveries_delivery/common/widgets/custom_button_widget.dart';
import 'package:fasta_deliveries_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/controllers/driver_ride_controller.dart';
import 'package:fasta_deliveries_delivery/features/ride_module/ride_order/domain/models/driver_ride.dart';
import 'package:fasta_deliveries_delivery/helper/price_converter_helper.dart';
import 'package:fasta_deliveries_delivery/util/dimensions.dart';
import 'package:fasta_deliveries_delivery/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// One ride, step by step: drive to the pickup → enter the customer's code → drive to the
/// destination → finish → collect cash (or see it was paid from the wallet).
class DriverTripScreen extends StatefulWidget {
  final String rideId;
  const DriverTripScreen({super.key, required this.rideId});

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  final DriverRideController _rides = Get.find<DriverRideController>();
  final TextEditingController _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rides.loadRide(widget.rideId);
    _rides.startPolling();
  }

  @override
  void dispose() {
    _rides.stopPolling();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<bool> Function() step, {String? done}) async {
    final ok = await step();
    if (!ok) {
      showCustomSnackBar(_rides.error);
    } else {
      if (done != null) showCustomSnackBar(done, isError: false);
      await _rides.loadRide(widget.rideId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'trip_details'.tr),
      body: GetBuilder<DriverRideController>(builder: (rides) {
        final ride = rides.ride(widget.rideId);
        if (ride == null) return const Center(child: CircularProgressIndicator());

        return RefreshIndicator(
          onRefresh: () => rides.loadRide(widget.rideId),
          child: ListView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            children: [
              _StepBanner(ride: ride),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              if (ride.customerName != null)
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(ride.customerName!, style: robotoBold),
                    subtitle: Text('Passenger', style: robotoRegular),
                    trailing: (ride.customerPhone ?? '').isEmpty
                        ? null
                        : IconButton.filled(
                            icon: const Icon(Icons.call),
                            onPressed: () => launchUrl(Uri(scheme: 'tel', path: ride.customerPhone)),
                          ),
                  ),
                ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _Place(
                icon: Icons.my_location,
                label: 'Pickup',
                address: ride.pickupAddress,
                point: ride.status == DriverRide.accepted ? ride.pickup : null,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _Place(
                icon: Icons.location_on,
                label: 'Drop-off',
                address: ride.destinationAddress,
                point: ride.status == DriverRide.ongoing ? ride.destination : null,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('fare'.tr, style: robotoMedium),
                Text(PriceConverterHelper.convertPrice(ride.fare), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
              ]),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              ..._actions(context, ride, rides.busy),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _actions(BuildContext context, DriverRide ride, bool busy) {
    switch (ride.status) {
      case DriverRide.accepted:
        return [
          Text('Ask the passenger for their 6-digit pickup code', style: robotoMedium),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: robotoBold.copyWith(fontSize: 24, letterSpacing: 8),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          CustomButtonWidget(
            buttonText: 'Start trip',
            isLoading: busy,
            onPressed: () {
              if (_code.text.trim().length != 6) {
                showCustomSnackBar('Enter the 6-digit code');
                return;
              }
              _run(() => _rides.start(ride.id, _code.text));
            },
          ),
        ];
      case DriverRide.ongoing:
        return [
          CustomButtonWidget(
            buttonText: 'Finish trip',
            isLoading: busy,
            onPressed: () async {
              final sure = await Get.dialog<bool>(AlertDialog(
                title: const Text('Finish this trip?'),
                content: const Text('Only when the passenger has arrived.'),
                actions: [
                  TextButton(onPressed: () => Get.back(result: false), child: Text('no'.tr)),
                  TextButton(onPressed: () => Get.back(result: true), child: Text('yes'.tr)),
                ],
              ));
              if (sure == true) _run(() => _rides.finish(ride.id));
            },
          ),
        ];
      case DriverRide.completed:
        if (ride.isPaid) {
          return [
            Center(child: Text(ride.paymentMethod == 'wallet' ? 'Paid from the passenger\'s wallet' : 'Payment recorded', style: robotoBold)),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            CustomButtonWidget(buttonText: 'Done', onPressed: () => Get.back()),
          ];
        }
        return [
          Center(
            child: Text('Collect ${PriceConverterHelper.convertPrice(ride.fare)} in cash',
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
          ),
          const SizedBox(height: 4),
          Center(child: Text('Or wait: the passenger may pay from their wallet.', style: robotoRegular)),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          CustomButtonWidget(
            buttonText: 'Cash received',
            isLoading: busy,
            onPressed: () => _run(() => _rides.cashReceived(ride.id), done: 'Payment recorded'),
          ),
        ];
      default:
        return [
          Center(child: Text(ride.status == DriverRide.cancelled ? 'The passenger cancelled this ride.' : '', style: robotoBold)),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          CustomButtonWidget(buttonText: 'Back', onPressed: () => Get.back()),
        ];
    }
  }
}

class _StepBanner extends StatelessWidget {
  final DriverRide ride;
  const _StepBanner({required this.ride});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String text) = switch (ride.status) {
      DriverRide.accepted => (Icons.directions_car, 'Drive to the pickup'),
      DriverRide.ongoing => (Icons.route, 'On the trip'),
      DriverRide.completed => (Icons.payments, ride.isPaid ? 'Trip complete' : 'Collect payment'),
      DriverRide.cancelled => (Icons.cancel, 'Ride cancelled'),
      _ => (Icons.hourglass_top, 'Waiting'),
    };
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Text(text, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      ]),
    );
  }
}

class _Place extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? address;
  final RidePoint? point;
  const _Place({required this.icon, required this.label, this.address, this.point});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label, style: robotoMedium.copyWith(color: Theme.of(context).hintColor)),
        subtitle: Text(address ?? '', style: robotoRegular),
        trailing: point == null
            ? null
            : TextButton.icon(
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate'),
                onPressed: () => launchUrl(point!.directions, mode: LaunchMode.externalApplication),
              ),
      ),
    );
  }
}
