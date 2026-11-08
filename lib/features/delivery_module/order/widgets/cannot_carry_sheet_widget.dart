import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fasta_deliveries_delivery/common/widgets/custom_button_widget.dart';
import 'package:fasta_deliveries_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:fasta_deliveries_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:fasta_deliveries_delivery/util/dimensions.dart';
import 'package:fasta_deliveries_delivery/util/styles.dart';

/// "Can't carry this": the rider's vehicle cannot take this order (too heavy, too big …).
/// The server passes it to a bigger vehicle and flags it for admin, who fixes the product's
/// weight or size (PUT /api/v1/delivery-man/report-cannot-carry).
class CannotCarrySheetWidget extends StatefulWidget {
  final OrderModel orderModel;
  final int index;
  const CannotCarrySheetWidget({super.key, required this.orderModel, required this.index});

  static void show(OrderModel orderModel, int index) {
    Get.bottomSheet(
      CannotCarrySheetWidget(orderModel: orderModel, index: index),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<CannotCarrySheetWidget> createState() => _CannotCarrySheetWidgetState();
}

class _CannotCarrySheetWidgetState extends State<CannotCarrySheetWidget> {
  static const List<String> _reasons = ['too_heavy', 'too_big', 'other'];
  String _reason = 'too_heavy';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('cannot_carry_this'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text('cannot_carry_hint'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value ?? _reason),
              child: Column(children: _reasons.map((reason) => RadioListTile<String>(
                value: reason,
                title: Text(reason.tr),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )).toList()),
            ),
            TextField(
              controller: _noteController,
              maxLength: 255,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'cannot_carry_note_hint'.tr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            GetBuilder<OrderController>(builder: (orderController) {
              return CustomButtonWidget(
                buttonText: 'send_to_a_bigger_vehicle'.tr,
                isLoading: orderController.isLoading,
                onPressed: () async {
                  final bool done = await orderController.reportCannotCarry(
                    widget.orderModel.id, widget.index, _reason, _noteController.text,
                  );
                  if (done && Get.isBottomSheetOpen == true) {
                    Get.back();
                  }
                },
              );
            }),
          ]),
        ),
      ),
    );
  }
}
