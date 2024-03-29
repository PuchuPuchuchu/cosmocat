import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'body.dart';

class StatisticsPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false, //fix pixel overflow
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("Statistics"),
        centerTitle: true,
      ),
      body: Body(),
    );
  }
}
