import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cosmocat/Login/log_in.dart';
import 'package:cosmocat/models/app_user.dart';
import 'package:cosmocat/models/todo_model.dart';
import 'package:flutter_tags/flutter_tags.dart';
import 'package:heatmap_calendar/time_utils.dart';

class DatabaseService {
  late CollectionReference userCollection;
  late DocumentReference userDoc;
  late CollectionReference focusTimeCollection;
  late CollectionReference tagsCollection;
  late CollectionReference townCollection;
  late CollectionReference todoCollection;

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

    tagsCollection = instance.collection('users').doc(uid).collection('Tags');
    townCollection = instance.collection('towns');
    todoCollection = instance.collection('users').doc(uid).collection('Todos');
    focusTimeCollection = instance.collection('users').doc(uid).collection('FocusTime');
  }

  Future<void> addUser(AppUser user, String uid) async {
    await userCollection.doc(uid).set({
      'uid': user.uid,
      'email': user.email,
      'nickname': user.nickName,
      'friends': user.friends,
      'animals': user.animals,
      'stars': user.stars,
      'tags': user.tags,
      'town': '',
      'townAchievements': user.townAchievements
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

      requestDoc.update({
        "friendRequest": FieldValue.arrayUnion([senderId])
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
    if (!animalList.contains(animalId)) animalList.add(animalId);

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

  //user_profile_pic
  Future<String> getProfileAnimal(String uid) async {
    String id = "0";
    DocumentReference currUserDoc = userCollection.doc(uid);

    await currUserDoc.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        id = documentSnapshot.get("uid");
      }
    });
    return id == "" ? "0" : id;
  }

  Future<String> getUserProfileAnimal(String uid) async {
    String id = "0";
    await userDoc.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        id = documentSnapshot.get("uid");
      }
    });
    return id == "" ? "0" : id;
  }

  Future<void> updateProfileAnimal(String id) async {
    userDoc.update({"uid": id});
  }

  //tags
  Future<List<Item>> getTags(String uid) async {
    List<Item> tagList = [];
    List<String> tagStrings = await getList("tags", user!.uid);
    tagStrings.forEach((tagString) {
      tagList.add(Item(title: tagString));
    });
    return tagList;
  }

  Future<void> addTag(String tagName) async {
    Map newPair = new HashMap<String, int>();
    tagsCollection
        .doc("$tagName")
        .set({"tagName": tagName, "dates": [], "date_duration": newPair});
    userDoc.update({
      "tags": FieldValue.arrayUnion([tagName]),
    });
  }

  Future<void> removeTag(String tagName) async {
    userDoc.update({
      "tags": FieldValue.arrayRemove([tagName])
    });
  }

  //focusTime
  Future<void> saveFocusTime(String tagName, int duration, String date) async {
    //update FocusTime->Date->tags[],total time
    var tagsCollection = userDoc.collection('Tags');
    var focusTimeCollection = userDoc.collection('FocusTime');

    final focusDate = await focusTimeCollection.doc("$date").get();
    if (focusDate.exists) {
      focusTimeCollection.doc("$date").update({
        "tags": FieldValue.arrayUnion([tagName]),
        "totalTime": FieldValue.increment(duration)
      });
    } else {
      focusTimeCollection.doc("$date").set({
        "tags": [tagName],
        "totalTime": duration,
        "DateTime": DateTime.now().toString()
      });
    }

    //update Tags->tagName->dates,date_duration pair
    final tagDoc = await tagsCollection.doc("$tagName").get();
    if (tagDoc.exists) {
      //int originalDur = tagDate.get("duration");
      Map originPair = tagDoc.get("date_duration");
      //Map newPair = new HashMap<String, int>();
      originPair.update(date, (value) => value + duration,
          ifAbsent: () => duration);

      tagsCollection.doc("$tagName").update({
        "dates": FieldValue.arrayUnion([date]),
        "date_duration": originPair
      });
    }
  }

  Future<Map<DateTime, int>> heatMapData() async {
    Map<DateTime, int> mapInput = new HashMap<DateTime, int>();
    await focusTimeCollection.get().then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((QueryDocumentSnapshot doc) {
        DateTime dt =
            TimeUtils.removeTime(DateTime.parse('${doc.get("DateTime")}z'));
        int duration = doc.get("totalTime");
        mapInput.putIfAbsent(dt, () => duration);
      });
    });

    return mapInput;
  }

  Future<Map<String, double>> pieChartData(DateTime start, DateTime end) async {
    String startStr = start.subtract(Duration(days: 1)).toString();
    String endStr = end.toString();
    //one more day after end day
    Map<String, double> tagDataMap = new HashMap<String, double>();
    List tagList = [];
    await focusTimeCollection
        .where("DateTime", isGreaterThanOrEqualTo: startStr)
        .where("DateTime", isLessThanOrEqualTo: endStr)
        .get()
        .then((query) {
      query.docs.forEach((doc) async {
        tagList += doc.get("tags");
      });
      tagList = tagList.toSet().toList(); // remove duplicate tags
    });

    tagList.forEach((tag) async {
      double total = 0;
      await tagsCollection.doc(tag).get().then((doc) async {
        Map<String, dynamic> dateDurationPair = await doc.get("date_duration");
        dateDurationPair.removeWhere((date, dur) =>
            date.compareTo(startStr) < 0 || date.compareTo(endStr) > 0);

        dateDurationPair.values.forEach((v) {
          total += v;
        });
      });
      tagDataMap.putIfAbsent(tag.toString(), () => total);
    });

    return tagDataMap;
  }

  Future<num> getTimeOfTheDay(String uid, String day) async {
    num totalMinutes = 0;

    CollectionReference userFocusTime = userCollection.doc(uid).collection('FocusTime');

    await userFocusTime.doc(day).get().then((DocumentSnapshot doc) {
      if (doc.exists) {
        totalMinutes = doc.get("totalTime");
      }
    });
    return totalMinutes;
  }

  Future<num> getTimeOfTheWeek(String uid) async {
    DateTime date = DateTime.now();
    int currDay = date.weekday; //Monday -> 1
    int fromCurrToMon = currDay - 1;
    DateTime monday = date.subtract(Duration(days: fromCurrToMon));
    num time = 0;

    for (int i = 0; i < 7; i++) {
      DateTime thisDay = monday.add(Duration(days: i));
      String date =
          "${thisDay.year}-${thisDay.month.toString().padLeft(2, '0')}-${thisDay.day.toString().padLeft(2, '0')}";

      await DatabaseService().getTimeOfTheDay(uid, date).then((value) {
        time += value;
      });
    }
    return time;
  }

  //town
  Future<String> getTown() async {
    String town = '';
    await userDoc.get().then((DocumentSnapshot doc) {
      town = doc.get("town");
    });
    return town;
  }

  Future<bool> isTownExist(String townName) async {
    bool exist = false;
    await townCollection
        .where("name", isEqualTo: townName)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.size != 0) {
        exist = true;
      }
    });

    return exist;
  }

  Future<void> addTown(String town) async {
    List<String> members = List.of(Iterable.empty());

    await townCollection.doc(town).set({
      'name': town,
      'members': members,
    }).then((value) {
      print("town added");
    });

    await addUserToTown(town);
  }

  Future<void> addUserToTown(String town) async {
    //String userName = await getUserName(user!.uid);

    //update town member
    townCollection.doc(town).update({
      "members": FieldValue.arrayUnion([user!.uid]),
    });

    //update user info
    userDoc.update({
      "town": town,
    });
  }

  Future<void> deleteUserFromTown(String town) async {
    //String userName = await getUserName(user!.uid);

    //print('town: $town');
    //update town member
    townCollection.doc(town).update({
      "members": FieldValue.arrayRemove([user!.uid]),
    });

    //update user info
    userDoc.update({
      "town": '',
    });
  }

  Future<Map<String, num>> getTownMemberAndStars(String town) async {
    Map<String, num> result = new HashMap<String, num>();

    await townCollection
        .doc(town)
        .get()
        .then((DocumentSnapshot documentSnapshot) async {
      List memberList = documentSnapshot.get("members");
      for (String memberId in memberList) {
        num stars = 0;
        String memberName = await getUserName(memberId);
        await userCollection.doc(memberId).get().then((DocumentSnapshot doc) {
          stars = doc.get("stars");
          result.putIfAbsent(memberName, () => stars);
        });
      }
    });

    Map<String, num> sortedMap = Map.fromEntries(result.entries.toList()
      ..sort((e1, e2) => e2.value.compareTo(e1.value)));

    return sortedMap;
  }

  Future<List<num>> getDayMemberList(String town, String date) async {
    List<num> result = [];

    await townCollection
        .doc(town)
        .get()
        .then((DocumentSnapshot documentSnapshot) async {
      List memberList = documentSnapshot.get("members");
      for (String memberId in memberList) {
        num time = 0;
        await userCollection
            .doc(memberId)
            .collection("FocusTime")
            .doc(date)
            .get()
            .then((DocumentSnapshot doc) {
          if (doc.exists) {
            time = doc.get("totalTime");
          }
          result.add(time);
        });
      }
    });

    return result;
  }

  Future<bool> isRewardClaimed(int index, String date) async {
    bool exist = false;
    String curr = '$index-$date';
    await userDoc.get().then((DocumentSnapshot doc) {
      List achieve = doc.get("townAchievements");
      if (achieve.contains(curr)) {
        exist = true;
      }
    });
    return exist;
  }

  Future<void> claimReward(int index, String date) async {
    String curr = '$index-$date';
    await userDoc.update({
      "townAchievements": FieldValue.arrayUnion([curr])
    });
    updateStars(10);
  }

  //todoList
  Future<void> addTodo(ToDoModel todoTask) async {
    todoCollection.doc().set({
      "startTime": todoTask.startDatetime,
      "category": todoTask.category,
      "durationHour": todoTask.durationHour,
      "durationMinute": todoTask.durationMinute,
      "astronautID": todoTask.austronautId,
      "isDone": todoTask.isDone
    });
  }

  Future<void> updateTodoIsDone(ToDoModel todoTask, bool status) async {
    todoCollection.doc(todoTask.docRef).update({"isDone": status});
  }

  Future<List<ToDoModel>> getTodo() async {
    List<ToDoModel> lst = [];
    await todoCollection.get().then((snapshot) => {
          snapshot.docs.forEach((doc) {
            Timestamp timestamp = doc.get("startTime");
            DateTime startDatetime = timestamp.toDate();
            String category = doc.get("category");
            int durationHour = doc.get("durationHour");
            int durationMinute = doc.get("durationMinute");
            String austronautId = doc.get("astronautID");
            bool isDone = doc.get("isDone");
            String ref = doc.id;

            lst.add(ToDoModel.fromDatabase(startDatetime, category,
                durationHour, durationMinute, austronautId, isDone, ref));
          })
        });

    return lst;
  }
}
