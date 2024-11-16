import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_map_in_flutter/database/database_helper.dart';
import 'package:google_map_in_flutter/model/data_model.dart';

class ServiceController extends GetxController {

  final DatabaseHelper db = DatabaseHelper.instance;

  Rxn<List<DataModel>> list =  Rxn<List<DataModel>>();

  Rx<DateTime> selectDay = DateTime.now().obs;
  Rx<DateTime> focusDay = DateTime.now().obs;

  Rx<int> timeInday = 0.obs;


  void onDaySelect(DateTime selectedDay, DateTime focusedDay) {
    selectDay.value = selectedDay;
    focusDay.value = focusedDay;
  }

  Future<void> updateListModel(String dateTime) async {
    timeInday.value = await db.countUniqueTimeInDayByDateTime(dateTime);
    debugPrint(timeInday.value.toString());
  }
}