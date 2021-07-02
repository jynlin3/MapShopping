import '../database_helper.dart';

class Product {
  String name = "";
  double price = 0;
  String store = "";
  String imageURL = "";
  String brand = "";
  String distance = "";
  int id = -1;
  bool isDeleted = true;

  Product(String name, double price, String store, String imageURL, String brand, String distance){
    this.name = name;
    this.price = price;
    this.store = store;
    this.imageURL = imageURL;
    this.brand = brand;
    this.distance = distance;
  }

  // Convert a Item into a Map.
  Map<String, dynamic> toMap(){
    return {
      columnId: null,
      columnTitle: this.name,
      columnIsDeleted: isDeleted ? 1 : 0
    };
  }

  // Convert a Map into a Item
  Product.fromDB(Map<String, dynamic> map):
        id = map[columnId],
        name = map[columnTitle],
        isDeleted = map[columnIsDeleted] == 1;
}