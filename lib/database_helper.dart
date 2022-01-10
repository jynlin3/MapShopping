import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/product.dart';

const columnId = 'id';
const columnTitle = 'title';
const columnIsDeleted = 'isDeleted';
const columnStore = 'store';

class Item {
  final int id;
  final String title;
  final bool isDeleted;

  Item({required this.id, required this.title, required this.isDeleted});

  Item.random(String title, bool isDeleted) :
    this.id = -1,
    this.title = title,
    this.isDeleted = isDeleted;

  // Convert a Map into a Item
  Item.fromDB(Map<String, dynamic> map):
      id = map[columnId],
      title = map[columnTitle],
      isDeleted = map[columnIsDeleted] == 1;

  // Convert a Item into a Map.
  Map<String, dynamic> toMap(){
    return {
      columnId: id,
      columnTitle: title,
      columnIsDeleted: isDeleted ? 1: 0
    };
  }
}

class DatabaseHelper {
  static final _databaseName = 'MapShopping.db';
  static final _databaseVersion = 1;

  static const itemTable = 'item';
  static const productTable = 'product';

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
        $columnIsDeleted INTEGER)
    ''');
    await db.execute('''
      CREATE TABLE $productTable( 
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT, 
        $columnTitle TEXT, 
        $columnIsDeleted INTEGER,
        $columnStore TEXT)
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
    final sql = 'SELECT * FROM $itemTable WHERE $columnIsDeleted == 0';
    final List<Map<String, dynamic>> maps = await db!.rawQuery(sql);
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
  Future<int> insertProduct(Product product) async{
    Database? db = await instance.database;
    return await db!.insert(productTable, product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getAllProducts() async {
    Database? db = await instance.database;
    final sql = 'SELECT * FROM $productTable WHERE $columnIsDeleted == 0';
    final List<Map<String, dynamic>> maps = await db!.rawQuery(sql);
    return List.generate(maps.length, (i){
      return Product.fromDB(maps[i]);
    });
  }

  Future<void> deleteProduct(String name) async {
    Database? db = await instance.database;
    await db!.delete(
        productTable,
        where: 'title = ?',
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
}