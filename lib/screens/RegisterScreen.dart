import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:public_transport_driver/screens/LoginScreen.dart';
import 'package:public_transport_driver/screens/SetRouteScreen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final picker = ImagePicker();
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool loading = false;

  String formStatus = 'Verifying phone number';

  File licensePhoto;
  File driverPhoto;

  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController vehicleNoController = TextEditingController();
  TextEditingController drivingLicenseNoController = TextEditingController();

  _onPhoneVerificationCompleted(PhoneAuthCredential credential) async {
    UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    DocumentReference driver =
        _firestore.collection('drivers').doc(userCredential.user.uid);

    setState(() {
      formStatus = 'Uploading Photos';
    });

    List<TaskSnapshot> fileUpload = await Future.wait([
      FirebaseStorage.instance
          .ref()
          .child("drivers")
          .child(driver.id)
          .child("license")
          .putFile(licensePhoto),
      FirebaseStorage.instance
          .ref()
          .child("drivers")
          .child(driver.id)
          .child("face")
          .putFile(driverPhoto),
    ]);

    setState(() {
      formStatus = 'Creating Account';
    });

    DocumentReference vehicle = _firestore.collection('vehicles').doc();

    await Future.wait([
      driver.set({
        'name': nameController.value.text,
        'contact': phoneController.value.text,
        'driving_license_no': drivingLicenseNoController.value.text,
        'vehicle_id': vehicle.id,
        'driving_license_url': fileUpload[0].ref.fullPath,
        'photo_url': fileUpload[1].ref.fullPath,
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
          ? Center(
              child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text(formStatus),
              ],
            ))
          : SingleChildScrollView(
              child: Container(
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
                          SizedBox(height: 10),
                          TextField(
                            controller: drivingLicenseNoController,
                            decoration: InputDecoration(
                                labelText: 'Driving License Number'),
                          ),
                          SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey)),
                                child: licensePhoto != null
                                    ? Image.file(
                                        licensePhoto,
                                        fit: BoxFit.contain,
                                      )
                                    : Container(),
                              ),
                              SizedBox(width: 10),
                              RaisedButton(
                                onPressed: () async {
                                  PickedFile file = await picker.getImage(
                                      source: ImageSource.gallery);

                                  if (file != null) {
                                    setState(() {
                                      licensePhoto = File(file.path);
                                    });
                                  }
                                },
                                child: Text('Upload driving Liciese photo'),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey)),
                                child: driverPhoto != null
                                    ? Image.file(
                                        driverPhoto,
                                        fit: BoxFit.contain,
                                      )
                                    : Container(),
                              ),
                              SizedBox(width: 10),
                              RaisedButton(
                                onPressed: () async {
                                  PickedFile file = await picker.getImage(
                                      source: ImageSource.gallery);

                                  if (file != null) {
                                    setState(() {
                                      driverPhoto = File(file.path);
                                    });
                                  }
                                },
                                child: Text('Upload your photo'),
                              ),
                            ],
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
                    Container(
                      margin: EdgeInsets.only(bottom: 10, top: 30),
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
            ),
    );
  }
}
