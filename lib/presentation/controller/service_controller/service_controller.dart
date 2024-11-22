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
    timeInday.value = await db.countUniqueTimeInDayByDateTime(dateTime);
    debugPrint(timeInday.value.toString());
  }

  Future<void> getListWithDayAndOrder(String dateTime, int timeInDay) async {
    saveDay.value = dateTime;
    saveTimeInDay.value = timeInDay;
    try {
      N.toShowHistory();
      list.value =
          await db.queryListByDateTimeAndTimeInDay(dateTime, timeInDay);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
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
