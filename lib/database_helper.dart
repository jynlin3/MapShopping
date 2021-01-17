import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const columnId = 'id';
const columnTitle = 'title';
const columnIsDeleted = 'isDeleted';

class Item {
  final int id;
  final String title;
  final bool isDeleted;

  Item({this.id, this.title, this.isDeleted});

  Item.random(String title, bool isDeleted) :
    this.id = null,
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
  static final _databaseName = "MapShopping.db";
  static final _databaseVersion = 1;

  static const itemTable = 'item';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;
  Future<Database> get database async {
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
    print("Database was created!");
  }

  Future<int> insertItem(Item item) async{
    Database db = await instance.database;
    return await db.insert(itemTable, item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Item>> getAllItems() async {
    Database db = await instance.database;
    final sql = "SELECT * FROM $itemTable WHERE $columnIsDeleted == 0";
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql);
    // final List<Map<String, dynamic>> maps = await db.query(itemTable);
    return List.generate(maps.length, (i){
      return Item.fromDB(maps[i]);
    });
  }

  Future<int> updateItem(Item item) async {
    Database db = await instance.database;
    return db.update(
      itemTable,
      item.toMap(),
      where: "id = ?",
      whereArgs: [item.id],
    );
  }

  Future<void> deleteItem(int id) async {
    Database db = await instance.database;
    await db.delete(
        itemTable,
        where: "id = ?",
        whereArgs: [id]
    );
  }
}