import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/place.dart';
import 'models/product.dart';

const columnId = 'id';
const columnTitle = 'title';
const columnIsDeleted = 'isDeleted';
const columnStore = 'store';
const columnLat = 'latitude';
const columnLong = 'longitude';
const columnName = 'name';
const columnImageURL = 'imageUrl';
const columnPrice = 'price';
const columnIsChecked = 'isChecked';
const columnItemTitle = 'itemTitle';

class Item {
  final int? id;
  final String title;
  final bool isDeleted;
  final bool isChecked;

  Item({required this.id, required this.title, required this.isDeleted, required this.isChecked});

  Item.random(String title, bool isDeleted) :
    this.id = null,
    this.title = title,
    this.isDeleted = isDeleted,
    this.isChecked = false;

  // Convert a Map into a Item
  Item.fromDB(Map<String, dynamic> map):
      id = map[columnId],
      title = map[columnTitle],
      isDeleted = map[columnIsDeleted] == 1,
      isChecked = map[columnIsChecked] == 1;

  // Convert a Item into a Map.
  Map<String, dynamic> toMap(){
    return {
      columnId: id,
      columnTitle: title,
      columnIsDeleted: isDeleted ? 1: 0,
      columnIsChecked: isChecked ? 1: 0
    };
  }
}

class DatabaseHelper {
  static final _databaseName = 'MapShopping.db';
  static final _databaseVersion = 1;

  static const itemTable = 'item';
  static const productTable = 'product';
  static const storeTable = 'store';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database?> get database async {
    if(_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // open the database (and create it if it does not exist)
  _initDatabase() async{
    var databasePath = await getDatabasesPath();
    String path = join(databasePath, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $itemTable( 
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT, 
        $columnTitle TEXT, 
        $columnIsDeleted INTEGER,
        $columnIsChecked INTEGER)
    ''');
    await db.execute('''
      CREATE TABLE $productTable( 
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT, 
        $columnTitle TEXT, 
        $columnIsDeleted INTEGER,
        $columnStore TEXT,
        $columnImageURL TEXT,
        $columnPrice REAL,
        $columnItemTitle TEXT)
    ''');
    await db.execute('''
      CREATE TABLE $storeTable( 
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT, 
        $columnName TEXT, 
        $columnLat REAL,
        $columnLong REAL,
        $columnIsDeleted INTEGER)
    ''');
    print('Database was created!');
  }

  // Insert/Find/Update/Delete in itemTable
  Future<int> insertItem(Item item) async{
    Database? db = await instance.database;
    return await db!.insert(itemTable, item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Item>> getAllItems() async {
    Database? db = await instance.database;
    // final sql = 'SELECT * FROM $itemTable WHERE $columnIsDeleted == 0';
    // final List<Map<String, dynamic>> maps = await db!.rawQuery(sql);
    final List<Map<String, dynamic>> maps = await db!.query(
        itemTable,
        where: '$columnIsDeleted = ?',
        whereArgs: [0],
        orderBy: '$columnIsChecked');
    return List.generate(maps.length, (i){
      return Item.fromDB(maps[i]);
    });
  }

  Future<int> updateItem(Item item) async {
    Database? db = await instance.database;
    return db!.update(
      itemTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteItem(int id) async {
    Database? db = await instance.database;
    await db!.delete(
        itemTable,
        where: 'id = ?',
        whereArgs: [id]
    );
  }

  // Insert/Find/Update/Delete in productTable
  Future<int> insertProduct(Product product, String itemTitle) async{
    Database? db = await instance.database;
    Map<String, dynamic> productMap = product.toMap();
    productMap[columnItemTitle] = itemTitle;
    return await db!.insert(productTable, productMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getAllProducts() async {
    Database? db = await instance.database;
    final sql = 'SELECT * FROM $productTable WHERE $columnIsDeleted == 0';
    final List<Map<String, dynamic>> maps = await db!.rawQuery(sql);
    return List.generate(maps.length, (i){
      return Product.fromDB(maps[i]);
    });
  }

  Future<void> deleteProductByName(String name) async {
    Database? db = await instance.database;
    await db!.delete(
        productTable,
        where: '$columnTitle = ?',
        whereArgs: [name]
    );
  }

  Future<bool> isStoreInProductTable(String store) async {
    Database? db = await instance.database;
    return (await db!.query(
        productTable,
        where: '$columnIsDeleted = ? AND $columnStore = ?',
        whereArgs: [0, store], limit: 1)).length > 0;
  }

  Future<void> deleteProductsByItemName(String itemName) async{
    Database? db = await instance.database;
    await db!.delete(
        productTable, where: '$columnItemTitle = ?', whereArgs: [itemName]);
  }

  Future<void> updateProductsByItemName(String itemName, bool isTempDeleted) async{
    Database? db = await instance.database;
    await db!.update(
        productTable,
        {columnIsDeleted: isTempDeleted},
        where: '$columnItemTitle = ?',
        whereArgs: [itemName]
    );
  }

  // Insert/Find/Update/Delete in storeTable
  Future<int> insertStore(Place place) async{
    Database? db = await instance.database;
    return await db!.insert(
        storeTable, place.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Place>> getAllStores() async {
    Database? db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
        storeTable,
        where: '$columnIsDeleted = ?',
        whereArgs: [0]
    );
    return List.generate(maps.length, (i){
      return Place.fromDB(maps[i]);
    });
  }

  Future<void> deleteStoresByName(String storeName) async{
    Database? db = await instance.database;
    await db!.delete(storeTable, where: '$columnName LIKE ?', whereArgs: ['$storeName%']);
  }

}