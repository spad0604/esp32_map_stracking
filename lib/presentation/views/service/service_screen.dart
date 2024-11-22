import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../main.dart';
import '../../controller/service_controller/service_controller.dart';

class ServiceScreen extends GetView<ServiceController> {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppBarWidget(pageName: 'Service'),
          Expanded(
            child: Container(
              color: const Color(0xFFF8F6F7),
              child: Column(
                children: [
                  Obx(
                        () => TableCalendar(
                      focusedDay: controller.focusDay.value,
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      calendarFormat: CalendarFormat.week,
                      headerVisible: false,
                      selectedDayPredicate: (day) {
                        return isSameDay(controller.selectDay.value, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) async {
                        String formattedDate = DateFormat('dd/MM/yyyy').format(controller.selectDay.value);
                        controller.onDaySelect(selectedDay, focusedDay);
                        await controller.updateListModel(formattedDate);
                      },
                      calendarStyle: const CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(color: Colors.black)
                      ),
                    ),
                  ),
                  Obx(
                        () => Expanded(  // Wrap ListView with Expanded
                      child: ListView.builder(
                          itemCount: controller.timeInday.value,
                          itemBuilder: (context, index) {
                            String formattedDate = DateFormat('dd/MM/yyyy').format(controller.selectDay.value);
                            return GestureDetector(
                              onTap: () async{
                                debugPrint('${formattedDate} index: ${index.toString()}');
                                await controller.getListWithDayAndOrder(formattedDate, index);
                                debugPrint(controller.list.value?.length.toString());
                              },
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white
                                ),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/bicycle_item.png',
                                      width: 60,
                                      height: 60,
                                    ),
                                    const SizedBox(width: 40,),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trip ${index + 1} in day',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black
                                          ),
                                        ),
                                        Text(
                                          'Day: $formattedDate',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 16,
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
