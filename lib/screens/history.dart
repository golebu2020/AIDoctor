import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class History extends StatelessWidget {
  const History({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(27, 98, 109, 1),
        title: Text(
          "DiGNOSIS HISTORY",
          style: TextStyle(
            decoration: TextDecoration.overline,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: Color.fromRGBO(251, 238, 218, 1),
      body: HistoryList(),
    );
  }
  //Condition Descriptor
}

class HistoryList extends StatefulWidget {
  const HistoryList({Key key}) : super(key: key);

  @override
  _HistoryListState createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  var _diagnosis =
      FirebaseFirestore.instance.collection("diagnosis").orderBy("imageURL").snapshots();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 20.0,
                  color: Colors.blueAccent,
                  child: Center(
                    child: Text(
                      "NORMAL",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.redAccent,
                  height: 20.0,
                  child: Center(
                    child: Text(
                      "PNEUMONIA",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 20,
          child: Card(
            margin: EdgeInsets.only(left:10.0, right:10.0, bottom:10.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            color: Colors.white,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              child: StreamBuilder(
                stream: _diagnosis,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(
                      valueColor:  AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(27, 98, 109, 1)),
                    ));
                  }
                  return ListView(
                    children:
                        snapshot.data?.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data = document.data();
                      var image_data = data['imageURL'];
                      int a = data['normal'];
                      double normalData = a.toDouble();
                      int b = data['pneumonia'];
                      double pneumoniaData = b.toDouble();
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex:4,
                                  child: SizedBox(
                                    child: Image.network(
                                      image_data,
                                      fit: BoxFit.fill,
                                    ),
                                    height: 150.0,
                                  ),
                                ),
                                SizedBox(width:50.0,),
                                Expanded(
                                  flex: 4,
                                  child: Stack(
                                    children: [
                                      Container(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 60.0,
                                              height: 60.0,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 10.0,
                                                backgroundColor: Colors.black12,
                                                value: normalData / 100,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        Colors.blueAccent),
                                              ),
                                            ),
                                            Text(
                                              normalData.toString() + "%",
                                              style: TextStyle(
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 80.0),
                                        child: Container(
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              SizedBox(
                                                width: 60.0,
                                                height: 60.0,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 10.0,
                                                  backgroundColor: Colors.black12,
                                                  value: pneumoniaData / 100,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<Color>(
                                                          Colors.redAccent),
                                                ),
                                              ),
                                              Text(
                                                pneumoniaData.toString() + "%",
                                                style: TextStyle(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(thickness: 0.8,color: Colors.black12.withOpacity(0.05),),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
