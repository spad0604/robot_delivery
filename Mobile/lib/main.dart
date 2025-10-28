import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/data/services/firebase_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: "assets/.env");
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBP5gSFWa-XYFBhMxFbOcyjwzSycB52suE',
      appId: '1:384967649765:android:01d4e46cddc9d7defc270c',
      messagingSenderId: '384967649765',
      projectId: 'robot-delivery-cbdcf',
      databaseURL: 'https://robot-delivery-cbdcf-default-rtdb.firebaseio.com',
      storageBucket: 'robot-delivery-cbdcf.firebasestorage.app',
    ),
  );
  
  // Initialize Firebase Service
  await Get.putAsync(() => FirebaseService().init());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Robot Delivery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      getPages: AppPages.routes,
    );
  }
}
