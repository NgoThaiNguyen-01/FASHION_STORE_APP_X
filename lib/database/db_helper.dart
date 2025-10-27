import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;

  // =============================
  // 1️⃣ KHỞI TẠO DATABASE
  // =============================
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('fashion_store_db_v5.sqlite');
    return _db!;
  }

  static Future<Database> _initDB(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, fileName);

    return openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        // Bật foreign keys để ON DELETE CASCADE hoạt động
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  // =============================
  // 2️⃣ TẠO BẢNG BAN ĐẦU
  // =============================
  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        role TEXT DEFAULT 'khach_hang',
        phone TEXT,
        address TEXT,
        avatar TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        image TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        categoryId INTEGER,
        price REAL NOT NULL,
        oldPrice REAL,
        description TEXT,
        images TEXT,
        discount INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        quantity INTEGER DEFAULT 0,
        status INTEGER DEFAULT 1,
        sizes TEXT,
        colors TEXT,
        material TEXT,
        weight REAL,
        tags TEXT,
        viewCount INTEGER DEFAULT 0,
        soldCount INTEGER DEFAULT 0,
        rating REAL DEFAULT 0,
        reviewCount INTEGER DEFAULT 0,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        orderCode TEXT UNIQUE,
        totalAmount REAL NOT NULL,
        discountAmount REAL DEFAULT 0,
        finalAmount REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        paymentMethod TEXT,
        shippingAddress TEXT,
        customerName TEXT,
        customerPhone TEXT,
        note TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER,
        productId INTEGER,
        productName TEXT NOT NULL,
        productPrice REAL NOT NULL,
        quantity INTEGER NOT NULL,
        size TEXT,
        color TEXT,
        discount INTEGER DEFAULT 0,
        totalPrice REAL NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        productId INTEGER,
        quantity INTEGER DEFAULT 1,
        size TEXT,
        color TEXT,
        addedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        productId INTEGER,
        addedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (productId) REFERENCES products(id),
        UNIQUE(userId, productId)
      )
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        productId INTEGER,
        rating INTEGER NOT NULL,
        comment TEXT,
        images TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        totalRevenue REAL DEFAULT 0,
        totalOrders INTEGER DEFAULT 0,
        totalProductsSold INTEGER DEFAULT 0,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await _createSampleData(db);
  }

  // =============================
  // 3️⃣ NÂNG CẤP DATABASE
  // =============================
  static Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          orderCode TEXT UNIQUE,
          totalAmount REAL NOT NULL,
          discountAmount REAL DEFAULT 0,
          finalAmount REAL NOT NULL,
          status TEXT DEFAULT 'pending',
          paymentMethod TEXT,
          shippingAddress TEXT,
          customerName TEXT,
          customerPhone TEXT,
          note TEXT,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
          updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (userId) REFERENCES users(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          orderId INTEGER,
          productId INTEGER,
          productName TEXT NOT NULL,
          productPrice REAL NOT NULL,
          quantity INTEGER NOT NULL,
          size TEXT,
          color TEXT,
          discount INTEGER DEFAULT 0,
          totalPrice REAL NOT NULL,
          FOREIGN KEY (orderId) REFERENCES orders(id) ON DELETE CASCADE,
          FOREIGN KEY (productId) REFERENCES products(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS cart_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          productId INTEGER,
          quantity INTEGER DEFAULT 1,
          size TEXT,
          color TEXT,
          addedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (userId) REFERENCES users(id),
          FOREIGN KEY (productId) REFERENCES products(id)
        )
      ''');
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN quantity INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE products ADD COLUMN status INTEGER DEFAULT 1');
        await db.execute('ALTER TABLE products ADD COLUMN sizes TEXT');
        await db.execute('ALTER TABLE products ADD COLUMN colors TEXT');
        await db.execute('ALTER TABLE products ADD COLUMN material TEXT');
        await db.execute('ALTER TABLE products ADD COLUMN weight REAL');
        await db.execute('ALTER TABLE products ADD COLUMN tags TEXT');
        await db.execute('ALTER TABLE products ADD COLUMN viewCount INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE products ADD COLUMN soldCount INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE products ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP');

        await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN address TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN avatar TEXT');

        await db.execute('ALTER TABLE categories ADD COLUMN image TEXT');
        await db.execute('ALTER TABLE categories ADD COLUMN isActive INTEGER DEFAULT 1');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            productId INTEGER,
            addedAt TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (userId) REFERENCES users(id),
            FOREIGN KEY (productId) REFERENCES products(id),
            UNIQUE(userId, productId)
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            productId INTEGER,
            rating INTEGER NOT NULL,
            comment TEXT,
            images TEXT,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (userId) REFERENCES users(id),
            FOREIGN KEY (productId) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS statistics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            totalRevenue REAL DEFAULT 0,
            totalOrders INTEGER DEFAULT 0,
            totalProductsSold INTEGER DEFAULT 0,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN rating REAL DEFAULT 0');
        await db.execute('ALTER TABLE products ADD COLUMN reviewCount INTEGER DEFAULT 0');
      } catch (_) {}
    }

    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE categories ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP');
      } catch (_) {}
    }
  }

  // =============================
  // 4️⃣ TẠO DỮ LIỆU MẪU
  // =============================
  static Future<void> _createSampleData(Database db) async {
    final adminHash = BCrypt.hashpw('Admin@123', BCrypt.gensalt());
    await db.insert('users', {
      'fullName': 'Quản trị viên',
      'email': 'admin@shop.com',
      'passwordHash': adminHash,
      'role': 'admin',
      'phone': '0123456789',
      'address': 'Hà Nội, Việt Nam',
    });

    final userHash = BCrypt.hashpw('User@123', BCrypt.gensalt());
    await db.insert('users', {
      'fullName': 'Nguyễn Văn A',
      'email': 'user@example.com',
      'passwordHash': userHash,
      'role': 'khach_hang',
      'phone': '0987654321',
      'address': 'TP.HCM, Việt Nam',
    });

    await db.insert('categories', {
      'name': 'Áo Thun',
      'description': 'Các loại áo thun nam nữ thời trang',
      'image': 'assets/images/category_tshirt.jpg'
    });
    await db.insert('categories', {
      'name': 'Quần Jean',
      'description': 'Quần jean nam nữ đa dạng',
      'image': 'assets/images/category_jean.jpg'
    });
    await db.insert('categories', {
      'name': 'Váy Đầm',
      'description': 'Váy đầm nữ thời trang',
      'image': 'assets/images/category_dress.jpg'
    });
    await db.insert('categories', {
      'name': 'Áo Sơ Mi',
      'description': 'Áo sơ mi công sở và dạo phố',
      'image': 'assets/images/category_shirt.jpg'
    });

    final sampleProducts = [
      {
        'name': 'Áo Thun Nam Cotton Premium',
        'categoryId': 1,
        'price': 250000,
        'oldPrice': 350000,
        'description':
        'Áo thun nam chất liệu cotton cao cấp, thoáng mát, thấm hút mồ hôi tốt. Phù hợp cho mọi hoạt động hàng ngày.',
        'images': jsonEncode(['assets/images/product_1_1.jpg', 'assets/images/product_1_2.jpg']),
        'discount': 30,
        'quantity': 50,
        'status': 1,
        'sizes': jsonEncode(['S', 'M', 'L', 'XL']),
        'colors': jsonEncode(['Đen', 'Trắng', 'Xám']),
        'material': 'Cotton 100%',
        'weight': 0.2,
        'tags': jsonEncode(['ao-thun', 'nam', 'cotton', 'basic']),
        'soldCount': 150,
        'rating': 4.5,
        'reviewCount': 25,
      },
      {
        'name': 'Quần Jean Nam Slim Fit',
        'categoryId': 2,
        'price': 450000,
        'oldPrice': 550000,
        'description':
        'Quần jean nam dáng slim fit, chất liệu denim co giãn, thoải mái vận động. Màu xanh đậm thời trang.',
        'images': jsonEncode(['assets/images/product_2_1.jpg', 'assets/images/product_2_2.jpg']),
        'discount': 20,
        'quantity': 30,
        'status': 1,
        'sizes': jsonEncode(['28', '29', '30', '31', '32']),
        'colors': jsonEncode(['Xanh đậm', 'Xanh nhạt', 'Đen']),
        'material': 'Denim co giãn',
        'weight': 0.5,
        'tags': jsonEncode(['quan-jean', 'nam', 'slim-fit', 'denim']),
        'soldCount': 89,
        'rating': 4.2,
        'reviewCount': 18,
      },
      {
        'name': 'Váy Đầm Nữ Body Suit',
        'categoryId': 3,
        'price': 380000,
        'oldPrice': 480000,
        'description':
        'Váy đầm nữ dáng body suit ôm tôn dáng, chất liệu vải mềm mại, phù hợp đi làm và dạo phố.',
        'images': jsonEncode(['assets/images/product_3_1.jpg', 'assets/images/product_3_2.jpg']),
        'discount': 25,
        'quantity': 25,
        'status': 1,
        'sizes': jsonEncode(['S', 'M', 'L']),
        'colors': jsonEncode(['Đỏ', 'Đen', 'Trắng']),
        'material': 'Polyester + Spandex',
        'weight': 0.3,
        'tags': jsonEncode(['vay-dam', 'nu', 'body-suit', 'cong-so']),
        'soldCount': 67,
        'rating': 4.8,
        'reviewCount': 32,
      },
      {
        'name': 'Áo Sơ Mi Nam Trắng',
        'categoryId': 4,
        'price': 320000,
        'oldPrice': 0,
        'description':
        'Áo sơ mi nam trắng form regular, chất liệu cotton pha, cổ bẻ, tay dài. Phù hợp mặc công sở.',
        'images': jsonEncode(['assets/images/product_4_1.jpg', 'assets/images/product_4_2.jpg']),
        'discount': 0,
        'quantity': 0,
        'status': 0,
        'sizes': jsonEncode(['M', 'L', 'XL', 'XXL']),
        'colors': jsonEncode(['Trắng']),
        'material': 'Cotton pha',
        'weight': 0.25,
        'tags': jsonEncode(['ao-so-mi', 'nam', 'cong-so', 'trang']),
        'soldCount': 120,
        'rating': 4.3,
        'reviewCount': 28,
      },
      {
        'name': 'Áo Thun Nữ Croptop',
        'categoryId': 1,
        'price': 180000,
        'oldPrice': 220000,
        'description':
        'Áo thun nữ dáng croptop trẻ trung, chất liệu cotton mềm mại, nhiều màu sắc thời trang.',
        'images': jsonEncode(['assets/images/product_5_1.jpg', 'assets/images/product_5_2.jpg']),
        'discount': 15,
        'quantity': 15,
        'status': 2,
        'sizes': jsonEncode(['S', 'M']),
        'colors': jsonEncode(['Hồng', 'Xanh lá', 'Vàng']),
        'material': 'Cotton mềm',
        'weight': 0.15,
        'tags': jsonEncode(['ao-thun', 'nu', 'croptop', 'tre-trung']),
        'soldCount': 45,
        'rating': 4.6,
        'reviewCount': 15,
      },
    ];

    for (final product in sampleProducts) {
      await db.insert('products', product);
    }

    await db.insert('orders', {
      'userId': 2,
      'orderCode': 'DH001',
      'totalAmount': 630000,
      'discountAmount': 126000,
      'finalAmount': 504000,
      'status': 'completed',
      'paymentMethod': 'cod',
      'shippingAddress': '123 Nguyễn Văn Linh, Quận 7, TP.HCM',
      'customerName': 'Nguyễn Văn A',
      'customerPhone': '0987654321',
    });

    await db.insert('order_items', {
      'orderId': 1,
      'productId': 1,
      'productName': 'Áo Thun Nam Cotton Premium',
      'productPrice': 250000,
      'quantity': 2,
      'size': 'M',
      'color': 'Đen',
      'discount': 30,
      'totalPrice': 350000,
    });

    await db.insert('order_items', {
      'orderId': 1,
      'productId': 2,
      'productName': 'Quần Jean Nam Slim Fit',
      'productPrice': 450000,
      'quantity': 1,
      'size': '30',
      'color': 'Xanh đậm',
      'discount': 20,
      'totalPrice': 360000,
    });

    await db.insert('reviews', {
      'userId': 2,
      'productId': 1,
      'rating': 5,
      'comment':
      'Áo rất đẹp, chất liệu tốt, mặc thoải mái. Sẽ ủng hộ shop dài dài!',
      'images': jsonEncode([]),
    });

    await db.insert('reviews', {
      'userId': 2,
      'productId': 2,
      'rating': 4,
      'comment':
      'Quần vừa vặn, chất liệu tốt. Nhưng màu hơi khác so với hình ảnh.',
      'images': jsonEncode([]),
    });

    await db.insert('reviews', {
      'userId': 2,
      'productId': 3,
      'rating': 5,
      'comment':
      'Váy rất đẹp, form dáng chuẩn. Chất vải mát, mặc đi làm rất phù hợp.',
      'images': jsonEncode([]),
    });
  }

  // =============================
  // 5️⃣ CRUD DANH MỤC
  // =============================
  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return db.query('categories', orderBy: 'name ASC');
  }

  static Future<List<Map<String, dynamic>>> getActiveCategories() async {
    final db = await database;
    return db.query(
      'categories',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
  }

  static Future<void> addCategory(String name, String? desc, {String? image}) async {
    final db = await database;
    await db.insert(
      'categories',
      {'name': name.trim(), 'description': desc ?? '', 'image': image},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateCategory(int id, String name, String? desc,
      {String? image}) async {
    final db = await database;
    await db.update(
      'categories',
      {
        'name': name.trim(),
        'description': desc ?? '',
        'image': image,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> toggleCategoryStatus(int id, bool isActive) async {
    final db = await database;
    await db.update(
      'categories',
      {
        'isActive': isActive ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =============================
  // 6️⃣ CRUD SẢN PHẨM
  // =============================
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return db.query('products', orderBy: 'id DESC');
  }

  static Future<List<Map<String, dynamic>>> getProductsByCategory(int categoryId) async {
    final db = await database;
    return db.query(
      'products',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'id DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getProductsWithStatus(int status) async {
    final db = await database;
    return db.query(
      'products',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'id DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getProductsOnSale() async {
    final db = await database;
    return db.query(
      'products',
      where: 'discount > ? AND quantity > ? AND status = ?',
      whereArgs: [0, 0, 1],
      orderBy: 'discount DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return db.query(
      'products',
      where: 'name LIKE ? OR description LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'id DESC',
    );
  }

  static Future<Map<String, dynamic>?> getProductById(int id) async {
    final db = await database;
    final res = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  static Future<void> addProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert(
      'products',
      {
        ...product,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateProduct(int id, Map<String, dynamic> product) async {
    final db = await database;
    await db.update(
      'products',
      {
        ...product,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateProductQuantity(int id, int quantity) async {
    final db = await database;
    await db.update(
      'products',
      {
        'quantity': quantity,
        'status': quantity > 0 ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateProductStatus(int id, int status) async {
    final db = await database;
    await db.update(
      'products',
      {'status': status, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateSaleDiscount(int id, int discount) async {
    final db = await database;
    await db.update(
      'products',
      {'discount': discount, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> incrementProductView(int id) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE products 
      SET viewCount = viewCount + 1, updatedAt = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), id]);
  }

  static Future<void> updateSoldCount(int id, int soldQuantity) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE products 
      SET soldCount = soldCount + ?, quantity = quantity - ?, updatedAt = ?
      WHERE id = ?
    ''', [soldQuantity, soldQuantity, DateTime.now().toIso8601String(), id]);
  }

  // =============================
  // 7️⃣ QUẢN LÝ KHO HÀNG
  // =============================
  static Future<List<Map<String, dynamic>>> getLowStockProducts({int threshold = 10}) async {
    final db = await database;
    return db.query(
      'products',
      where: 'quantity <= ? AND status = ?',
      whereArgs: [threshold, 1],
      orderBy: 'quantity ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    final db = await database;
    return db.query(
      'products',
      where: 'quantity = ? OR status = ?',
      whereArgs: [0, 0],
      orderBy: 'name ASC',
    );
  }

  static Future<void> importStock(int productId, int quantity) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE products 
      SET quantity = quantity + ?, status = ?, updatedAt = ?
      WHERE id = ?
    ''', [quantity, quantity > 0 ? 1 : 0, DateTime.now().toIso8601String(), productId]);
  }

  // =============================
  // 8️⃣ QUẢN LÝ NGƯỜI DÙNG
  // =============================
  static Future<String?> registerUser({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? address,
  }) async {
    final db = await database;
    email = email.trim().toLowerCase();

    if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Email không hợp lệ';
    }
    if (password.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';

    final exists = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (exists.isNotEmpty) return 'Email đã được sử dụng';

    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    await db.insert('users', {
      'fullName': fullName.trim(),
      'email': email,
      'passwordHash': hash,
      'role': 'khach_hang',
      'phone': phone,
      'address': address,
    });
    return null;
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final db = await database;
    email = email.trim().toLowerCase();
    final users = await db.query('users', where: 'email = ?', whereArgs: [email]);

    if (users.isEmpty) return {'error': 'Tài khoản không tồn tại'};

    final user = users.first;
    final hash = user['passwordHash'] as String;

    if (!BCrypt.checkpw(password, hash)) return {'error': 'Sai mật khẩu'};

    return {
      'id': user['id'],
      'fullName': user['fullName'],
      'email': user['email'],
      'role': user['role'],
      'phone': user['phone'],
      'address': user['address'],
    };
  }

  static Future<bool> updateUserProfile(int userId, Map<String, dynamic> profile) async {
    final db = await database;
    final res = await db.update(
      'users',
      {...profile, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return res > 0;
  }

  static Future<bool> updatePassword(String email, String newPassword) async {
    final db = await database;
    final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    final res = await db.update(
      'users',
      {'passwordHash': newHash, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'email = ?',
      whereArgs: [email],
    );
    return res > 0;
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return db.query('users', orderBy: 'createdAt DESC');
  }

  static Future<void> updateUserRole(int userId, String role) async {
    final db = await database;
    await db.update(
      'users',
      {'role': role, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // =============================
  // 9️⃣ QUẢN LÝ ĐƠN HÀNG
  // =============================
  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await database;
    return db.query('orders', orderBy: 'createdAt DESC');
  }

  static Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    final db = await database;
    return db.query(
      'orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await database;
    return db.query('order_items', where: 'orderId = ?', whereArgs: [orderId]);
  }

  static Future<void> updateOrderStatus(int orderId, String status) async {
    final db = await database;
    await db.update(
      'orders',
      {'status': status, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // =============================
  // 🔟 THỐNG KÊ & BÁO CÁO
  // =============================
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;

    final totalProducts = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    final totalUsers = await db.rawQuery(
        'SELECT COUNT(*) as count FROM users WHERE role = ?', ['khach_hang']);
    final totalOrders = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
    final totalRevenue = await db.rawQuery(
        'SELECT SUM(finalAmount) as total FROM orders WHERE status = ?', ['completed']);
    final lowStockCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE quantity <= ? AND status = ?',
        [10, 1]);

    int _asInt(Map<String, Object?> row, String k) =>
        (row[k] as num?)?.toInt() ?? 0;
    double _asDouble(Map<String, Object?> row, String k) =>
        (row[k] as num?)?.toDouble() ?? 0.0;

    return {
      'totalProducts': _asInt(totalProducts.first, 'count'),
      'totalUsers': _asInt(totalUsers.first, 'count'),
      'totalOrders': _asInt(totalOrders.first, 'count'),
      'totalRevenue': _asDouble(totalRevenue.first, 'total'),
      'lowStockCount': _asInt(lowStockCount.first, 'count'),
    };
  }

  static Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 5}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT * FROM products 
      ORDER BY soldCount DESC, viewCount DESC 
      LIMIT ?
    ''', [limit]);
  }

  static Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 10}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT * FROM orders 
      ORDER BY createdAt DESC 
      LIMIT ?
    ''', [limit]);
  }

  // =============================
  // 11️⃣ QUẢN LÝ ĐÁNH GIÁ
  // =============================
  static Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT r.*, u.fullName as userName 
      FROM reviews r 
      LEFT JOIN users u ON r.userId = u.id 
      WHERE r.productId = ? 
      ORDER BY r.createdAt DESC
    ''', [productId]);
  }

  static Future<void> addReview({
    required int userId,
    required int productId,
    required int rating,
    String? comment,
    String? images,
  }) async {
    final db = await database;
    await db.insert('reviews', {
      'userId': userId,
      'productId': productId,
      'rating': rating,
      'comment': comment,
      'images': images,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _updateProductRating(productId);
  }

  static Future<void> _updateProductRating(int productId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT AVG(rating) as avgRating, COUNT(*) as reviewCount 
      FROM reviews 
      WHERE productId = ?
    ''', [productId]);

    if (result.isNotEmpty) {
      final avg = (result.first['avgRating'] as num?)?.toDouble() ?? 0.0;
      final cnt = (result.first['reviewCount'] as num?)?.toInt() ?? 0;

      await db.update(
        'products',
        {
          'rating': avg,
          'reviewCount': cnt,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );
    }
  }

  // =============================
  // 12️⃣ QUẢN LÝ YÊU THÍCH
  // =============================
  static Future<List<Map<String, dynamic>>> getUserFavorites(int userId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT p.* 
      FROM favorites f 
      JOIN products p ON f.productId = p.id 
      WHERE f.userId = ? 
      ORDER BY f.addedAt DESC
    ''', [userId]);
  }

  static Future<bool> isProductInFavorites(int userId, int productId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
    return result.isNotEmpty;
  }

  static Future<void> toggleFavorite(int userId, int productId) async {
    final db = await database;
    if (await isProductInFavorites(userId, productId)) {
      await db.delete('favorites',
          where: 'userId = ? AND productId = ?', whereArgs: [userId, productId]);
    } else {
      await db.insert('favorites', {
        'userId': userId,
        'productId': productId,
        'addedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // =============================
  // 13️⃣ QUẢN LÝ GIỎ HÀNG
  // =============================
  static Future<List<Map<String, dynamic>>> getCartItems(int userId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT c.*, p.name, p.price, p.images, p.discount, p.status, p.quantity as stock
      FROM cart_items c 
      JOIN products p ON c.productId = p.id 
      WHERE c.userId = ? 
      ORDER BY c.addedAt DESC
    ''', [userId]);
  }

  static Future<void> addToCart({
    required int userId,
    required int productId,
    required int quantity,
    String? size,
    String? color,
  }) async {
    final db = await database;

    // Chuẩn hoá để tránh so sánh NULL (= NULL luôn sai trong SQLite)
    final sz = size ?? '';
    final cl = color ?? '';

    final existing = await db.query(
      'cart_items',
      where: 'userId = ? AND productId = ? AND IFNULL(size, "") = ? AND IFNULL(color, "") = ?',
      whereArgs: [userId, productId, sz, cl],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'cart_items',
        {
          'quantity': ((existing.first['quantity'] as num?)?.toInt() ?? 0) + quantity,
          'addedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('cart_items', {
        'userId': userId,
        'productId': productId,
        'quantity': quantity,
        'size': sz,
        'color': cl,
        'addedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<void> updateCartItemQuantity(int cartItemId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
    } else {
      await db.update(
        'cart_items',
        {'quantity': quantity, 'addedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [cartItemId],
      );
    }
  }

  static Future<void> removeFromCart(int cartItemId) async {
    final db = await database;
    await db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
  }

  static Future<void> clearCart(int userId) async {
    final db = await database;
    await db.delete('cart_items', where: 'userId = ?', whereArgs: [userId]);
  }

  // =============================
  // 14️⃣ TIỆN ÍCH
  // =============================
  static Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cart_items');
      await txn.delete('order_items');
      await txn.delete('orders');
      await txn.delete('favorites');
      await txn.delete('reviews');
      await txn.delete('products');
      await txn.delete('categories');
      await txn.delete('users');
    });
    await _createSampleData(db);
  }

  static Future<String> backupDatabase() async {
    await database; // đảm bảo đã mở
    final dir = await getApplicationDocumentsDirectory();
    final originalPath = join(dir.path, 'fashion_store_db_v5.sqlite');
    final backupPath = join(dir.path, 'backup_${DateTime.now().millisecondsSinceEpoch}.sqlite');
    await File(originalPath).copy(backupPath);
    return backupPath;
  }

  // =============================
  // 15️⃣ KIỂM TRA KẾT NỐI
  // =============================
  static Future<bool> testConnection() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Database connection error: $e');
      return false;
    }
  }

  // =============================
  // 16️⃣ RESET PASSWORD
  // =============================
  static Future<bool> checkEmailExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
