import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dada_pneumonia_detector/screens/history.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:toast/toast.dart';
import 'package:flutter/services.dart';

var screenWidth = 0.0;
var screenHeight = 0.0;

class Diagnosis extends StatelessWidget {
  const Diagnosis({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    print(screenWidth);
    print(screenHeight);
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Raleway'),
      debugShowCheckedModeBanner: false,
      title: "Pneumonia Diagnosis",
      color: Colors.white,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading;
  File _imageFile;
  var normalCL = 0.0;
  var pneumoniaCL = 0.0;
  UploadTask uploadTask;
  String imageDownloadLink;
  double uploadOpacity = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isLoading = false;
    loadModel();
  }

  pickAnImage() async {
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      print(file.path.toString());
      setState(() {
        _imageFile = file;
        _isLoading = true;
        print("Image Picker loaded");
        pneumoniaCL = 0.0;
        normalCL = 0.0;
      });
    } else {}
  }

  void showToast(String msg, {int duration, int gravity}) {
    Toast.show(
      msg,
      context,
      duration: duration,
      gravity: gravity,
      backgroundColor: Color.fromRGBO(27, 98, 109, 1),
    );
  }

  testModel() async {
    if (_isLoading != true) {
      showToast("Please pick a testing sample",
          gravity: Toast.BOTTOM, duration: 3);
      return;
    }
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.runModelOnImage(
        path: _imageFile.path, // required
        threshold: 0.05,
        imageMean: 127.5,
        imageStd: 127.5, // defaults to 1.0
        numResults: 2, // defaults to 5// defaults to 0.1
        asynch: true // defaults to true
        );
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
    print("The length of the recognition result is:");
    print(recognitions.length);
    var firstResult = recognitions.toList();
    print(firstResult.toString());
    if (firstResult.length == 1) {
      HapticFeedback.heavyImpact();
      if (firstResult[0]["index"] == 0) {
        print("Yes");
        setState(() {
          normalCL = firstResult[0]["confidence"];
          normalCL = normalCL.toDouble() * 100;
          normalCL = dp(normalCL, 0);
          pneumoniaCL = 0.0;
        });
      } else {
        setState(() {
          pneumoniaCL = firstResult[0]["confidence"];
          pneumoniaCL = pneumoniaCL.toDouble() * 100;
          pneumoniaCL = dp(pneumoniaCL, 0);
          normalCL = 0.0;
        });
      }
    } else {
      HapticFeedback.heavyImpact();
      var normal = firstResult[0];
      var pneumonia = firstResult[1];
      setState(() {
        normalCL = normal['confidence'];
        pneumoniaCL = pneumonia['confidence'];
        normalCL = normalCL.toDouble() * 100;
        normalCL = dp(normalCL, 0);
        pneumoniaCL = pneumoniaCL.toDouble() * 100;
        pneumoniaCL = dp(pneumoniaCL, 0);
      });
    }
  }

  double dp(double val, int places) {
    double mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }

  loadModel() async {
    Tflite.close();
    String res = await Tflite.loadModel(
        model: "assets/pneumonia_detector.tflite",
        labels: "assets/labels.txt",
        numThreads: 2, // defaults to 1
        isAsset:
            true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate:
            false // defaults to false, set to true to use GPU delegate
        );
    if (res.isNotEmpty) {
      print("Model Loaded");
    }
  }

//Future<firebase_storage.UploadTask> uploadFile(PickedFile file) async
  Future<dynamic> uploadFile(File file) async {
    // Create a Reference to the file
    setState(() {
      uploadOpacity = 1.0;
    });

    String fileName = '/' +
        'result' +
        new DateTime.now().millisecondsSinceEpoch.toString() +
        '.jpg';
    Reference ref =
        FirebaseStorage.instance.ref().child('results').child(fileName);
    final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': file.path});

    if (kIsWeb) {
      uploadTask = ref.putData(await file.readAsBytes(), metadata);
    } else {
      uploadTask = ref.putFile(File(file.path), metadata);
    }

    return [ref, Future.value(uploadTask)];
  }

  Future<void> _downloadLink(Reference ref) async {
    final link = await ref.getDownloadURL();

    await Clipboard.setData(ClipboardData(
      text: link,
    ));
    print(link.toString());
    imageDownloadLink = link.toString();
    uploadReport();
    showToast("Successfully saved diagnosis to cloud storage",
        gravity: Toast.BOTTOM, duration: 3);
  }

  CollectionReference _diagnosis =
      FirebaseFirestore.instance.collection("diagnosis");
  Future<void> uploadReport() {
    return _diagnosis.add({
      "imageURL": imageDownloadLink,
      "normal": normalCL.toInt(),
      "pneumonia": pneumoniaCL.toInt(),
    }).then((value) {
      setState(() {
        uploadOpacity = 0.0;
        print("Successfully uploaded");
      });
    }).catchError((error) => print("Failed to add user: $error"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(27, 98, 109, 1),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text("Refresh"),
                  onPressed: () {
                    setState(() {
                      normalCL = 0.0;
                      pneumoniaCL = 0.0;
                      _isLoading = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromRGBO(40, 168, 179, 1),
                  )),
            ),
          ),
        ],
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                "AI DOCTOR",
                style: TextStyle(
                  decoration: TextDecoration.overline,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                ".",
                style: TextStyle(
                  decoration: TextDecoration.overline,
                    fontSize: 70,
                    color: Colors.red,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Color.fromRGBO(251, 238, 218, 1),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          pickAnImage();
        },
        child: Icon(
          Icons.image,
          color: Colors.white,
        ),
        backgroundColor:
            Color.fromRGBO(40, 168, 179, 1), //Color.fromRGBO(40, 168, 179, 1),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            // alignment: Alignment.topCenter,
            children: [
              SizedBox(
                height: screenHeight/2.35,
                width: double.infinity,
                child: Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    color: Colors.white,
                    margin: EdgeInsets.only(
                        right: 15.0, left: 15.0, top: 15.0, bottom: 11.0),
                    child: _isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: SizedBox(
                                height: screenHeight/3.36,
                                width: screenWidth/1.8,
                                child: Image.file(
                                  _imageFile,
                                  fit: BoxFit.cover,
                                )),
                          )
                        : SizedBox(
                            child: Center(
                                child: Image.asset("images/diagnosis.png")),
                          )),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 0.0, right: 15.0, left: 15.0),
                child: Card(
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  margin: EdgeInsets.only(bottom: 10.0),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.blueAccent,
                            ),
                            curve: Curves.ease,
                            duration: Duration(milliseconds: 2000),
                            width: normalCL == 0.0 ? 10.0 : 3.4 * normalCL,
                            height: screenHeight/33.6,
                          ),
                        ),
                        SizedBox(height: screenHeight/44.8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Normal Lungs " +
                                "(" +
                                normalCL.toString() +
                                "%)",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                        SizedBox(
                          height: screenHeight/134.4,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.red,
                            ),
                            curve: Curves.ease,
                            duration: Duration(milliseconds: 2000),
                            width:
                                pneumoniaCL == 0.0 ? 10.0 : 3.4 * pneumoniaCL,
                            height: screenHeight/33.6,
                          ),
                        ),
                        SizedBox(height: screenHeight/134.4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Pneumonia Lungs " +
                                "(" +
                                pneumoniaCL.toString() +
                                "%)",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 1.0, right: 15.0, left: 15.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Color.fromRGBO(40, 168, 179, 1),
                      shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(10.0),
                      ),
                      //backgroundColor: MaterialStateProperty.all(
                      // Color.fromRGBO(40, 168, 179, 1))),
                    ),
                    onPressed: () {
                      //loadModel();
                      testModel();
                    },
                    child: Text(
                      "DIAGNOSE",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              MaterialButton(
                onPressed: () async {
                  if (_isLoading) {
                    //[ref,Future.value(uploadTask)]
                    var result = await uploadFile(_imageFile);
                    if (result[1] != null) {
                      print("Upload Successful!");
                      var myRef = result[0];
                      Future.delayed(const Duration(milliseconds: 2000),
                          () async {
                        print(myRef.toString());
                        await _downloadLink(myRef);
                      });
                    }
                  }
                },
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Color.fromRGBO(189, 190, 192, 1.0),
                        gradient: LinearGradient(colors: [
                          Color.fromRGBO(40, 168, 179, 1),
                          Color.fromRGBO(156, 134, 122, 1)
                        ]),
                      ),
                      width: screenWidth/1.44,
                      height: screenHeight/16.8,
                      child: Row(
                        children: [
                          Opacity(
                            opacity: uploadOpacity,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.fromRGBO(255, 150, 110, 1)
                                        .withOpacity(1.0),
                                  ),
                                ),
                                height: screenHeight/33.6,
                                width: screenWidth/18.0,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Save Diagnosis to Cloud",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: screenHeight/12.218,
              width: double.infinity,
              color: Color.fromRGBO(27, 98, 109, 1),
              child: MaterialButton(
                  child: Text(
                    "Show History",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white60,
                        fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => History()),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
