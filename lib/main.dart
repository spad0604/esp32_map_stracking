import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_map_in_flutter/database/database_helper.dart';
import 'package:google_map_in_flutter/env/app_route.dart';
import 'package:google_map_in_flutter/presentation/controller/root_page_controller/root_page_binding.dart';
import 'package:google_map_in_flutter/presentation/controller/root_page_controller/root_page_controller.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAncwvOjUr_SQsnM1R8Yr_4CuzHIheubtg',
      appId: '1:490502126854:android:ec4617f1b82470c1e37287',
      messagingSenderId: '490502126854',
      projectId: 'esp32-firebase-gps-4e0df',
      storageBucket: 'esp32-firebase-gps-4e0df.firebasestorage.app',
      databaseURL: 'https://esp32-firebase-gps-4e0df-default-rtdb.asia-southeast1.firebasedatabase.app',
    ),
  );
  await requestLocationPermission();
  Get.put(RootPageController());

  final dbHelper = DatabaseHelper.instance;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      builder: EasyLoading.init(),
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialBinding: RootPageBinding(),
      initialRoute: AppRoute.ROOT,
      getPages: AppRoute.generateGetPages,
    );
  }
}

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({
    required this.pageName,
    this.arrowBack,
    super.key
  });

  final String pageName;
  final Function()? arrowBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.only(bottom: 5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F6F7),
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                child: Text(
                  pageName,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: arrowBack ?? Get.back,
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

Future<void> requestLocationPermission() async {
  if (await Permission.location.request().isGranted) {
  } else {
  }
}
