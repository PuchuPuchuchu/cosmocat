import 'package:cosmocat/collection/selection.dart';
import 'package:flutter/material.dart';
import 'package:cosmocat/components/background.dart';
import '../size_config.dart';

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  Widget build(BuildContext context) {
    double defaultSize = SizeConfig.defaultSize!;

    return Background(
        child: Padding(
            padding:
                EdgeInsets.only(top: defaultSize * 5, right: defaultSize * 0.5),
            child: Container(
                decoration: new BoxDecoration(
                  image: new DecorationImage(
                    image: new AssetImage("assets/image/collection_book.png"),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Selection())));
  }
}
