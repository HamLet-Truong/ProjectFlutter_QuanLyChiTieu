import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        email $textType,
        preferredCurrency $textType,
        createdAt $textType
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        amount $realType,
        date $textType,
        note $textType,
        type $textType,
        categoryId $textType,
        userId $textType
      )
    ''');
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        iconPath $textType,
        colorHex $textType,
        type $textType
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets (
        id $idType,
        categoryId $textType,
        limitAmount $realType,
        startDate $textType,
        endDate $textType
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        id $idType,
        themeMode $textType,
        currencyCode $textType,
        isBiometricEnabled $integerType
      )
    ''');
    // DEEP SEED DATA
    await db.execute('''INSERT INTO categories (id, name, iconPath, colorHex, type) VALUES 
      ('1', 'Ăn uống', 'fastfood', '#FF7043', 'expense'),
      ('2', 'Di chuyển', 'directions_car', '#42A5F5', 'expense'),
      ('3', 'Lương', 'attach_money', '#4CAF50', 'income'),
      ('4', 'Sức khỏe', 'health_and_safety', '#EC407A', 'expense'),
      ('5', 'Giải trí', 'movie', '#AB47BC', 'expense'),
      ('6', 'Đầu tư', 'trending_up', '#5C6BC0', 'income'),
      ('7', 'Mua sắm', 'shopping_bag', '#FFB74D', 'expense'),
      ('8', 'Hóa đơn', 'receipt_long', '#78909C', 'expense')
    ''');
    // Sample transactions
    await db.execute('''INSERT INTO transactions (id, amount, date, note, type, categoryId, userId) VALUES 
      ('t1', 25000000.0, '${DateTime.now().toIso8601String()}', 'Lương tháng', 'income', '3', '1'),
      ('t2', 55000.0, '${DateTime.now().toIso8601String()}', 'Bữa trưa', 'expense', '1', '1'),
      ('t3', 120000.0, '${DateTime.now().toIso8601String()}', 'Đổ xăng', 'expense', '2', '1')
    ''');
    // Sample settings
    await db.execute('''INSERT INTO settings (id, themeMode, currencyCode, isBiometricEnabled) VALUES 
      ('1', 'system', 'VND', 0)
    ''');
  }

  Future<void> resetDB() async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'expense_manager.db');
    await deleteDatabase(path);
    _database = null;
  }
}
