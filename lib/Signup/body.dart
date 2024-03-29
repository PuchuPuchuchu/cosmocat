import 'package:cosmocat/components/rounded_empty_field.dart';
import 'package:cosmocat/constant.dart';
import 'package:cosmocat/database.dart';
import 'package:cosmocat/models/app_user.dart';
import 'package:cosmocat/story/page1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cosmocat/components/background.dart';

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  late String _email, _password, _confirmPassword, _userName;
  final auth = FirebaseAuth.instance;

  Future<void> _register() async {
    try {
      final newUser = await auth.createUserWithEmailAndPassword(
          email: _email, password: _password);
      AppUser appUser = new AppUser(email: _email, nickName: _userName);
      final bool exist = await DatabaseService().isUserNameExist(_userName);

      if (!exist) {
        DatabaseService().addUser(appUser, newUser.user!.uid);
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) => Page1()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Username is taken, please select another one"),
        ));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.toString();
      print("Exception in registration: " + errorMessage);
      print(e.code);

      if (e.code == "invalid-email") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Invalid email"),
        ));
      } else if (e.code == "weak-password") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("weak password: should be at least 6 characters"),
        ));
      } else if (e.code == "email-already-in-use") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("You have already registered with this email"),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Background(
        child: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
          SizedBox(
            width: size.width * 0.8,
            height: size.width * 0.1,
          ),
          RoundedEmptyField(
            isPassword: false,
            title: "Email",
            hintText: "must be correct format",
            onChanged: (value) {
              _email = value;
            },
          ),
          RoundedEmptyField(
              isPassword: false,
              title: "Nickname",
              hintText: "type your nickname",
              onChanged: (value) {
                setState(() {
                  _userName = value;
                });
              }),
          RoundedEmptyField(
              hintText: "At least 6 characters",
              onChanged: (value) {
                _password = value;
              },
              title: "Password",
              isPassword: true),
          RoundedEmptyField(
              hintText: "Enter your password again",
              onChanged: (value) {
                _confirmPassword = value;
              },
              title: "Confirm Password",
              isPassword: true),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: distinctPurple, // background
                    onPrimary: Colors.white,
                    side: BorderSide(color: Colors.white),
                  ),
                  onPressed: () {
                    if (_password == _confirmPassword) {
                      _register();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Passwords do not match"),
                      ));
                    }
                  },
                  child: Text("Sign Up",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              Container(
                  width: size.width * 0.4,
                  height: size.height * 0.2,
                  child: Image.asset('assets/image/coma_sign_up.png')),
            ],
          )
        ])));
  }
}
