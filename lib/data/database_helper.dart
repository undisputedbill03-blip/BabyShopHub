import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/app_config.dart';
import '../core/db_utils.dart';
import '../core/pricing.dart';
import '../core/statuses.dart';
import 'password_service.dart';
import 'seed_data.dart';

/// Owns the single SQLite connection and the schema.
///
/// The app keeps everything on the device: there is no server, no API key
/// and no network call anywhere in this project. That is a deliberate
/// decision recorded in the design document, and it is why this class is the
/// only place that knows what the storage looks like.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;
  static bool _ffiInitialised = false;

  /// Opens the database on first use and reuses it afterwards.
  Future<Database> get database async {
    final Database? existing = _database;
    if (existing != null && existing.isOpen) return existing;
    final Database opened = await _open();
    _database = opened;
    return opened;
  }

  Future<Database> _open() async {
    _prepareFactory();
    final String directory = await databaseFactory.getDatabasesPath();
    await Directory(directory).create(recursive: true);
    final String path = p.join(directory, AppConfig.databaseName);
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConfig.databaseVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Android and iOS ship a SQLite engine, so sqflite works unchanged there.
  /// Windows and Linux do not, so the same Dart code is pointed at the FFI
  /// implementation instead. This exists so the project can be demonstrated
  /// on a desktop machine when an Android emulator will not start, which is
  /// by some distance the most fragile part of a first Flutter install.
  static void _prepareFactory() {
    if (_ffiInitialised) return;
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _ffiInitialised = true;
  }

  static Future<void> _onConfigure(Database db) async {
    // Off by default in SQLite. Without this the ON DELETE rules below are
    // recorded but never enforced.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version 1 is the first release, so there is no migration to perform
    // yet. Future versions add their ALTER TABLE statements here rather than
    // dropping and recreating, so a user's orders survive an update.
  }

  // ------------------------------------------------------------ schema

  static Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
    await _seed(db);
  }

  static Future<void> _createTables(Database db) async {
    // Email is stored lower-cased and UNIQUE, so "Parent@..." and
    // "parent@..." cannot become two accounts.
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        role TEXT NOT NULL DEFAULT '${UserRole.customer}',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // A tiny key/value table that holds the id of the signed-in user, so the
    // session survives closing the app. This is why the project needs no
    // shared_preferences dependency.
    await db.execute('''
      CREATE TABLE app_state (
        state_key TEXT PRIMARY KEY,
        state_value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE addresses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        label TEXT NOT NULL DEFAULT 'Home',
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        line1 TEXT NOT NULL,
        line2 TEXT NOT NULL DEFAULT '',
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        postal_code TEXT NOT NULL DEFAULT '',
        is_default INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Only the brand and last four digits are ever written. The number the
    // shopper types is validated for shape, used to derive those two values,
    // and then discarded. No security code is collected at all.
    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        card_holder TEXT NOT NULL,
        card_brand TEXT NOT NULL,
        last4 TEXT NOT NULL,
        expiry_month INTEGER NOT NULL,
        expiry_year INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL DEFAULT '',
        icon_name TEXT NOT NULL DEFAULT 'category',
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // rating_sum and rating_count are recalculated from the ratings table
    // after every write rather than incremented by hand, so they can never
    // drift away from the reviews a shopper can actually read.
    await db.execute('''
      CREATE TABLE sellers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL DEFAULT '',
        rating_sum INTEGER NOT NULL DEFAULT 0,
        rating_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // category_id and seller_id use NO ACTION rather than CASCADE: deleting
    // a category should not silently delete its products. The admin screens
    // check for dependants first and offer to deactivate instead.
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        price REAL NOT NULL DEFAULT 0,
        category_id INTEGER NOT NULL,
        seller_id INTEGER NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        image_path TEXT NOT NULL DEFAULT '',
        age_group TEXT NOT NULL DEFAULT '',
        rating_sum INTEGER NOT NULL DEFAULT 0,
        rating_count INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE NO ACTION,
        FOREIGN KEY (seller_id) REFERENCES sellers (id) ON DELETE NO ACTION
      )
    ''');

    // The UNIQUE pair means adding a product that is already in the cart
    // increases its quantity instead of creating a second row.
    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        added_at TEXT NOT NULL,
        UNIQUE (user_id, product_id),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // The delivery address is copied onto the order rather than referenced.
    // If the shopper later edits or deletes that address, the receipt still
    // says where the parcel actually went.
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_code TEXT NOT NULL UNIQUE,
        user_id INTEGER NOT NULL,
        ship_full_name TEXT NOT NULL,
        ship_phone TEXT NOT NULL,
        ship_line1 TEXT NOT NULL,
        ship_line2 TEXT NOT NULL DEFAULT '',
        ship_city TEXT NOT NULL,
        ship_state TEXT NOT NULL,
        ship_postal_code TEXT NOT NULL DEFAULT '',
        payment_label TEXT NOT NULL,
        subtotal REAL NOT NULL DEFAULT 0,
        shipping_fee REAL NOT NULL DEFAULT 0,
        tax REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT '${OrderStatus.pending}',
        placed_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE NO ACTION
      )
    ''');

    // product_id carries NO foreign key on purpose. The name, brand, image
    // and unit price are all copied here at checkout, so this row is already
    // a complete record of what was bought. Leaving the key off means an
    // admin deleting a discontinued product can never corrupt order history;
    // the id is kept only so "buy it again" can try to find the product.
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        brand TEXT NOT NULL DEFAULT '',
        image_path TEXT NOT NULL DEFAULT '',
        unit_price REAL NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 1,
        line_total REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // One row per stage the parcel reaches. This is the tracking timeline.
    await db.execute('''
      CREATE TABLE order_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // user_name is copied so the review list needs no JOIN and still reads
    // correctly if the account is later removed.
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        rating INTEGER NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        comment TEXT NOT NULL DEFAULT '',
        is_hidden INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        UNIQUE (product_id, user_id),
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE seller_ratings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        seller_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        UNIQUE (seller_id, user_id),
        FOREIGN KEY (seller_id) REFERENCES sellers (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE support_tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        subject TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'General',
        status TEXT NOT NULL DEFAULT '${TicketStatus.open}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE support_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_id INTEGER NOT NULL,
        sender_role TEXT NOT NULL DEFAULT '${SenderRole.customer}',
        sender_name TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (ticket_id) REFERENCES support_tickets (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Indexes on every column the app filters or joins by. With forty
  /// products the difference is not measurable, but the brief asks for a
  /// design that scales, and these are what keep the listing queries from
  /// turning into table scans as the catalogue grows.
  static Future<void> _createIndexes(Database db) async {
    const List<String> statements = <String>[
      'CREATE INDEX idx_products_category ON products (category_id)',
      'CREATE INDEX idx_products_seller ON products (seller_id)',
      'CREATE INDEX idx_products_active ON products (is_active)',
      'CREATE INDEX idx_addresses_user ON addresses (user_id)',
      'CREATE INDEX idx_payment_methods_user ON payment_methods (user_id)',
      'CREATE INDEX idx_cart_user ON cart_items (user_id)',
      'CREATE INDEX idx_orders_user ON orders (user_id)',
      'CREATE INDEX idx_orders_status ON orders (status)',
      'CREATE INDEX idx_order_items_order ON order_items (order_id)',
      'CREATE INDEX idx_order_events_order ON order_events (order_id)',
      'CREATE INDEX idx_reviews_product ON reviews (product_id)',
      'CREATE INDEX idx_reviews_user ON reviews (user_id)',
      'CREATE INDEX idx_seller_ratings_seller ON seller_ratings (seller_id)',
      'CREATE INDEX idx_tickets_user ON support_tickets (user_id)',
      'CREATE INDEX idx_messages_ticket ON support_messages (ticket_id)',
    ];
    for (final String statement in statements) {
      await db.execute(statement);
    }
  }

  // ------------------------------------------------- rating recomputation

  /// Rewrites a product's rating totals from its visible reviews.
  ///
  /// Called after any review is added, edited, deleted or hidden. Working it
  /// out from the rows themselves, rather than adding and subtracting as we
  /// go, means a bug in one code path cannot leave a product showing 4.8
  /// stars from reviews that no longer exist.
  static Future<void> recomputeProductRating(
      DatabaseExecutor db, int productId) async {
    await db.rawUpdate('''
      UPDATE products SET
        rating_sum = (SELECT COALESCE(SUM(rating), 0) FROM reviews r
                      WHERE r.product_id = products.id AND r.is_hidden = 0),
        rating_count = (SELECT COUNT(*) FROM reviews r
                        WHERE r.product_id = products.id AND r.is_hidden = 0)
      WHERE id = ?
    ''', <Object?>[productId]);
  }

  static Future<void> recomputeAllProductRatings(DatabaseExecutor db) async {
    await db.rawUpdate('''
      UPDATE products SET
        rating_sum = (SELECT COALESCE(SUM(rating), 0) FROM reviews r
                      WHERE r.product_id = products.id AND r.is_hidden = 0),
        rating_count = (SELECT COUNT(*) FROM reviews r
                        WHERE r.product_id = products.id AND r.is_hidden = 0)
    ''');
  }

  static Future<void> recomputeSellerRating(
      DatabaseExecutor db, int sellerId) async {
    await db.rawUpdate('''
      UPDATE sellers SET
        rating_sum = (SELECT COALESCE(SUM(rating), 0) FROM seller_ratings sr
                      WHERE sr.seller_id = sellers.id),
        rating_count = (SELECT COUNT(*) FROM seller_ratings sr
                        WHERE sr.seller_id = sellers.id)
      WHERE id = ?
    ''', <Object?>[sellerId]);
  }

  static Future<void> recomputeAllSellerRatings(DatabaseExecutor db) async {
    await db.rawUpdate('''
      UPDATE sellers SET
        rating_sum = (SELECT COALESCE(SUM(rating), 0) FROM seller_ratings sr
                      WHERE sr.seller_id = sellers.id),
        rating_count = (SELECT COUNT(*) FROM seller_ratings sr
                        WHERE sr.seller_id = sellers.id)
    ''');
  }

  // -------------------------------------------------------------- seeding

  /// Writes the demo dataset.
  ///
  /// This runs once, inside the transaction sqflite already holds open for
  /// onCreate, which is why it uses the connection directly instead of
  /// starting a transaction of its own.
  static Future<void> _seed(Database db) async {
    final String now = nowIso();
    final Map<int, String> userNames = <int, String>{};

    // --- users --------------------------------------------------------
    for (final Map<String, Object?> user in SeedData.users) {
      final int id = asInt(user['id']);
      final String name = asString(user['name']);
      final String salt = PasswordService.generateSalt();
      userNames[id] = name;
      await db.insert('users', <String, Object?>{
        'id': id,
        'name': name,
        'email': asString(user['email']).toLowerCase(),
        'password_hash':
            PasswordService.hash(asString(user['password']), salt),
        'password_salt': salt,
        'phone': asString(user['phone']),
        'role': asString(user['role'], UserRole.customer),
        'is_active': 1,
        'created_at': now,
      });
    }

    // --- catalogue ----------------------------------------------------
    final Batch batch = db.batch();

    for (final Map<String, Object?> category in SeedData.categories) {
      batch.insert('categories', <String, Object?>{
        'id': asInt(category['id']),
        'name': asString(category['name']),
        'description': asString(category['description']),
        'icon_name': asString(category['icon_name'], 'category'),
        'sort_order': asInt(category['sort_order']),
      });
    }

    for (final Map<String, Object?> seller in SeedData.sellers) {
      batch.insert('sellers', <String, Object?>{
        'id': asInt(seller['id']),
        'name': asString(seller['name']),
        'description': asString(seller['description']),
        'rating_sum': 0,
        'rating_count': 0,
      });
    }

    for (final Map<String, Object?> product in SeedData.products) {
      batch.insert('products', <String, Object?>{
        'id': asInt(product['id']),
        'name': asString(product['name']),
        'brand': asString(product['brand']),
        'description': asString(product['description']),
        'price': asDouble(product['price']),
        'category_id': asInt(product['category_id']),
        'seller_id': asInt(product['seller_id']),
        'stock': asInt(product['stock']),
        'image_path': imagePathFor(asString(product['image'])),
        'age_group': asString(product['age_group']),
        'rating_sum': 0,
        'rating_count': 0,
        'is_active': 1,
        'created_at': now,
      });
    }

    // --- addresses and cards -------------------------------------------
    for (final Map<String, Object?> address in SeedData.addresses) {
      batch.insert('addresses', <String, Object?>{
        'user_id': asInt(address['user_id']),
        'label': asString(address['label'], 'Home'),
        'full_name': asString(address['full_name']),
        'phone': asString(address['phone']),
        'line1': asString(address['line1']),
        'line2': asString(address['line2']),
        'city': asString(address['city']),
        'state': asString(address['state']),
        'postal_code': asString(address['postal_code']),
        'is_default': asInt(address['is_default']),
      });
    }

    for (final Map<String, Object?> card in SeedData.paymentMethods()) {
      batch.insert('payment_methods', <String, Object?>{
        'user_id': asInt(card['user_id']),
        'card_holder': asString(card['card_holder']),
        'card_brand': asString(card['card_brand']),
        'last4': asString(card['last4']),
        'expiry_month': asInt(card['expiry_month']),
        'expiry_year': asInt(card['expiry_year']),
        'is_default': asInt(card['is_default']),
      });
    }

    // --- reviews and seller ratings ------------------------------------
    for (final Map<String, Object?> review in SeedData.reviews()) {
      final int userId = asInt(review['user_id']);
      batch.insert('reviews', <String, Object?>{
        'product_id': asInt(review['product_id']),
        'user_id': userId,
        'user_name': userNames[userId] ?? 'Customer',
        'rating': asInt(review['rating']),
        'title': asString(review['title']),
        'comment': asString(review['comment']),
        'is_hidden': asInt(review['is_hidden']),
        'created_at': asString(review['created_at'], now),
      });
    }

    for (final Map<String, Object?> rating in SeedData.sellerRatings()) {
      final int userId = asInt(rating['user_id']);
      batch.insert('seller_ratings', <String, Object?>{
        'seller_id': asInt(rating['seller_id']),
        'user_id': userId,
        'user_name': userNames[userId] ?? 'Customer',
        'rating': asInt(rating['rating']),
        'comment': asString(rating['comment']),
        'created_at': asString(rating['created_at'], now),
      });
    }

    // --- support -------------------------------------------------------
    for (final Map<String, Object?> ticket in SeedData.supportTickets()) {
      batch.insert('support_tickets', <String, Object?>{
        'id': asInt(ticket['id']),
        'user_id': asInt(ticket['user_id']),
        'user_name': asString(ticket['user_name']),
        'subject': asString(ticket['subject']),
        'category': asString(ticket['category'], 'General'),
        'status': asString(ticket['status'], TicketStatus.open),
        'created_at': asString(ticket['created_at'], now),
        'updated_at': asString(ticket['updated_at'], now),
      });
    }

    for (final Map<String, Object?> message in SeedData.supportMessages()) {
      batch.insert('support_messages', <String, Object?>{
        'ticket_id': asInt(message['ticket_id']),
        'sender_role': asString(message['sender_role'], SenderRole.customer),
        'sender_name': asString(message['sender_name']),
        'message': asString(message['message']),
        'created_at': asString(message['created_at'], now),
      });
    }

    await batch.commit(noResult: true);

    // --- orders --------------------------------------------------------
    await _seedOrders(db);

    // Derive the rating totals from the rows just written, using the same
    // statements the app runs in normal use.
    await recomputeAllProductRatings(db);
    await recomputeAllSellerRatings(db);
  }

  /// Builds the demo orders, pricing them through [Pricing].
  ///
  /// Nothing about the money is hard-coded: the totals come out of exactly
  /// the same code the checkout screen uses, so a seeded receipt and one the
  /// examiner creates during the demonstration add up the same way.
  static Future<void> _seedOrders(Database db) async {
    // An id-keyed view of the catalogue, so each order line can copy the
    // name, brand, image and price it was bought at.
    final Map<int, Map<String, Object?>> catalogue =
        <int, Map<String, Object?>>{
      for (final Map<String, Object?> product in SeedData.products)
        asInt(product['id']): product,
    };

    final List<SeedOrder> orders = SeedData.orders();
    for (int index = 0; index < orders.length; index++) {
      final SeedOrder order = orders[index];
      final int orderId = index + 1;

      final List<Map<String, Object?>> lines = <Map<String, Object?>>[];
      for (final SeedOrderItem item in order.items) {
        final Map<String, Object?>? product = catalogue[item.productId];
        if (product == null) continue;
        final double unitPrice = asDouble(product['price']);
        lines.add(<String, Object?>{
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': asString(product['name']),
          'brand': asString(product['brand']),
          'image_path': imagePathFor(asString(product['image'])),
          'unit_price': unitPrice,
          'quantity': item.quantity,
          'line_total': Pricing.roundMoney(unitPrice * item.quantity),
        });
      }
      if (lines.isEmpty) continue;

      final double subtotal = Pricing.subtotalOf(
        lines.map((Map<String, Object?> line) => asDouble(line['line_total'])),
      );

      // The tracking timeline: every stage up to and including the order's
      // current status, dated from the offsets in the seed file.
      final List<Map<String, Object?>> events = <Map<String, Object?>>[];
      final int stageIndex = OrderStatus.flow.indexOf(order.status);
      final int stageCount = stageIndex < 0 ? 1 : stageIndex + 1;
      String lastEventAt = order.placedAt;
      for (int stage = 0; stage < stageCount; stage++) {
        final String status = OrderStatus.flow[stage];
        final String createdAt = stage < order.eventOffsetsDays.length
            ? DateTime.now()
                .subtract(Duration(days: order.eventOffsetsDays[stage]))
                .toIso8601String()
            : order.placedAt;
        lastEventAt = createdAt;
        events.add(<String, Object?>{
          'order_id': orderId,
          'status': status,
          'note': OrderStatus.note(status),
          'created_at': createdAt,
        });
      }

      final Batch batch = db.batch();
      batch.insert('orders', <String, Object?>{
        'id': orderId,
        'order_code': order.orderCode,
        'user_id': order.userId,
        'ship_full_name': order.shipFullName,
        'ship_phone': order.shipPhone,
        'ship_line1': order.shipLine1,
        'ship_line2': order.shipLine2,
        'ship_city': order.shipCity,
        'ship_state': order.shipState,
        'ship_postal_code': order.shipPostalCode,
        'payment_label': order.paymentLabel,
        'subtotal': subtotal,
        'shipping_fee': Pricing.shippingFor(subtotal),
        'tax': Pricing.taxFor(subtotal),
        'total': Pricing.totalFor(subtotal),
        'status': order.status,
        'placed_at': order.placedAt,
        'updated_at': lastEventAt,
      });
      for (final Map<String, Object?> line in lines) {
        batch.insert('order_items', line);
      }
      for (final Map<String, Object?> event in events) {
        batch.insert('order_events', event);
      }
      await batch.commit(noResult: true);
    }
  }

  /// Turns a seed file stem into the asset path the app loads.
  static String imagePathFor(String stem) {
    if (stem.isEmpty) return '';
    return 'assets/images/products/$stem.png';
  }

  // ----------------------------------------------------------- app_state

  /// Reads a saved value, or null if it was never written.
  Future<String?> readState(String key) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'app_state',
      where: 'state_key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return asString(rows.first['state_value']);
  }

  Future<void> writeState(String key, String value) async {
    final Database db = await database;
    await db.insert(
      'app_state',
      <String, Object?>{'state_key': key, 'state_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearState(String key) async {
    final Database db = await database;
    await db.delete('app_state',
        where: 'state_key = ?', whereArgs: <Object?>[key]);
  }

  // ------------------------------------------------------------ lifecycle

  Future<void> close() async {
    final Database? db = _database;
    _database = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }

  /// Deletes the database file and rebuilds it from the seed data.
  ///
  /// Exposed on the admin screen so the app can be returned to a known state
  /// between demonstrations without uninstalling it.
  Future<void> resetDatabase() async {
    _prepareFactory();
    await close();
    final String directory = await databaseFactory.getDatabasesPath();
    final String path = p.join(directory, AppConfig.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = await _open();
  }
}
