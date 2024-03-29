import 'package:cosmocat/database.dart';
import 'package:test/test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group("star system test", () {
    var firestore = FakeFirebaseFirestore();
    DatabaseService ds = new DatabaseService(instanceInjection: firestore);
    test("[get star] value should return 0", () async {
      await ds.userDoc.set({"stars": 0});
      var result = await ds.getStars();
      expect(result, 0);
    });
  });

  group("friend system test", () {
    var firestore = FakeFirebaseFirestore();
    DatabaseService ds = new DatabaseService(instanceInjection: firestore);

    test("[get friendlist] value should return ['1']", () async {
      await ds.userDoc.update({
        'friends': ["1"]
      });
      var result = await ds.getFriendList("0");
      expect(result, ["1"]);
    });

    test("[get friendRequestlist] value should return ['2']", () async {
      await ds.userDoc.update({
        'friendRequest': ["2"]
      });
      var result = await ds.getFriendRequestList("0");
      expect(result, ["2"]);
    });

    test("[is friend] value should return true ", () async {
      var result = await ds.isFriend("0", "1");
      expect(result, true);
    });

    test("[is friend] value should return false ", () async {
      var result = await ds.isFriend("0", "2");
      expect(result, false);
    });

    test("[is request exist] value should return true ", () async {
      var result = await ds.isReqeustExist("2", "0");
      expect(result, true);
    });

    test("[is request exist] value should return false ", () async {
      var result = await ds.isReqeustExist("1", "0");
      expect(result, false);
    });

    test("[is username exist] value should return ture", () async {
      await ds.userDoc.set({"nickname": "bla"});
      var result = await ds.isUserNameExist("bla");
      expect(result, true);
    });

    test("[is username exist] value should return false", () async {
      var result = await ds.isUserNameExist("b");
      expect(result, false);
    });

    test("[send friend request to user] value should return true", () async {
      await ds.userCollection
          .doc("4")
          .set({"nickname": "4", "friendRequest": [], "friends": []});
      var result = await ds.sendFriendRequest("0", "4");
      expect(result, true);
    });

    test("[send repeated friend request] value should return false", () async {
      await ds.sendFriendRequest("0", "4");
      var rqlist = await ds.getFriendRequestList("4");
      expect(rqlist.length == 1, true);
    });

    test("[send friend request to myself] value should return false", () async {
      var result = await ds.sendFriendRequest("0", "bla");
      expect(result, false);
    });

    test("[send friend request to non exist user] value should return false",
        () async {
      var result = await ds.sendFriendRequest("0", "b");
      expect(result, false);
    });

    test("[accept friend rq] value should return true", () async {
      await ds.receiveFriendRequest("4", "0");
      var rqlist = await ds.getFriendRequestList("4");

      expect(rqlist.length == 0, true);
    });
  });

  group("animal system test", () {
    var firestore = FakeFirebaseFirestore();
    DatabaseService ds = new DatabaseService(instanceInjection: firestore);

    test("[get animalList] value should return ['0']", () async {
      await ds.userDoc.update({
        'animals': ["0"]
      });
      var result = await ds.getAnimalList("0");
      expect(result, ["0"]);
    });

    test("[add animal] value should be true", () async {
      await ds.addAnimal("0", "1");
      var animalList = await ds.getAnimalList("0");
      expect(animalList.contains("1"), true);
    });
  });
}
