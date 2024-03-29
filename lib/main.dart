import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostess/home_screen.dart';
import 'package:hostess/notifier/cart_notifire.dart';
import 'package:hostess/notifier/profile_notifier.dart';
import 'package:hostess/notifier/tab_notifire.dart';
import 'package:provider/provider.dart';
import 'notifier/categories_notifier.dart';

void main() => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => ProfileNotifier(),
          ),
          ChangeNotifierProvider(
            create: (context) => CategoriesNotifier(),
          ),
          ChangeNotifierProvider(
            create: (context) => CartNotifier(),
          ),
          ChangeNotifierProvider(
            create: (context) => TabNotifier(),
          )
        ],
        child: MyApp(),
      ),
    );

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hostess',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CheckConnection(),
    );
  }
}

class CheckConnection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(child: Text("Error: ${snapshot.error}")));
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return HomeScreen();
        }

        return Scaffold(
            body: Center(child: CircularProgressIndicator(strokeWidth: 6)));
      },
    );
  }
}

// flutter build apk --target-platform android-arm
