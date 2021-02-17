import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:public_transport_driver/class/route.dart';

class ShowRouteMapScreen extends StatefulWidget {
  @override
  _ShowRouteMapScreenState createState() => _ShowRouteMapScreenState();
}

class _ShowRouteMapScreenState extends State<ShowRouteMapScreen> {
  List<VehicleRoute> routes;
  List<VehicleRoute> visibleRoutes;
  VehicleRoute selectedRoute;
  Position currentPosition;

  @override
  void initState() {
    super.initState();
    getLocation();
    getRoute();
  }

  getLocation() async {
    currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    setState(() {});
  }

  getRoute() async {
    var _routes = await FirebaseFirestore.instance
        .collection('routes')
        .get()
        .then((value) => value.docs);

    routes = _routes.map((QueryDocumentSnapshot route) {
      return VehicleRoute.from(
          routeId: route.id,
          startName: route.get('startName'),
          endName: route.get('endName'),
          startPoint: route.get('startPoint'),
          endPoint: route.get('endPoint'),
          label: route.get('label'),
          points: List.castFrom<dynamic, GeoPoint>(route.get('points')),
          color: Color(int.parse(('0xff${route.get('color')}').toString())));
    }).toList();
    visibleRoutes = List.from(routes);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route'),
      ),
      body: routes != null && currentPosition != null
          ? Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  initialCameraPosition: CameraPosition(
                    zoom: 13,
                    target: LatLng(
                      currentPosition.latitude,
                      currentPosition.longitude,
                    ),
                  ),
                  polylines: {
                    if (routes != null)
                      ...visibleRoutes.map(
                        (route) => Polyline(
                          polylineId: PolylineId(route.routeId),
                          visible: true,
                          color: route.color.withOpacity(0.7),
                          points: route.routePoints,
                          width: 4,
                        ),
                      )
                  },
                ),
                Positioned(
                  bottom: 10,
                  right: 0,
                  left: 0,
                  child: Container(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            ...routes.map((route) => Card(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        visibleRoutes = [route];
                                        selectedRoute = route;
                                      });
                                    },
                                    child: Container(
                                      color: (selectedRoute != null &&
                                              route.routeId ==
                                                  selectedRoute.routeId)
                                          ? Theme.of(context)
                                              .primaryColorLight
                                              .withOpacity(0.3)
                                          : null,
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            children: [
                                              Container(
                                                height: 10,
                                                color: route.color,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Text('Route No. ${route.routeId}'),
                                          SizedBox(height: 10),
                                          Text(
                                            'From ${route.startName} to ${route.endName}',
                                            style:
                                                TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ))
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          : Container(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
