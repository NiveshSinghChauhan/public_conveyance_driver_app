import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:public_transport_driver/screens/LoginScreen.dart';
import 'package:public_transport_driver/screens/SetRouteScreen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController vehicleNoController = TextEditingController();

  _onPhoneVerificationCompleted(PhoneAuthCredential credential) async {
    UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    DocumentReference driver =
        _firestore.collection('drivers').doc(userCredential.user.uid);

    DocumentReference vehicle = _firestore.collection('vehicles').doc();

    await Future.wait([
      driver.set({
        'name': nameController.value.text,
        'contact': phoneController.value.text,
        'vehicle_id': vehicle.id
      }),
      vehicle.set({
        'driver_id': driver.id,
        'vehicle_number': vehicleNoController.value.text,
      })
    ]);

    setState(() {
      loading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SetRouteScreen(vehicleId: vehicle.id),
      ),
    );
  }

  _onPhoneVerificaionFailled(FirebaseAuthException e) {
    print('FirebaseAuth Error: ${e.message}');
  }

  _onPhoneVerificationCodeSent(String verificationId, int resendToken) {}
  _onPhoneVerificationCodeAutoRetrivalTimeout(String verificationId) {}

  Future<void> registerDriver() async {
    setState(() {
      loading = true;
    });

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: '+91${phoneController.value.text}',
      verificationCompleted: _onPhoneVerificationCompleted,
      verificationFailed: _onPhoneVerificaionFailled,
      codeSent: _onPhoneVerificationCodeSent,
      codeAutoRetrievalTimeout: _onPhoneVerificationCodeAutoRetrivalTimeout,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(labelText: 'Name'),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: phoneController,
                          decoration:
                              InputDecoration(labelText: 'Phone Number'),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: vehicleNoController,
                          decoration:
                              InputDecoration(labelText: 'Vehicle Number'),
                        ),
                        SizedBox(height: 30),
                        Container(
                          width: double.maxFinite,
                          child: RaisedButton(
                            color: Theme.of(context).primaryColor,
                            padding: EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            textColor: Theme.of(context)
                                .primaryTextTheme
                                .bodyText1
                                .color,
                            onPressed: () {
                              registerDriver();
                            },
                            child: Text('Register'),
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(child: Container()),
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text("Already have a account?"),
                  ),
                  Container(
                    width: double.maxFinite,
                    child: FlatButton(
                      padding: EdgeInsets.all(15),
                      color: Colors.transparent,
                      textColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                            color: Theme.of(context).primaryColor, width: 1),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      child: Text('Login'),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
