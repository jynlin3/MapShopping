import 'package:cloud_firestore/cloud_firestore.dart';

import '../database_helper.dart';

class Product {
  String name;
  double price;
  String store;
  String imageURL;
  String brand;
  String itemId;
  String distance = "";
  int id = -1;
  bool isDeleted = true;

  String? referenceId;

  Product(
      {required this.name,
      required this.price,
      required this.store,
      required this.imageURL,
      required this.brand,
      required this.itemId});

  // Convert a Product into a Map.
  Map<String, dynamic> toMap() {
    return {
      columnId: null,
      columnTitle: this.name,
      columnIsDeleted: isDeleted ? 1 : 0,
      columnStore: this.store,
      columnImageURL: this.imageURL,
      columnPrice: this.price,
      columnBrand: this.brand,
      columnItemId: this.itemId,
    };
  }

  // Convert a Map into a Product
  Product.fromDB(Map<String, dynamic> map)
      : id = map[columnId],
        name = map[columnTitle],
        isDeleted = map[columnIsDeleted] == 1,
        store = map[columnStore],
        imageURL = map[columnImageURL],
        price = map[columnPrice],
        brand = map[columnBrand],
        itemId = "";

  // Convert a QueryDocumentSnapshot into a Product
  Product.fromFirestore(QueryDocumentSnapshot doc)
      : id = doc.data()[columnId],
        name = doc.data()[columnTitle],
        isDeleted = doc.data()[columnIsDeleted] == 1,
        store = doc.data()[columnStore],
        imageURL = doc.data()[columnImageURL],
        price = doc.data()[columnPrice],
        brand = doc.data()[columnBrand],
        itemId = doc.data()[columnItemId],
        referenceId = doc.id;
}
