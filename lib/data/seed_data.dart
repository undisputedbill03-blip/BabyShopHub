import '../core/statuses.dart';

/// The demo dataset written into the database the first time the app runs.
///
/// Ids are written explicitly rather than left to AUTOINCREMENT so the
/// relationships below (a product's category, a review's product, an order's
/// items) are fixed and readable instead of depending on insert order.
///
/// Timestamps are computed relative to the moment of seeding, so a freshly
/// installed copy always shows recent activity rather than dates from
/// whenever this file was written.
class SeedData {
  SeedData._();

  static String _daysAgo(int days, {int hour = 10, int minute = 0}) {
    final DateTime now = DateTime.now();
    final DateTime base = DateTime(now.year, now.month, now.day, hour, minute);
    return base.subtract(Duration(days: days)).toIso8601String();
  }

  static String _hoursAgo(int hours) {
    return DateTime.now().subtract(Duration(hours: hours)).toIso8601String();
  }

  // ---------------------------------------------------------------- users
  //
  // Passwords are NOT listed here as hashes: DatabaseHelper generates a
  // fresh salt per account at seed time and hashes the plain password below.
  // Hard-coding a hash would mean hard-coding its salt too, which would give
  // every installation of the app identical credentials on disk.

  static const List<Map<String, Object?>> users = <Map<String, Object?>>[
    <String, Object?>{
      'id': 1,
      'name': 'Store Administrator',
      'email': 'admin@babyshophub.com',
      'password': 'Admin@123',
      'phone': '08030000001',
      'role': UserRole.admin,
    },
    <String, Object?>{
      'id': 2,
      'name': 'Chidinma Okeke',
      'email': 'parent@babyshophub.com',
      'password': 'Parent@123',
      'phone': '08030000002',
      'role': UserRole.customer,
    },
    <String, Object?>{
      'id': 3,
      'name': 'Amaka Eze',
      'email': 'amaka@example.com',
      'password': 'Parent@123',
      'phone': '08030000003',
      'role': UserRole.customer,
    },
    <String, Object?>{
      'id': 4,
      'name': 'Tunde Bakare',
      'email': 'tunde@example.com',
      'password': 'Parent@123',
      'phone': '08030000004',
      'role': UserRole.customer,
    },
    <String, Object?>{
      'id': 5,
      'name': 'Ngozi Adeyemi',
      'email': 'ngozi@example.com',
      'password': 'Parent@123',
      'phone': '08030000005',
      'role': UserRole.customer,
    },
  ];

  // ----------------------------------------------------------- categories

  static const List<Map<String, Object?>> categories = <Map<String, Object?>>[
    <String, Object?>{
      'id': 1,
      'name': 'Diapering',
      'description': 'Nappies, pants, wipes and changing essentials.',
      'icon_name': 'diaper',
      'sort_order': 1,
    },
    <String, Object?>{
      'id': 2,
      'name': 'Baby Food',
      'description': 'Formula, cereals, purees and healthy snacks.',
      'icon_name': 'food',
      'sort_order': 2,
    },
    <String, Object?>{
      'id': 3,
      'name': 'Clothing',
      'description': 'Sleepsuits, rompers and soft everyday wear.',
      'icon_name': 'clothing',
      'sort_order': 3,
    },
    <String, Object?>{
      'id': 4,
      'name': 'Toys',
      'description': 'Safe, age-appropriate toys for play and learning.',
      'icon_name': 'toys',
      'sort_order': 4,
    },
    <String, Object?>{
      'id': 5,
      'name': 'Bath & Skincare',
      'description': 'Gentle washes, lotions and bath time favourites.',
      'icon_name': 'bath',
      'sort_order': 5,
    },
    <String, Object?>{
      'id': 6,
      'name': 'Feeding',
      'description': 'Bottles, bibs, sterilisers and weaning sets.',
      'icon_name': 'feeding',
      'sort_order': 6,
    },
    <String, Object?>{
      'id': 7,
      'name': 'Nursery',
      'description': 'Cots, mattresses, monitors and nursery comfort.',
      'icon_name': 'nursery',
      'sort_order': 7,
    },
    <String, Object?>{
      'id': 8,
      'name': 'Travel Gear',
      'description': 'Strollers, car seats, carriers and changing bags.',
      'icon_name': 'travel',
      'sort_order': 8,
    },
  ];

  // -------------------------------------------------------------- sellers

  static const List<Map<String, Object?>> sellers = <Map<String, Object?>>[
    <String, Object?>{
      'id': 1,
      'name': 'TinySteps Nigeria',
      'description':
          'Lagos-based retailer of everyday baby essentials since 2016.',
    },
    <String, Object?>{
      'id': 2,
      'name': 'MamaCare Stores',
      'description':
          'Pharmacy-grade feeding and skincare products, nationwide delivery.',
    },
    <String, Object?>{
      'id': 3,
      'name': 'LittleNest Supplies',
      'description': 'Organic and bamboo baby goods sourced from small makers.',
    },
    <String, Object?>{
      'id': 4,
      'name': 'BabyBloom Market',
      'description': 'Affordable everyday basics with fast dispatch.',
    },
    <String, Object?>{
      'id': 5,
      'name': 'Cuddle & Co',
      'description': 'Soft textiles, sleepwear and nursery comfort.',
    },
    <String, Object?>{
      'id': 6,
      'name': 'BrightStart Retail',
      'description': 'Larger nursery items, travel gear and learning toys.',
    },
  ];

  // ------------------------------------------------------------- products
  //
  // `image` is the file stem under assets/images/products/. Every stem
  // listed here must exist as a .png in that folder; tool/check_project.py
  // verifies that, because a missing asset is not a compile error and would
  // only show up as a broken tile at demo time.

  static const List<Map<String, Object?>> products = <Map<String, Object?>>[
    // --- Diapering -------------------------------------------------------
    <String, Object?>{
      'id': 1,
      'name': 'Baby Dry Pants Size 4',
      'brand': 'Pampers',
      'description':
          'Up to twelve hours of dryness with a soft cotton-like cover and '
              'stretchy sides that move with your baby. Pack of 44 pants for '
              'toddlers between 9 and 14 kg.',
      'price': 12500.0,
      'category_id': 1,
      'seller_id': 1,
      'stock': 40,
      'image': 'diapers-pampers-dry',
      'age_group': '6-12 months',
    },
    <String, Object?>{
      'id': 2,
      'name': 'Ultra Comfort Nappies Size 3',
      'brand': 'Huggies',
      'description':
          'Breathable outer layer with a wetness indicator that changes '
              'colour, so you know when a change is due without unfastening. '
              'Pack of 50.',
      'price': 10800.0,
      'category_id': 1,
      'seller_id': 2,
      'stock': 35,
      'image': 'diapers-huggies-comfort',
      'age_group': '3-6 months',
    },
    <String, Object?>{
      'id': 3,
      'name': 'Soft Care Newborn Nappies',
      'brand': 'Molfix',
      'description':
          'Extra-soft newborn nappies with an umbilical cord cutout and a '
              'hypoallergenic inner layer. Suitable from 2 to 5 kg.',
      'price': 7900.0,
      'category_id': 1,
      'seller_id': 3,
      'stock': 60,
      'image': 'diapers-molfix-newborn',
      'age_group': '0-3 months',
    },
    <String, Object?>{
      'id': 4,
      'name': 'Baby Wipes 4-Pack',
      'brand': 'WaterWipes',
      'description':
          'Just purified water and a drop of fruit extract. No fragrance, no '
              'alcohol. Four packs of 60 wipes, gentle enough for newborn skin.',
      'price': 6400.0,
      'category_id': 1,
      'seller_id': 1,
      'stock': 80,
      'image': 'wipes-waterwipes-4pack',
      'age_group': 'All ages',
    },
    <String, Object?>{
      'id': 5,
      'name': 'Changing Mat with Raised Edges',
      'brand': 'LittleNest',
      'description':
          'Wipe-clean padded mat with raised sides to keep your baby secure '
              'during a change. Folds flat for the changing bag.',
      'price': 9200.0,
      'category_id': 1,
      'seller_id': 3,
      'stock': 18,
      'image': 'changing-mat-raised',
      'age_group': 'All ages',
    },

    // --- Baby Food -------------------------------------------------------
    <String, Object?>{
      'id': 6,
      'name': 'Cerelac Wheat & Honey 400g',
      'brand': 'Nestle',
      'description':
          'Iron-fortified first cereal that mixes smoothly with warm water or '
              'milk. A gentle introduction to solids from six months.',
      'price': 5600.0,
      'category_id': 2,
      'seller_id': 2,
      'stock': 50,
      'image': 'food-cerelac-wheat',
      'age_group': '6-12 months',
    },
    <String, Object?>{
      'id': 7,
      'name': 'Organic Apple Puree',
      'brand': 'Gerber',
      'description':
          'Single-ingredient organic apple puree with nothing added. Smooth '
              'stage-one texture for first tastes.',
      'price': 3200.0,
      'category_id': 2,
      'seller_id': 4,
      'stock': 75,
      'image': 'food-gerber-apple',
      'age_group': '4-6 months',
    },
    <String, Object?>{
      'id': 8,
      'name': 'Optipro Stage 1 Formula 800g',
      'brand': 'NAN',
      'description':
          'Starter infant formula with a whey-dominant protein blend and DHA. '
              'For bottle feeding from birth when breastfeeding is not '
              'possible.',
      'price': 18900.0,
      'category_id': 2,
      'seller_id': 2,
      'stock': 25,
      'image': 'food-nan-optipro',
      'age_group': '0-6 months',
    },
    <String, Object?>{
      'id': 9,
      'name': 'Baby Rice Cereal 200g',
      'brand': 'Heinz',
      'description':
          'Mild, easily digested rice cereal enriched with iron and vitamin '
              'B1. Mixes to the thickness you prefer.',
      'price': 4100.0,
      'category_id': 2,
      'seller_id': 4,
      'stock': 45,
      'image': 'food-heinz-rice',
      'age_group': '4-6 months',
    },
    <String, Object?>{
      'id': 10,
      'name': 'Banana & Oat Pouches, 6 Pack',
      'brand': 'HappyBaby',
      'description':
          'Organic banana blended with wholegrain oats in a spill-proof '
              'pouch. No added sugar, no concentrates. Six 100g pouches.',
      'price': 7300.0,
      'category_id': 2,
      'seller_id': 5,
      'stock': 30,
      'image': 'food-banana-oat-pouch',
      'age_group': '6-12 months',
    },

    // --- Clothing --------------------------------------------------------
    <String, Object?>{
      'id': 11,
      'name': 'Cotton Sleepsuit 3-Pack',
      'brand': 'Cuddle & Co',
      'description':
          'Pure cotton sleepsuits with fold-over scratch mitts and poppers '
              'all the way down for one-handed night changes.',
      'price': 8900.0,
      'category_id': 3,
      'seller_id': 5,
      'stock': 40,
      'image': 'clothing-sleepsuit-3pack',
      'age_group': '0-3 months',
    },
    <String, Object?>{
      'id': 12,
      'name': 'Soft Knit Baby Cardigan',
      'brand': 'LittleNest',
      'description':
          'Lightweight knitted cardigan for cool evenings and air-conditioned '
              'rooms. Wooden buttons, machine washable.',
      'price': 6500.0,
      'category_id': 3,
      'seller_id': 3,
      'stock': 22,
      'image': 'clothing-knit-cardigan',
      'age_group': '3-6 months',
    },
    <String, Object?>{
      'id': 13,
      'name': 'Bamboo Romper with Booties',
      'brand': 'BabyBloom',
      'description':
          'Breathable bamboo viscose romper that stays cool in the heat, with '
              'matching booties. Envelope neckline for easy dressing.',
      'price': 7200.0,
      'category_id': 3,
      'seller_id': 4,
      'stock': 28,
      'image': 'clothing-bamboo-romper',
      'age_group': '0-6 months',
    },
    <String, Object?>{
      'id': 14,
      'name': 'Hooded Bath Towel Wrap',
      'brand': 'Cuddle & Co',
      'description':
          'Thick cotton towel with a hood to keep your baby warm straight out '
              'of the bath. Generous 90 by 90 cm size.',
      'price': 5800.0,
      'category_id': 3,
      'seller_id': 5,
      'stock': 34,
      'image': 'clothing-hooded-towel',
      'age_group': 'All ages',
    },
    <String, Object?>{
      'id': 15,
      'name': 'Sun Hat & Mittens Set',
      'brand': 'TinySteps',
      'description':
          'Wide-brim cotton sun hat with a chin tie, plus a pair of soft '
              'mittens. Protects delicate skin on outings.',
      'price': 4400.0,
      'category_id': 3,
      'seller_id': 1,
      'stock': 50,
      'image': 'clothing-hat-mittens',
      'age_group': '3-12 months',
    },

    // --- Toys ------------------------------------------------------------
    <String, Object?>{
      'id': 16,
      'name': 'Wooden Stacking Rings',
      'brand': 'BrightStart',
      'description':
          'Five graded rings on a rounded wooden base, finished with '
              'water-based non-toxic paint. Builds hand-eye coordination.',
      'price': 6900.0,
      'category_id': 4,
      'seller_id': 6,
      'stock': 30,
      'image': 'toys-stacking-rings',
      'age_group': '6-12 months',
    },
    <String, Object?>{
      'id': 17,
      'name': 'Soft Activity Play Gym',
      'brand': 'Fisher-Price',
      'description':
          'Padded play mat with two arches, five hanging toys, a baby-safe '
              'mirror and a crinkle leaf. Folds for storage.',
      'price': 24500.0,
      'category_id': 4,
      'seller_id': 6,
      'stock': 12,
      'image': 'toys-play-gym',
      'age_group': '0-6 months',
    },
    <String, Object?>{
      'id': 18,
      'name': 'Musical Rattle Set, 5 Piece',
      'brand': 'TinySteps',
      'description':
          'Five lightweight rattles in different shapes and sounds, sized for '
              'small hands. Free of BPA and small detachable parts.',
      'price': 5200.0,
      'category_id': 4,
      'seller_id': 1,
      'stock': 55,
      'image': 'toys-rattle-set',
      'age_group': '3-6 months',
    },
    <String, Object?>{
      'id': 19,
      'name': 'Silicone Teether Rainbow',
      'brand': 'BabyBloom',
      'description':
          'Food-grade silicone teether with textured ridges that soothe sore '
              'gums. Freezer safe and dishwasher safe.',
      'price': 2900.0,
      'category_id': 4,
      'seller_id': 4,
      'stock': 90,
      'image': 'toys-teether-rainbow',
      'age_group': '3-12 months',
    },
    <String, Object?>{
      'id': 20,
      'name': 'Shape Sorter Cube',
      'brand': 'BrightStart',
      'description':
          'Twelve chunky blocks and a sturdy cube with matching cutouts. '
              'Teaches shapes, colours and problem solving.',
      'price': 8400.0,
      'category_id': 4,
      'seller_id': 6,
      'stock': 3,
      'image': 'toys-shape-sorter',
      'age_group': '12-24 months',
    },

    // --- Bath & Skincare -------------------------------------------------
    <String, Object?>{
      'id': 21,
      'name': "Top-to-Toe Wash 500ml",
      'brand': "Johnson's",
      'description':
          'A single gentle wash for hair and body, with the no-more-tears '
              'formula. Rinses clean without drying the skin.',
      'price': 4700.0,
      'category_id': 5,
      'seller_id': 2,
      'stock': 65,
      'image': 'bath-johnsons-wash',
      'age_group': 'All ages',
    },
    <String, Object?>{
      'id': 22,
      'name': 'Daily Moisture Lotion 354ml',
      'brand': 'Aveeno',
      'description':
          'Colloidal oatmeal lotion that keeps delicate skin soft for 24 '
              'hours. Fragrance free and suitable for eczema-prone skin.',
      'price': 8100.0,
      'category_id': 5,
      'seller_id': 4,
      'stock': 38,
      'image': 'bath-aveeno-lotion',
      'age_group': 'All ages',
    },
    <String, Object?>{
      'id': 23,
      'name': 'Foldable Baby Bath Tub',
      'brand': 'MamaCare',
      'description':
          'Collapses to five centimetres for storage, with a non-slip base, a '
              'drain plug and a temperature indicator.',
      'price': 15600.0,
      'category_id': 5,
      'seller_id': 2,
      'stock': 0,
      'image': 'bath-foldable-tub',
      'age_group': '0-12 months',
    },
    <String, Object?>{
      'id': 24,
      'name': 'Nappy Rash Cream 250g',
      'brand': 'Sudocrem',
      'description':
          'Soothing antiseptic cream that forms a protective barrier against '
              'moisture. A little goes a long way.',
      'price': 6300.0,
      'category_id': 5,
      'seller_id': 3,
      'stock': 42,
      'image': 'bath-sudocrem-cream',
      'age_group': 'All ages',
    },
    <String, Object?>{
      'id': 25,
      'name': 'Bath Time Duck Set',
      'brand': 'TinySteps',
      'description':
          'Six squeezy bath toys with sealed bodies, so no water gets trapped '
              'inside and nothing goes mouldy.',
      'price': 3500.0,
      'category_id': 5,
      'seller_id': 1,
      'stock': 60,
      'image': 'bath-duck-set',
      'age_group': '6-24 months',
    },

    // --- Feeding ---------------------------------------------------------
    <String, Object?>{
      'id': 26,
      'name': 'Natural Response Bottle 260ml',
      'brand': 'Philips Avent',
      'description':
          'Wide breast-shaped teat with an anti-colic valve that vents air '
              'away from the milk. Pack of two bottles.',
      'price': 9800.0,
      'category_id': 6,
      'seller_id': 2,
      'stock': 33,
      'image': 'feeding-avent-bottle',
      'age_group': '0-6 months',
    },
    <String, Object?>{
      'id': 27,
      'name': 'Silicone Bib with Crumb Catcher',
      'brand': 'BabyBloom',
      'description':
          'Soft silicone bib that wipes clean under a tap and rolls up for '
              'the changing bag. Adjustable neck with four positions.',
      'price': 3900.0,
      'category_id': 6,
      'seller_id': 4,
      'stock': 70,
      'image': 'feeding-silicone-bib',
      'age_group': '6-24 months',
    },
    <String, Object?>{
      'id': 28,
      'name': 'Electric Steam Steriliser',
      'brand': 'MamaCare',
      'description':
          'Sterilises six bottles in eight minutes using steam alone, with no '
              'chemicals. Contents stay sterile for 24 hours if the lid is '
              'left closed.',
      'price': 42000.0,
      'category_id': 6,
      'seller_id': 2,
      'stock': 8,
      'image': 'feeding-steam-steriliser',
      'age_group': 'All ages',
    },
    <String, Object?>{
      'id': 29,
      'name': 'Training Cup 2-Pack',
      'brand': 'Tommee Tippee',
      'description':
          'Easy-grip handles and a soft spout that will not leak when it '
              'rolls off the table. A first step towards an open cup.',
      'price': 6700.0,
      'category_id': 6,
      'seller_id': 5,
      'stock': 44,
      'image': 'feeding-training-cup',
      'age_group': '12-24 months',
    },
    <String, Object?>{
      'id': 30,
      'name': 'Bamboo Suction Plate & Spoon',
      'brand': 'LittleNest',
      'description':
          'Divided bamboo plate with a silicone suction ring that grips the '
              'table, plus a matching soft-tip spoon.',
      'price': 7500.0,
      'category_id': 6,
      'seller_id': 3,
      'stock': 26,
      'image': 'feeding-suction-plate',
      'age_group': '6-24 months',
    },

    // --- Nursery ---------------------------------------------------------
    <String, Object?>{
      'id': 31,
      'name': 'Convertible Wooden Cot Bed',
      'brand': 'BrightStart',
      'description':
          'Solid pine cot with three mattress heights that converts to a '
              'toddler bed, so it lasts from birth to around three years.',
      'price': 145000.0,
      'category_id': 7,
      'seller_id': 6,
      'stock': 5,
      'image': 'nursery-cot-bed',
      'age_group': '0-36 months',
    },
    <String, Object?>{
      'id': 32,
      'name': 'Breathable Cot Mattress',
      'brand': 'MamaCare',
      'description':
          'Hypoallergenic foam core with an airflow cover and a removable, '
              'washable outer layer. Fits standard 120 by 60 cm cots.',
      'price': 38500.0,
      'category_id': 7,
      'seller_id': 2,
      'stock': 10,
      'image': 'nursery-cot-mattress',
      'age_group': '0-36 months',
    },
    <String, Object?>{
      'id': 33,
      'name': 'Baby Monitor with Night Vision',
      'brand': 'BrightStart',
      'description':
          'Five-inch parent unit with infrared night vision, two-way talk, a '
              'temperature readout and a 300 metre range.',
      'price': 56000.0,
      'category_id': 7,
      'seller_id': 6,
      'stock': 9,
      'image': 'nursery-baby-monitor',
      'age_group': 'All ages',
    },
    <String, Object?>{
      'id': 34,
      'name': 'Blackout Nursery Curtains',
      'brand': 'Cuddle & Co',
      'description':
          'Triple-weave curtains that block daylight for naps and help keep '
              'the room cool. Pair of panels with tie-backs.',
      'price': 19400.0,
      'category_id': 7,
      'seller_id': 5,
      'stock': 16,
      'image': 'nursery-blackout-curtains',
      'age_group': 'All ages',
    },
    <String, Object?>{
      'id': 35,
      'name': 'Star Projector Night Light',
      'brand': 'TinySteps',
      'description':
          'Projects a slow-moving star field on the ceiling with eight colour '
              'settings, a soft lullaby option and a sleep timer.',
      'price': 11200.0,
      'category_id': 7,
      'seller_id': 1,
      'stock': 24,
      'image': 'nursery-night-light',
      'age_group': 'All ages',
    },

    // --- Travel Gear -----------------------------------------------------
    <String, Object?>{
      'id': 36,
      'name': 'Lightweight Fold Stroller',
      'brand': 'TinySteps',
      'description':
          'Folds one-handed into a cabin-sized package and weighs 6.2 kg, '
              'with a reclining seat, a five-point harness and a sun canopy.',
      'price': 98000.0,
      'category_id': 8,
      'seller_id': 1,
      'stock': 7,
      'image': 'travel-fold-stroller',
      'age_group': '6-36 months',
    },
    <String, Object?>{
      'id': 37,
      'name': 'Group 0+ Infant Car Seat',
      'brand': 'Chicco',
      'description':
          'Rear-facing seat for babies up to 13 kg with side-impact '
              'protection, a newborn insert and a removable washable cover.',
      'price': 132000.0,
      'category_id': 8,
      'seller_id': 6,
      'stock': 4,
      'image': 'travel-car-seat',
      'age_group': '0-12 months',
    },
    <String, Object?>{
      'id': 38,
      'name': 'Ergonomic Baby Carrier',
      'brand': 'Cuddle & Co',
      'description':
          'Four carry positions with a wide seat that supports a healthy hip '
              'position, plus a padded waist belt that spreads the load.',
      'price': 34900.0,
      'category_id': 8,
      'seller_id': 5,
      'stock': 15,
      'image': 'travel-baby-carrier',
      'age_group': '3-24 months',
    },
    <String, Object?>{
      'id': 39,
      'name': 'Insulated Changing Backpack',
      'brand': 'BabyBloom',
      'description':
          'Wide-opening backpack with an insulated bottle pocket, a wipeable '
              'changing mat and stroller clips included.',
      'price': 22700.0,
      'category_id': 8,
      'seller_id': 4,
      'stock': 19,
      'image': 'travel-changing-backpack',
      'age_group': 'All ages',
    },
    <String, Object?>{
      'id': 40,
      'name': 'Travel Bottle Warmer',
      'brand': 'MamaCare',
      'description':
          'Cordless warmer that brings a bottle to feeding temperature in '
              'about six minutes on a single charge. Fits most bottle shapes.',
      'price': 16800.0,
      'category_id': 8,
      'seller_id': 2,
      'stock': 21,
      'image': 'travel-bottle-warmer',
      'age_group': '0-12 months',
    },
  ];

  // ------------------------------------------------------------- reviews
  //
  // `rating_sum` and `rating_count` on products are NOT seeded. They are
  // recalculated from these rows after insertion, using the same statement
  // the app runs whenever a review is written, so the stored totals and the
  // reviews always agree.

  static List<Map<String, Object?>> reviews() {
    return <Map<String, Object?>>[
      _review(1, 2, 5, 'Finally no more night leaks',
          'We were changing the sheets twice a week before these. Two weeks in and not one leak overnight.', 26),
      _review(1, 3, 4, 'Good but pricey',
          'Quality is genuinely better than the cheaper packs. I just wish the pack lasted longer.', 18),
      _review(1, 4, 5, 'Soft and stretchy',
          'Easy to pull on while my son is standing up, which is the only way he will accept a change now.', 9),
      _review(2, 3, 4, 'The wetness line is useful',
          'Being able to see whether a change is needed without undressing him is more helpful than I expected.', 21),
      _review(2, 5, 5, 'Great value pack',
          'Fifty in a pack at this price is hard to beat and they have never let us down.', 6),
      _review(3, 2, 5, 'Perfect for a newborn',
          'The cord cutout meant no rubbing at all in those first two weeks. Very soft.', 30),
      _review(4, 2, 5, 'The only wipes we use',
          'My daughter reacted to two other brands. These have been completely fine on her skin.', 24),
      _review(4, 4, 5, 'Gentle and no smell',
          'No perfume at all, which is exactly what we wanted. Buying the four pack again.', 11),
      _review(6, 2, 4, 'Mixes smoothly',
          'No lumps if you add the water slowly. My son finishes the bowl every morning.', 16),
      _review(6, 5, 5, 'A reliable first cereal',
          'Started weaning with this on the advice of our clinic and it has gone well.', 8),
      _review(8, 3, 5, 'Settled well with us',
          'Switched at four months and there was no upset stomach at all during the change.', 22),
      _review(10, 2, 4, 'Handy for outings',
          'The pouches are less messy than jars in the changing bag. Slightly sweet but no added sugar.', 13),
      _review(11, 2, 5, 'Excellent cotton',
          'Washed at sixty degrees a dozen times and they have not shrunk or bobbled.', 27),
      _review(11, 5, 4, 'Poppers all the way down',
          'This matters more than you think at 3am. Sizing runs slightly large.', 14),
      _review(13, 4, 5, 'Cool in the heat',
          'Bamboo really does make a difference in Lagos. He sleeps better in this than in cotton.', 10),
      _review(16, 3, 5, 'Beautifully made',
          'Solid wood, no splinters, no chemical smell. She has played with it every day for a month.', 19),
      _review(17, 2, 5, 'Bought us an hour a day',
          'She is happy under it for twenty minutes at a time, which has been a lifesaver.', 23),
      _review(17, 4, 4, 'Good but the arches sag',
          'The toys are lovely and the mat is thick. The arches bow a little after a few weeks.', 7),
      _review(19, 5, 5, 'Teething saviour',
          'Twenty minutes in the freezer and it is the only thing that calms him down.', 12),
      _review(21, 2, 4, 'Does what it says',
          'One bottle for hair and body keeps bath time simple. No stinging eyes so far.', 17),
      _review(22, 3, 5, 'Cleared up the dry patches',
          'Her cheeks were flaky for a month. Four days of this and they were smooth again.', 5),
      _review(26, 2, 5, 'Big reduction in colic',
          'We moved to these after a bad fortnight and the evening crying halved within days.', 20),
      _review(28, 4, 4, 'Fast and simple',
          'Eight minutes and done. It does take up a lot of counter space though.', 15),
      _review(31, 2, 5, 'Worth the money',
          'Assembly took about forty minutes with two people. Feels extremely solid.', 29),
      _review(33, 3, 4, 'Clear picture at night',
          'The night vision is genuinely usable. Battery on the parent unit could be better.', 4),
      _review(36, 5, 5, 'Perfect for the car boot',
          'Folds down small enough that we still have room for shopping. Pushes smoothly.', 25),
      _review(37, 2, 5, 'Fitted our car easily',
          'The base clicked in first try and the newborn insert is well padded.', 28),
      _review(38, 4, 4, 'Comfortable for long walks',
          'The waist belt takes the weight off your shoulders properly. Slightly warm in the afternoon.', 3),
    ];
  }

  static Map<String, Object?> _review(
    int productId,
    int userId,
    int rating,
    String title,
    String comment,
    int daysAgo,
  ) {
    return <String, Object?>{
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'is_hidden': 0,
      'created_at': _daysAgo(daysAgo, hour: 14, minute: 30),
    };
  }

  // ------------------------------------------------------- seller ratings

  static List<Map<String, Object?>> sellerRatings() {
    return <Map<String, Object?>>[
      _sellerRating(1, 2, 5, 'Dispatched the same afternoon. Well packed.', 24),
      _sellerRating(1, 3, 4, 'Good communication, delivery took a day longer than promised.', 15),
      _sellerRating(2, 2, 5, 'Everything sealed and in date. No complaints.', 19),
      _sellerRating(2, 4, 4, 'Reliable for formula, which is what matters to me.', 8),
      _sellerRating(3, 5, 5, 'Lovely packaging and genuinely organic materials.', 12),
      _sellerRating(4, 3, 4, 'Cheapest I found and it arrived intact.', 21),
      _sellerRating(5, 2, 5, 'The textiles are far nicer than the photos suggest.', 16),
      _sellerRating(6, 4, 4, 'The cot arrived on time and undamaged. Assembly guide is thin.', 27),
      _sellerRating(6, 5, 5, 'Handled a heavy item carefully and kept me updated.', 6),
    ];
  }

  static Map<String, Object?> _sellerRating(
    int sellerId,
    int userId,
    int rating,
    String comment,
    int daysAgo,
  ) {
    return <String, Object?>{
      'seller_id': sellerId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'created_at': _daysAgo(daysAgo, hour: 16),
    };
  }

  // ----------------------------------------------------------- addresses

  static const List<Map<String, Object?>> addresses = <Map<String, Object?>>[
    <String, Object?>{
      'user_id': 2,
      'label': 'Home',
      'full_name': 'Chidinma Okeke',
      'phone': '08030000002',
      'line1': '12 Awolowo Road',
      'line2': 'Flat 4',
      'city': 'Ikoyi',
      'state': 'Lagos',
      'postal_code': '101233',
      'is_default': 1,
    },
    <String, Object?>{
      'user_id': 2,
      'label': 'Work',
      'full_name': 'Chidinma Okeke',
      'phone': '08030000002',
      'line1': '8 Adeola Odeku Street',
      'line2': '3rd Floor',
      'city': 'Victoria Island',
      'state': 'Lagos',
      'postal_code': '101241',
      'is_default': 0,
    },
    <String, Object?>{
      'user_id': 3,
      'label': 'Home',
      'full_name': 'Amaka Eze',
      'phone': '08030000003',
      'line1': '45 Zik Avenue',
      'line2': '',
      'city': 'Enugu',
      'state': 'Enugu',
      'postal_code': '400102',
      'is_default': 1,
    },
  ];

  // ----------------------------------------------------- payment methods
  //
  // Only the brand and the last four digits exist here. No full card number
  // is stored anywhere in this project, seeded or otherwise.

  static List<Map<String, Object?>> paymentMethods() {
    final int year = DateTime.now().year + 2;
    return <Map<String, Object?>>[
      <String, Object?>{
        'user_id': 2,
        'card_holder': 'CHIDINMA OKEKE',
        'card_brand': 'Visa',
        'last4': '4242',
        'expiry_month': 9,
        'expiry_year': year,
        'is_default': 1,
      },
      <String, Object?>{
        'user_id': 3,
        'card_holder': 'AMAKA EZE',
        'card_brand': 'Mastercard',
        'last4': '8210',
        'expiry_month': 4,
        'expiry_year': year + 1,
        'is_default': 1,
      },
    ];
  }

  // -------------------------------------------------------------- orders
  //
  // Totals are NOT written here. DatabaseHelper prices these orders through
  // the same Pricing helper the checkout screen uses, so a seeded receipt
  // and a receipt the user creates during the demo add up the same way.

  static List<SeedOrder> orders() {
    return <SeedOrder>[
      SeedOrder(
        orderCode: 'BSH-100241',
        userId: 2,
        status: OrderStatus.delivered,
        placedAt: _daysAgo(21, hour: 9, minute: 15),
        shipFullName: 'Chidinma Okeke',
        shipPhone: '08030000002',
        shipLine1: '12 Awolowo Road',
        shipLine2: 'Flat 4',
        shipCity: 'Ikoyi',
        shipState: 'Lagos',
        shipPostalCode: '101233',
        paymentLabel: 'Visa ending 4242',
        items: const <SeedOrderItem>[
          SeedOrderItem(productId: 1, quantity: 2),
          SeedOrderItem(productId: 4, quantity: 1),
          SeedOrderItem(productId: 19, quantity: 2),
        ],
        eventOffsetsDays: const <int>[21, 21, 20, 19, 18, 18],
      ),
      SeedOrder(
        orderCode: 'BSH-100242',
        userId: 2,
        status: OrderStatus.shipped,
        placedAt: _daysAgo(4, hour: 11, minute: 40),
        shipFullName: 'Chidinma Okeke',
        shipPhone: '08030000002',
        shipLine1: '12 Awolowo Road',
        shipLine2: 'Flat 4',
        shipCity: 'Ikoyi',
        shipState: 'Lagos',
        shipPostalCode: '101233',
        paymentLabel: 'Visa ending 4242',
        items: const <SeedOrderItem>[
          SeedOrderItem(productId: 11, quantity: 1),
          SeedOrderItem(productId: 26, quantity: 2),
        ],
        eventOffsetsDays: const <int>[4, 4, 3, 1],
      ),
      SeedOrder(
        orderCode: 'BSH-100243',
        userId: 3,
        status: OrderStatus.pending,
        placedAt: _hoursAgo(5),
        shipFullName: 'Amaka Eze',
        shipPhone: '08030000003',
        shipLine1: '45 Zik Avenue',
        shipLine2: '',
        shipCity: 'Enugu',
        shipState: 'Enugu',
        shipPostalCode: '400102',
        paymentLabel: 'Mastercard ending 8210',
        items: const <SeedOrderItem>[
          SeedOrderItem(productId: 17, quantity: 1),
        ],
        eventOffsetsDays: const <int>[0],
      ),
    ];
  }

  // ------------------------------------------------------ support threads

  static List<Map<String, Object?>> supportTickets() {
    return <Map<String, Object?>>[
      <String, Object?>{
        'id': 1,
        'user_id': 2,
        'user_name': 'Chidinma Okeke',
        'subject': 'Sleepsuit arrived in the wrong size',
        'category': 'Order issue',
        'status': TicketStatus.inProgress,
        'created_at': _daysAgo(3, hour: 8, minute: 20),
        'updated_at': _daysAgo(2, hour: 9, minute: 5),
      },
      <String, Object?>{
        'id': 2,
        'user_id': 3,
        'user_name': 'Amaka Eze',
        'subject': 'How do I follow my delivery?',
        'category': 'Delivery',
        'status': TicketStatus.open,
        'created_at': _hoursAgo(4),
        'updated_at': _hoursAgo(4),
      },
    ];
  }

  static List<Map<String, Object?>> supportMessages() {
    return <Map<String, Object?>>[
      <String, Object?>{
        'ticket_id': 1,
        'sender_role': SenderRole.customer,
        'sender_name': 'Chidinma Okeke',
        'message':
            'I ordered the 3-pack cotton sleepsuits in 0-3 months but the pack '
                'that arrived is 3-6 months. Order BSH-100242. Can I exchange it?',
        'created_at': _daysAgo(3, hour: 8, minute: 20),
      },
      <String, Object?>{
        'ticket_id': 1,
        'sender_role': SenderRole.support,
        'sender_name': 'Store Administrator',
        'message':
            'Sorry about that. I can see the order. Please keep the packaging '
                'and I will arrange a collection and send the correct size out '
                'at no cost to you.',
        'created_at': _daysAgo(3, hour: 11, minute: 45),
      },
      <String, Object?>{
        'ticket_id': 1,
        'sender_role': SenderRole.customer,
        'sender_name': 'Chidinma Okeke',
        'message': 'That is fine, thank you. The packaging is still here.',
        'created_at': _daysAgo(2, hour: 9, minute: 5),
      },
      <String, Object?>{
        'ticket_id': 2,
        'sender_role': SenderRole.customer,
        'sender_name': 'Amaka Eze',
        'message':
            'I placed an order this morning for the play gym. Where do I see '
                'how far along it is?',
        'created_at': _hoursAgo(4),
      },
    ];
  }
}

/// A demo order described by its items; the money is worked out at seed time.
class SeedOrder {
  final String orderCode;
  final int userId;
  final String status;
  final String placedAt;
  final String shipFullName;
  final String shipPhone;
  final String shipLine1;
  final String shipLine2;
  final String shipCity;
  final String shipState;
  final String shipPostalCode;
  final String paymentLabel;
  final List<SeedOrderItem> items;

  /// How many days before today each tracking event was recorded. The list
  /// is read alongside `OrderStatus.flow`, so the first entry is when the
  /// order was placed and the last is when it reached [status].
  final List<int> eventOffsetsDays;

  const SeedOrder({
    required this.orderCode,
    required this.userId,
    required this.status,
    required this.placedAt,
    required this.shipFullName,
    required this.shipPhone,
    required this.shipLine1,
    this.shipLine2 = '',
    required this.shipCity,
    required this.shipState,
    required this.shipPostalCode,
    required this.paymentLabel,
    required this.items,
    required this.eventOffsetsDays,
  });
}

class SeedOrderItem {
  final int productId;
  final int quantity;

  const SeedOrderItem({required this.productId, required this.quantity});
}
