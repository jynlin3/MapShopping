import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:map_shopper/database_helper.dart';

import '../models/item.dart';
import '../models/product.dart';
import '../models/search_log.dart';

const collectionItem = 'Item';
const collectionProduct = 'Product';
const collectionSearchLog = 'SearchLog';

class DatabaseService {
  final String uid;

  DatabaseService({required this.uid});

  // collection reference
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('UserData');

  Future<DocumentReference> insertItem(Item item) {
    return userCollection.doc(uid).collection(collectionItem).add(item.toMap());
  }

  Future<List<Item>> getAllItems() async {
    QuerySnapshot qSnapshot = await userCollection
        .doc(uid)
        .collection(collectionItem)
        .orderBy(columnAddTime, descending: true)
        .get();
    return qSnapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
  }

  Future updateItem(Item item) async {
    await userCollection
        .doc(uid)
        .collection(collectionItem)
        .doc(item.referenceId)
        .update(item.toMap());
  }

  Future deleteItem(Item item) async {
    await userCollection
        .doc(uid)
        .collection(collectionItem)
        .doc(item.referenceId)
        .delete();
  }

  Future<List<Product>> getAllProducts() async {
    QuerySnapshot querySnapshot =
        await userCollection.doc(uid).collection(collectionProduct).get();
    return querySnapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  Future<List<Product>> getUnpurchasedProducts() async {
    return (await getAllProducts())
        .where((product) => !product.isDeleted)
        .toList();
  }

  Future<DocumentReference> insertProduct(Product product) {
    product.isDeleted = false;
    return userCollection
        .doc(uid)
        .collection(collectionProduct)
        .add(product.toMap());
  }

  Future deleteProduct(String productId) async {
    await userCollection
        .doc(uid)
        .collection(collectionProduct)
        .doc(productId)
        .delete();
  }

  Future updateProductsByItemId(
      String itemId, Map<String, dynamic> data) async {
    QuerySnapshot querySnapshot =
        await userCollection.doc(uid).collection(collectionProduct).get();
    for (var doc in querySnapshot.docs) {
      if (doc.data()[columnItemId] == itemId) {
        await doc.reference.update(data);
      }
    }
  }

  Future<DocumentReference> insertSearchLog(SearchLog searchLog) {
    return userCollection
        .doc(uid)
        .collection(collectionSearchLog)
        .add(searchLog.toMap());
  }
}
