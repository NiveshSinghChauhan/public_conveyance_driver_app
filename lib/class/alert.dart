import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoadAlert {
  String title;
  String address;
  GeoPoint position;
  String type;
  String alertId;

  RoadAlert.from({
    @required this.alertId,
    @required this.title,
    @required this.address,
    @required this.type,
    @required this.position,
  });

  static Map<String, dynamic> createDocument({
    @required String title,
    @required String address,
    @required String type,
    @required GeoPoint position,
  }) =>
      {
        'type': type,
        'address': address,
        'location': position,
        'title': title,
        'timestamp': Timestamp.now()
      };
}
