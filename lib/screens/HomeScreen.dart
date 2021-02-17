import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:public_transport_driver/screens/LoginScreen.dart';
import 'package:public_transport_driver/screens/RegisterScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool doTrackPosition = false;
  bool loading = false;
  DocumentSnapshot driver;
  StreamSubscription<Position> positionStream;

  @override
  initState() {
    super.initState();
    getDriver();
  }

  getDriver() async {
    setState(() {
      loading = true;
    });

    driver = await _firebaseFirestore
        .collection('drivers')
        .doc(_firebaseAuth.currentUser.uid)
        .get();

    setState(() {
      loading = false;
    });
  }

  trackPosition(value) {
    setState(() {
      doTrackPosition = value;
    });

    if (value) {
      getLocation();
    } else {
      if (positionStream != null) {
        positionStream.cancel();
      }
    }
  }

  getLocation() async {
    positionStream = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      intervalDuration: Duration(seconds: 1),
    ).listen((Position position) {
      _firebaseFirestore
          .collection('vehicles')
          .doc(driver.get('vehicle_id'))
          .update(
              {'location': GeoPoint(position.latitude, position.longitude)});
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (positionStream != null) {
      positionStream.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          FlatButton(
            onPressed: () async {
              await _firebaseAuth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ),
              );
            },
            child: Text(
              'LOGOUT',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.all(30),
              width: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        style: BorderStyle.solid,
                        color: Colors.blueGrey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Hi, ${(driver.get('name') as String).split(' ')[0]}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 10),
                          child: Text(
                            'Lets get start working, Theirs are lots of people waiting for you.',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Live Location'),
                    subtitle:
                        Text('Turn on your location when you are on duty'),
                    trailing: Switch(
                        value: doTrackPosition, onChanged: trackPosition),
                  ),
                ],
              ),
            ),
    );
  }
}
