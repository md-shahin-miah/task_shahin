import 'package:flutter/material.dart';
import 'package:flutter_order_manager/core/di/service_locator.dart';
import 'package:flutter_order_manager/core/router/navigation_extension.dart';
import 'package:flutter_order_manager/core/theme/app_colors.dart';
import 'package:flutter_order_manager/domain/entities/order.dart';
import 'package:flutter_order_manager/domain/usecases/order_usecases.dart';
import 'package:flutter_order_manager/presentation/providers/order_providers.dart';
import 'package:flutter_order_manager/presentation/widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_bottom_sheet.dart';

final selectedTimeProvider = StateProvider<String>((ref) {
  return '';
});

class TimeSelectionSheet extends StatelessWidget {
  Order order;

  TimeSelectionSheet(this.order, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () =>context.goBack,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.selectedSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildTimeOption('60', 'secs', AppColors.surfaceLight, order.id!),
                      _buildTimeOption('2', 'mins', AppColors.surfaceLight, order.id!),
                      _buildTimeOption('3', 'mins', AppColors.surfaceLight, order.id!),
                      _buildTimeOption('5', 'mins', AppColors.surfaceLight, order.id!),
                      _buildTimeOption('7', 'mins', AppColors.colorGreenLight, order.id!),
                      _buildTimeOption('10', 'mins', AppColors.colorGreenLight, order.id!),
                      _buildTimeOption('15', 'mins', AppColors.colorGreenLight, order.id!),
                      _buildTimeOption('20', 'mins', AppColors.secondarySurfaceLightDeep, order.id!),
                      _buildTimeOption('30', 'mins', AppColors.secondarySurfaceLightDeep, order.id!),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Consumer(
                    builder: (context, ref, child) => CustomButton(
                      text: 'Custom',
                      onPressed: () async {
                        updateOrderStatus('ongoing',order,ref,context,ref.read(selectedTimeProvider));
                      },
                      color: AppColors.secondarySurfaceLightDeep,
                      textColor: AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTimeOption(String time, String unit, Color backgroundColor, int id) {
    final bool isGreen = backgroundColor == const Color(0xFFE6F9EF);
    final bool isOrange = backgroundColor == const Color(0xFFFEEADD);

    return Consumer(
        builder: (context, ref, child) => InkWell(
              onTap: () {
                ref.read(selectedTimeProvider.notifier).state = time=='60'?'1':time;
              },
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: ref.watch(selectedTimeProvider) == time
                      ? Border.all(
                          color: isGreen
                              ? AppColors.success
                              : isOrange
                                  ? AppColors.primary
                                  : AppColors.textLight,
                          width: 1,
                        )
                      : backgroundColor == Colors.white
                          ? Border.all(color: Colors.grey.shade200)
                          : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isGreen
                            ? AppColors.success
                            : isOrange
                                ? AppColors.primary
                                : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14,
                        color: isGreen
                            ? Colors.green
                            : isOrange
                                ? Colors.deepOrange
                                : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }

  Future<void> updateOrderStatus(String nextStatus, Order _currentOrder, WidgetRef ref, BuildContext context, String time) async {
    final updateOrderStatus = getIt<UpdateOrderStatusUseCase>();
    final currentTime = DateTime.now();
    final pickupTime = currentTime.add( Duration(minutes:int.parse(time)));
    final deliveryTime = pickupTime.add(const Duration(minutes: 30));

    _currentOrder.pickupTime = pickupTime;
    _currentOrder.deliveryTime = deliveryTime;

    await updateOrderStatus.execute(_currentOrder, nextStatus);
    ref.invalidate(orderByIdProvider(_currentOrder.id!));
    context.goBack();

    // Refresh the lists
    ref.read(incomingOrdersProvider.notifier).loadOrders();
    ref.read(ongoingOrdersProvider.notifier).loadOrders();
    ref.read(readyOrdersProvider.notifier).loadOrders();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order moved to $nextStatus')),
      );
    }
  }
}
