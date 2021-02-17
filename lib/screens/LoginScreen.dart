import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:public_transport_driver/screens/HomeScreen.dart';
import 'package:public_transport_driver/screens/RegisterScreen.dart';
import 'package:public_transport_driver/screens/SetRouteScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();

  _onPhoneVerificationCompleted(PhoneAuthCredential credential) async {
    await _firebaseAuth.signInWithCredential(credential);

    setState(() {
      loading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(),
      ),
    );
  }

  _onPhoneVerificaionFailled(FirebaseAuthException e) {
    print('FirebaseAuth Error: ${e.message}');
  }

  _onPhoneVerificationCodeSent(String verificationId, int resendToken) {}
  _onPhoneVerificationCodeAutoRetrivalTimeout(String verificationId) {}

  Future<void> _loginDriver() async {
    if (_formKey.currentState.validate()) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 10),
                  TextFormField(
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Field is required';
                      } else if (value.length != 10) {
                        return 'Phone Number is invalid';
                      }
                    },
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Phone Number'),
                  ),
                  SizedBox(height: 30),
                  Container(
                    width: double.maxFinite,
                    child: RaisedButton(
                      padding: EdgeInsets.all(15),
                      color: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyText1.color,
                      onPressed: loading
                          ? null
                          : () {
                              _loginDriver();
                            },
                      child: loading
                          ? Container(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: Container()),
            Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Text("If you are not registered yet"),
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
                      builder: (context) => RegisterScreen(),
                    ),
                  );
                },
                child: Text('Register'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
