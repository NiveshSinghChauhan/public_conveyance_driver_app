import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:public_transport_driver/class/alert.dart';
import 'package:public_transport_driver/screens/AlertListScreen.dart';
import 'package:public_transport_driver/screens/LoginScreen.dart';
import 'package:toast/toast.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool doTrackPosition = false;
  bool loading = false;
  bool passengerAlertLoading = false;
  bool roadBlockAlertLoading = false;

  String routeId;
  DocumentSnapshot driver;
  List<RoadAlert> alerts = [];
  StreamSubscription<Position> positionStream;
  Position currLocation;

  @override
  initState() {
    super.initState();
    getDriver();
  }

  getDriver() async {
    setState(() {
      loading = true;
    });

    var results = await Future.wait([
      _firebaseFirestore
          .collection('drivers')
          .doc(_firebaseAuth.currentUser.uid)
          .get(),
      _firebaseFirestore
          .collection('vehicles')
          .where('driver_id', isEqualTo: _firebaseAuth.currentUser.uid)
          .get()
          .then((value) => value.docs[0])
          .then((vehicle) => vehicle.get('route'))
    ]);

    driver = results[0];
    routeId = results[1];

    getAlerts();

    setState(() {
      loading = false;
    });
  }

  getAlerts() async {
    _firebaseFirestore
        .collection('routes')
        .doc(routeId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((event) {
      setState(() {
        alerts = event.docs
            .map((e) => RoadAlert.from(
                  address: e.get('address') as String,
                  alertId: e.id,
                  title: e.get('title'),
                  type: e.get('type'),
                  position: e.get('location'),
                ))
            .toList();
      });
    });
  }

  deleteAlert(String alertId) {
    print(alertId);
    _firebaseFirestore
        .collection('routes')
        .doc(routeId)
        .collection('alerts')
        .doc(alertId)
        .delete();
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
      currLocation = position;

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

  alertRoadBlock() async {
    Position mylocation = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    await _firebaseFirestore
        .collection('routes')
        .doc(routeId)
        .collection('alerts')
        .doc()
        .set(RoadAlert.createDocument(
            title: 'Road Block Stated',
            address: (await geo.Geocoder.local.findAddressesFromCoordinates(
                    geo.Coordinates(mylocation.latitude, mylocation.longitude)))
                .first
                .addressLine,
            type: 'road_block',
            position: GeoPoint(mylocation.latitude, mylocation.longitude)));

    Toast.show('Road Block Alertted', context);
  }

  alertPassengerhere() async {
    Position mylocation;
    if (currLocation != null) {
      mylocation = currLocation;
    } else {
      mylocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    }

    await _firebaseFirestore
        .collection('routes')
        .doc(routeId)
        .collection('alerts')
        .doc()
        .set(RoadAlert.createDocument(
            title: 'Passenger Waiting',
            address: (await geo.Geocoder.local.findAddressesFromCoordinates(
                    geo.Coordinates(mylocation.latitude, mylocation.longitude)))
                .first
                .addressLine,
            type: 'passenger',
            position: GeoPoint(mylocation.latitude, mylocation.longitude)));

    Toast.show('Passengers Waiting Stated', context);
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
          : SingleChildScrollView(
              child: Container(
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
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87),
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
                    SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: RaisedButton(
                            color: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            onPressed: passengerAlertLoading
                                ? null
                                : () {
                                    alertPassengerhere();
                                  },
                            child: passengerAlertLoading
                                ? Container(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text('Passengers Here'),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: FlatButton(
                            color: Colors.transparent,
                            textColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.red),
                            ),
                            onPressed: roadBlockAlertLoading
                                ? null
                                : () {
                                    alertRoadBlock();
                                  },
                            child: roadBlockAlertLoading
                                ? Container(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.red),
                                    ),
                                  )
                                : Text('Road Block'),
                          ),
                        ),
                      ],
                    ),
                    if (alerts.length > 0) ...[
                      SizedBox(height: 20),
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 20),
                        child: Text('Alerts'),
                      ),
                      ...alerts.map((alert) => Card(
                            margin: EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              title: Text(alert.title),
                              subtitle: Text(alert.address),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline_rounded),
                                onPressed: () {
                                  deleteAlert(alert.alertId);
                                },
                              ),
                            ),
                          ))
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
