import 'package:cosmocat/home/home_page.dart';
import 'package:flutter/material.dart';
import '../size_config.dart';
import 'body.dart';

class Shop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text("Store"),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              padding: EdgeInsets.fromLTRB(4.0, 0, 4.0, 00),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => HomePage()));
              },
              icon: Icon(Icons.arrow_back_rounded),
              color: Colors.white),
        ),
        body: Body());
  }
}
