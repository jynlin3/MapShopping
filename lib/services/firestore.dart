import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:map_shopper/database_helper.dart';

import '../models/item.dart';

class DatabaseService {
  final String uid;

  DatabaseService({required this.uid});

  // collection reference
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('UserData');

  Future<DocumentReference> insertItem(Item item) {
    return userCollection.doc(uid).collection('Item').add(item.toMap());
  }

  Future<List<Item>> getAllItems() async {
    QuerySnapshot qSnapshot = await userCollection
        .doc(uid)
        .collection('Item')
        .orderBy(columnAddTime, descending: true)
        .get();
    return qSnapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
  }

  Future updateItem(Item item) async {
    await userCollection
        .doc(uid)
        .collection('Item')
        .doc(item.referenceId)
        .update(item.toMap());
  }

  Future deleteItem(Item item) async {
    await userCollection
        .doc(uid)
        .collection('Item')
        .doc(item.referenceId)
        .delete();
  }
}
