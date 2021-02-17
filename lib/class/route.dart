import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VehicleRoute {
  String startName;
  String endName;
  Color color;
  GeoPoint startPoint;
  GeoPoint endPoint;
  String routeId;
  String label;
  List<LatLng> routePoints;

  VehicleRoute.from(
      {@required this.routeId,
      @required this.startName,
      @required this.endName,
      @required this.startPoint,
      @required this.endPoint,
      @required this.color,
      @required this.label,
      @required List<GeoPoint> points}) {
    routePoints =
        points.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }
}
