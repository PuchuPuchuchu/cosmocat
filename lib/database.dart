import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cosmocat/Login/log_in.dart';
import 'package:cosmocat/models/app_user.dart';
import 'package:flutter_tags/flutter_tags.dart';

class DatabaseService {
  late CollectionReference userCollection;
  late DocumentReference userDoc;

  DatabaseService({FirebaseFirestore? instanceInjection}) {
    FirebaseFirestore instance;
    String uid;

    if (instanceInjection == null) {
      instance = FirebaseFirestore.instance;
      uid = user!.uid;
    } else {
      instance = instanceInjection;
      uid = "0";
    }

    userCollection = instance.collection('users');
    userDoc = instance.collection('users').doc(uid);
    // focusTimeCollection =
    //     instance.collection('users').doc(uid).collection('FocusTime');

    // tagsCollection = instance.collection('users').doc(uid).collection('Tags');
  }

  Future<void> addUser(AppUser user, String uid) async {
    await userCollection.doc(uid).set({
      'uid': user.uid,
      'email': user.email,
      'nickname': user.nickName,
      'friends': user.friends,
      'animals': user.animals,
      'stars': user.stars
    }).then((value) {
      print("User added");
    }).catchError((error) => print("Failed to add user: $error"));
  }

  Future<String> getUserName(String userId) async {
    late String name;
    DocumentReference docRef = userCollection.doc(userId);
    await docRef.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        name = documentSnapshot.get("nickname");
      } else {
        name = "null";
      }
    });
    return name;
  }

  Future<List<String>> getList(String databaseField, String userId) async {
    late List<String> requestList;
    DocumentReference docRef = userCollection.doc(userId);
    await docRef.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        var requestListRaw = [];
        try {
          requestListRaw = documentSnapshot.get(databaseField);
        } catch (StateError) {
          print("rq list does not exist");
        }

        requestList = List<String>.from(requestListRaw);
      }
    });

    return requestList;
  }

  //friend system
  Future<List<String>> getFriendList(String userId) {
    return getList("friends", userId);
  }

  Future<bool> sendFriendRequest(String senderId, String receiverName) async {
    //assumption: userName is unique

    bool succ = false;

    //check whether user search himself
    if (await getUserName(senderId) == receiverName) return false;

    await userCollection
        .where("nickname", isEqualTo: receiverName)
        .get()
        .then((QuerySnapshot querySnapshot) async {
      if (querySnapshot.size == 0) return false;

      DocumentReference requestDoc = querySnapshot.docs.first.reference;

      //check whether this is a existed friend
      if (await isFriend(senderId, requestDoc.id)) return false;
      //check whether there is alr an exist request
      if (await isReqeustExist(requestDoc.id, senderId)) return false;

      var receiverCurrentRequest = [];

      await requestDoc.get().then((document) {
        try {
          receiverCurrentRequest = document.get("friendRequest");
        } catch (StateError) {
          print("rq list does not exist");
        }

        if (!receiverCurrentRequest.contains(senderId)) {
          receiverCurrentRequest.add(senderId);
        }
      });

      requestDoc.update({
        "friendRequest": [senderId]
      });

      succ = true;
    });

    return succ;
  }

  Future<void> receiveFriendRequest(String id1, String id2) async {
    if (await isFriend(id1, id2)) return;

    //add 1 to 2
    DocumentReference docRef1 = userCollection.doc(id1);
    var friends1 = await getFriendList(id1);
    friends1.add(id2);
    await docRef1.update({"friends": friends1});

    //add 2 to 1
    DocumentReference docRef2 = userCollection.doc(id2);
    var friends2 = await getFriendList(id2);
    friends2.add(id1);
    await docRef2.update({"friends": friends2});

    //delete 2 from 1 request list
    var reqList = await getList("friendRequest", id1);
    reqList.remove(id2);
    await docRef1.update({"friendRequest": reqList});
  }

  Future<bool> isUserNameExist(String receiverName) async {
    bool exist = true;
    await userCollection
        .where("nickname", isEqualTo: receiverName)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.size == 0) {
        exist = false;
      }
    });

    return exist;
  }

  Future<bool> isFriend(String uid, String targetId) async {
    var friendlist = await getFriendList(uid);
    return friendlist.contains(targetId);
  }

  Future<bool> isReqeustExist(String uid, String targetId) async {
    var targetRequestList = await getFriendRequestList(targetId);
    return targetRequestList.contains(uid);
  }

  Future<List<String>> getFriendRequestList(String userId) {
    return getList("friendRequest", userId);
  }

  //anaimal system
  Future<List<String>> getAnimalList(String userId) {
    return getList("animals", userId);
  }

  Future<void> addAnimal(String userId, String animalId) async {
    var animalList = await getAnimalList(userId);
    var doc = userCollection.doc(userId);
    animalList.add(animalId);
    doc.update({"animals": animalList});
  }

  //star
  Future<int> getStars() async {
    int starCount = 0;
    await userDoc.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        starCount = documentSnapshot.get("stars");
      }
    });
    return starCount;
  }

  Future<void> updateStars(int amt) async {
    int starsCount = await getStars();
    userDoc.update({"stars": starsCount + amt});
  }

  //tags
  Future<List<Item>> getTags(String uid) async {
    List<Item> tagList = [];
    var tagsCollection = userCollection.doc(uid).collection('Tags');
    tagsCollection.get().then((querySnapshot) => {
          querySnapshot.docs.forEach((doc) {
            tagList.add(Item(title: doc.id));
          })
        });

    return tagList;
  }

  Future<void> addTag(String tagName) async {
    Map<String, String> field = HashMap<String, String>();
    field['tagName'] = tagName;
    var tagsCollection = userDoc.collection('Tags');
    tagsCollection.doc("$tagName").set(field);
  }

  //focusTime
  Future<void> saveFocusTime(String tagName, int duration, String date) async {
    //update FocusTime->Date->tags[]
    var tagsCollection = userDoc.collection('Tags');
    var focusTimeCollection = userDoc.collection('FocusTime');

    final focusDate = await focusTimeCollection.doc("$date").get();
    if (focusDate.exists) {
      focusTimeCollection.doc("$date").update({
        "tags": FieldValue.arrayUnion([tagName])
      });
    } else {
      focusTimeCollection.doc("$date").set({
        "tags": [tagName]
      });
    }

    //update Tags->tagName->date->currDate(duration:)
    final tagDate = await tagsCollection
        .doc("$tagName")
        .collection("date")
        .doc("$date")
        .get();
    if (tagDate.exists) {
      int originalDur = tagDate.get("duration");
      tagsCollection
          .doc("$tagName")
          .collection("date")
          .doc("$date")
          .set({"duration": originalDur + duration});
    } else {
      tagsCollection
          .doc("$tagName")
          .collection("date")
          .doc("$date")
          .set({"duration": duration});
    }
  }

  Future<num> getTagDurationOfDay(String uid, String tag, String day) async {
    num duration = 0;
    var tagsCollection = userCollection.doc(uid).collection('Tags');
    await tagsCollection
        .doc(tag)
        .collection("date")
        .doc(day)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      duration = documentSnapshot.get("duration");
    });
    return duration;
  }

  Future<num> getTimeOfTheDay(String uid, String day) async {
    num totalMinutes = 0;

    var timeCollection = userCollection.doc(uid).collection('FocusTime');

    //get list of tags used during that day
    await timeCollection
        .doc(day)
        .get()
        .then((DocumentSnapshot documentSnapshot) async {
      if (documentSnapshot.exists) {
        List tagsOfTheDay = documentSnapshot.get("tags");
        for (dynamic tag in tagsOfTheDay) {
          num duration = await getTagDurationOfDay(uid, tag, day);
          totalMinutes += duration;
        }
      }
    });

    return totalMinutes;
  }
}
