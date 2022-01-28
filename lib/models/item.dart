import 'package:cloud_firestore/cloud_firestore.dart';

import '../database_helper.dart';

class Item {
  int? id;
  String title;
  bool isDeleted;
  bool isChecked;
  DateTime addTime;

  String? referenceId;

  Item(
      {required this.id,
        required this.title,
        required this.isDeleted,
        required this.isChecked,
        required this.addTime,
        this.referenceId});

  Item.random(String title, bool isDeleted)
      : this.id = null,
        this.title = title,
        this.isDeleted = isDeleted,
        this.isChecked = false,
        this.addTime = DateTime.now().toUtc();

  // Convert a Map into a Item
  Item.fromDB(Map<String, dynamic> map)
      : id = map[columnId],
        title = map[columnTitle],
        isDeleted = map[columnIsDeleted] == 1,
        isChecked = map[columnIsChecked] == 1,
        addTime = map[columnAddTime];

  // Convert a Item into a Map.
  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnTitle: title,
      columnIsDeleted: isDeleted ? 1 : 0,
      columnIsChecked: isChecked ? 1 : 0,
      columnAddTime: addTime
    };
  }

  // Convert a QueryDocumentSnapshot into a Item
  Item.fromFirestore(QueryDocumentSnapshot doc):
      id = doc.data()[columnId],
      title = doc.data()[columnTitle],
      isDeleted = doc.data()[columnIsDeleted] == 1,
      isChecked = doc.data()[columnIsChecked] == 1,
      addTime = doc.data()[columnAddTime].toDate(),
      referenceId = doc.id;
}
