import 'package:cosmocat/friendboard/friendRequest/receive_request.dart';
import 'package:cosmocat/friendboard/friendRequest/send_request.dart';
import 'package:flutter/material.dart';

import '../../size_config.dart';

class FriendRequest extends StatefulWidget {
  @override
  _FriendRequestState createState() => _FriendRequestState();
}

class _FriendRequestState extends State<FriendRequest> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return DefaultTabController(
      initialIndex: 1,
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Friend request'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(
                text: "Send",
              ),
              Tab(
                text: "Receive",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            Send(),
            Receive()
          ], //day and week, need to pass vars
        ),
      ),
    );
  }
}
