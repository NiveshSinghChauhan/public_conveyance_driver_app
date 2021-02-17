import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:public_transport_driver/class/route.dart';
import 'package:public_transport_driver/screens/HomeScreen.dart';

class SetRouteScreen extends StatefulWidget {
  final String vehicleId;

  const SetRouteScreen({@required this.vehicleId});

  @override
  _SetRouteScreenState createState() => _SetRouteScreenState();
}

class _SetRouteScreenState extends State<SetRouteScreen> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<VehicleRoute> routes;
  List<VehicleRoute> visibleRoutes;
  VehicleRoute selectedRoute;

  String settingRouteloading;
  bool gettingRoutesLoading = true;

  @override
  void initState() {
    super.initState();
    getRoute();
  }

  setDriverRoute(VehicleRoute route) async {
    setState(() {
      settingRouteloading = route.routeId;
    });

    await _firestore
        .collection('vehicles')
        .doc(widget.vehicleId)
        .update({'route': route.routeId});

    setState(() {
      selectedRoute = route;
      settingRouteloading = null;
    });
  }

  getRoute() async {
    setState(() {
      gettingRoutesLoading = true;
    });
    var _routes =
        await _firestore.collection('routes').get().then((value) => value.docs);

    routes = _routes.map((QueryDocumentSnapshot route) {
      return VehicleRoute.from(
          routeId: route.id,
          startName: route.get('startName'),
          endName: route.get('endName'),
          startPoint: route.get('startPoint'),
          label: route.get('label'),
          endPoint: route.get('endPoint'),
          points: List.castFrom<dynamic, GeoPoint>(route.get('points')),
          color: Color(int.parse(('0xff${route.get('color')}').toString())));
    }).toList();
    visibleRoutes = List.from(routes);

    setState(() {
      gettingRoutesLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Route'),
      ),
      body: gettingRoutesLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  child: Text(
                    'Select the route on which your vehicle will going to run from the list below.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...visibleRoutes?.map(
                          (route) => ListTile(
                            selected: selectedRoute != null &&
                                selectedRoute.routeId == route.routeId,
                            selectedTileColor: Theme.of(context)
                                .primaryColorLight
                                .withOpacity(0.4),
                            title: Text('Route - ${route.label}'),
                            subtitle: Text(
                              'From ${route.startName} to ${route.endName}',
                            ),
                            trailing: settingRouteloading != null &&
                                    settingRouteloading == route.routeId
                                ? Container(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : selectedRoute != null &&
                                        selectedRoute.routeId == route.routeId
                                    ? Icon(Icons.check_box_outlined)
                                    : Icon(
                                        Icons.check_box_outline_blank_rounded),
                            onTap: () => setDriverRoute(route),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.maxFinite,
                  margin: EdgeInsets.all(10),
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    padding: EdgeInsets.all(15),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(),
                        ),
                      );
                    },
                    child: Text('Continue'),
                  ),
                )
              ],
            ),
    );
  }
}
