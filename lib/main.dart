import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_map_in_flutter/database/database_helper.dart';
import 'package:google_map_in_flutter/env/app_route.dart';
import 'package:google_map_in_flutter/presentation/controller/root_page_controller/root_page_binding.dart';
import 'package:google_map_in_flutter/presentation/controller/root_page_controller/root_page_controller.dart';
import 'package:google_map_in_flutter/presentation/views/accident_screen/accident_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await requestNotificationPermission();

  await requestLocationPermission();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAncwvOjUr_SQsnM1R8Yr_4CuzHIheubtg',
      appId: '1:490502126854:android:ec4617f1b82470c1e37287',
      messagingSenderId: '490502126854',
      projectId: 'esp32-firebase-gps-4e0df',
      storageBucket: 'esp32-firebase-gps-4e0df.firebasestorage.app',
      databaseURL:
          'https://esp32-firebase-gps-4e0df-default-rtdb.asia-southeast1.firebasedatabase.app',
    ),
  );

  await initializeService();
  Get.put(RootPageController());

  final dbHelper = DatabaseHelper.instance;
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
      iosConfiguration:
          IosConfiguration(onForeground: onStart, autoStart: true),
      androidConfiguration: AndroidConfiguration(
          onStart: onStart, isForegroundMode: true, autoStart: true));

  await service.startService();
}

void onStart(ServiceInstance service) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAncwvOjUr_SQsnM1R8Yr_4CuzHIheubtg',
        appId: '1:490502126854:android:ec4617f1b82470c1e37287',
        messagingSenderId: '490502126854',
        projectId: 'esp32-firebase-gps-4e0df',
        storageBucket: 'esp32-firebase-gps-4e0df.firebasestorage.app',
        databaseURL:
        'https://esp32-firebase-gps-4e0df-default-rtdb.asia-southeast1.firebasedatabase.app',
      ),
    );
  }

  final databaseRef = FirebaseDatabase.instance.ref();
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  notificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        await onSelectNotification(response.payload);
      }
    },
  );

  databaseRef.child('/data').onValue.listen((event) async {
    if (event.snapshot.value != null) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      final int accidentStatus = int.parse(data['accident'].toString());
      final int thiefStatus = int.parse(data['thief'].toString());
      final double latitude =
          double.tryParse(data['LAT'].toString()) ?? 0.0;
      final double longitude =
          double.tryParse(data['LON'].toString()) ?? 0.0;

      if (accidentStatus == 1) {
        notificationsPlugin.show(
          0,
          'Cảnh báo tai nạn',
          'Hệ thống đã phát hiện tai nạn!',
          payload: '{"latitude": $latitude, "longitude": $longitude}',
          NotificationDetails(
            android: AndroidNotificationDetails(
              vibrationPattern:
              Int64List.fromList([0, 5000, 1000, 2000, 1000, 2000]),
              'accident_channel',
              'Accident Alerts',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
        );

        await databaseRef.child('/data/accident').set(0).catchError((error) {
          debugPrint('Error updating accident status: $error');
        });
      }

      if (thiefStatus == 1) {
        notificationsPlugin.show(
          1,
          'Cảnh báo trộm cắp',
          'Hệ thống đã phát hiện có trộm lấy xe!',
          payload: '{"latitude": $latitude, "longitude": $longitude}',
          NotificationDetails(
            android: AndroidNotificationDetails(
              vibrationPattern:
              Int64List.fromList([0, 5000, 1000, 2000, 1000, 2000]),
              'thief_channel',
              'Theft Alerts',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
        );

        await databaseRef.child('/data/thief').set(0).catchError((error) {
          debugPrint('Error updating thief status: $error');
        });
      }

      service.invoke('update', {
        'accident': accidentStatus,
        'thief': thiefStatus,
        'latitude': latitude,
        'longitude': longitude,
      });
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}


Future<void> onSelectNotification(String? payload) async {
  if (payload != null) {
    Map<String, dynamic> data = jsonDecode(payload);

    final double latitude = data['latitude'];
    final double longitude = data['longitude'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(() => AccidentMapScreen(
            latitude: latitude,
            longitude: longitude,
          ));
    });
  }
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

Future<void> requestLocationPermission() async {
  if (await Permission.location.request().isGranted) {
  } else {}
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    Permission.notification.request();
  }
}

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({required this.pageName, this.arrowBack, super.key});

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
