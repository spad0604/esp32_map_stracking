import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_map_in_flutter/database/database_helper.dart';
import 'package:google_map_in_flutter/model/data_model.dart';

import '../../../env/app_navigator.dart';

class ServiceController extends SuperController {
  final DatabaseHelper db = DatabaseHelper.instance;

  Rxn<List<DataModel>> list = Rxn<List<DataModel>>();

  Rx<DateTime> selectDay = DateTime.now().obs;
  Rx<DateTime> focusDay = DateTime.now().obs;

  Rx<int> timeInday = 0.obs;

  Rx<int> saveTimeInDay = 0.obs;
  Rx<String> saveDay = ''.obs;

  void onDaySelect(DateTime selectedDay, DateTime focusedDay) {
    selectDay.value = selectedDay;
    focusDay.value = focusedDay;
  }

  Future<void> updateListModel(String dateTime) async {
    try {
      timeInday.value = await db.countUniqueTimeInDayByDateTime(dateTime);
      debugPrint('Found ${timeInday.value} trips for date: $dateTime');
      
      // Thêm debug info về database
      final hasData = await db.hasData();
      final stats = await db.getDatabaseStats();
      debugPrint('Database has data: $hasData');
      debugPrint('Database stats: $stats');
      
      if (timeInday.value == 0) {
        debugPrint('No trips found for $dateTime. Checking all available dates...');
        final trips = await db.getTripsByDate(dateTime);
        debugPrint('Available trips for $dateTime: $trips');
      }
    } catch (e) {
      debugPrint('Error in updateListModel: $e');
    }
  }

  Future<void> getListWithDayAndOrder(String dateTime, int timeInDay) async {
    saveDay.value = dateTime;
    saveTimeInDay.value = timeInDay;
    try {
      debugPrint('Getting trip data for date: $dateTime, timeInDay: $timeInDay');
      N.toShowHistory();
      list.value = await db.queryListByDateTimeAndTimeInDay(dateTime, timeInDay);
      debugPrint('Retrieved ${list.value?.length ?? 0} data points');
      
      if (list.value?.isEmpty ?? true) {
        debugPrint('No data found. Checking database...');
        final allTrips = await db.getTripsByDate(dateTime);
        debugPrint('All trips for $dateTime: $allTrips');
      }
    } catch (e) {
      debugPrint('Error in getListWithDayAndOrder: $e');
    }
  }

  @override
  void onDetached() {
  }

  @override
  void onHidden() {
  }

  @override
  void onInactive() {
  }

  @override
  void onPaused() {
  }

  @override
  void onResumed() {
  }
}
