import 'package:dada_pneumonia_detector/screens/diagnose.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splashscreen/splashscreen.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await firebase_core.Firebase.initializeApp();
  runApp(HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(
          seconds: 5,
          navigateAfterSeconds: new Diagnosis(),
          title: new Text(
            'Welcome!',
            style: TextStyle(
              color: Colors.black,
              fontSize:30,
            ),
          ),
          image: new Image.asset('images/diagnosis.png'),
          backgroundColor: Colors.white,
          styleTextUnderTheLoader: new TextStyle(),
          photoSize: 120.0,
          loaderColor: Colors.red),
    );
  }
}
