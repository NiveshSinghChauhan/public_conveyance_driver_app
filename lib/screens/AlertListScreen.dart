import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:public_transport_driver/class/alert.dart';

class AlertListScreen extends StatefulWidget {
  @override
  _AlertListScreenState createState() => _AlertListScreenState();
}

class _AlertListScreenState extends State<AlertListScreen> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  List<RoadAlert> alertList;
  String routeId;
  Stream<List<RoadAlert>> alertListStream;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    getAlerts();
  }

  getAlerts() async {
    setState(() {
      loading = true;
    });

    routeId = await _firestore
        .collection('vehicles')
        .where('driver_id', isEqualTo: _auth.currentUser.uid)
        .get()
        .then((value) => value.docs[0].get('route') as String);

    _firestore
        .collection('routes')
        .doc(routeId)
        .collection('alerts')
        .snapshots()
        .listen((event) {
      alertList = event.docs
          .map((e) => RoadAlert.from(
                address: e.get('address') as String,
                alertId: e.id,
                title: e.get('title'),
                type: e.get('type'),
                position: e.get('location'),
              ))
          .toList();
      setState(() {
        loading = false;
      });
    });
  }

  deleteAlert(String alertId) {
    print(alertId);
    _firestore
        .collection('routes')
        .doc(routeId)
        .collection('alerts')
        .doc(alertId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts'),
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : alertList.length > 0
              ? ListView(
                  children: [
                    ...alertList.map((alert) => Card(
                          child: ListTile(
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
                )
              : Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    children: [
                      Text(
                        'No Alerts',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
    );
  }
}
