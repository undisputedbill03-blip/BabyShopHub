import '../core/app_config.dart';
import '../models/support_ticket.dart';

/// Help-centre content shown on the Support screen.
///
/// These live in code rather than in the database because they are part of
/// the app's user documentation, not user data: they ship with the build and
/// no one edits them at runtime.
const List<FaqEntry> kFaqEntries = <FaqEntry>[
  FaqEntry(
    'How do I create an account?',
    'Tap Register on the welcome screen, enter your name, email address, '
        'phone number and a password of at least eight characters containing '
        'a letter and a digit, then tap Create account. You are signed in '
        'straight away.',
  ),
  FaqEntry(
    'I forgot my password. What do I do?',
    '${AppConfig.appName} stores all data on this device only, so there is no '
        'email reset link. Contact support from this screen and an '
        'administrator can reset the password on the account for you.',
  ),
  FaqEntry(
    'How do I find a product?',
    'Use the search bar at the top of the Home screen to search by product '
        'name or brand, or open Categories to browse. On the search results '
        'screen you can narrow by category, price range, minimum rating and '
        'availability, and sort by price, rating or newest.',
  ),
  FaqEntry(
    'How do I change the quantity of something in my cart?',
    'Open the Cart tab and use the minus and plus buttons on the item. The '
        'plus button stops at the quantity we have in stock. Swipe an item or '
        'tap the bin icon to remove it.',
  ),
  FaqEntry(
    'How much is delivery?',
    'Delivery is a flat fee that is shown on the checkout screen before you '
        'pay, and it is free once your items total reaches the free-delivery '
        'threshold. The cart tells you how much more you need to add to '
        'qualify.',
  ),
  FaqEntry(
    'Is my card charged?',
    'No. Payment in this application is simulated for demonstration '
        'purposes. Only the cardholder name, the card brand and the last four '
        'digits are saved, so we can label your order; the full number is '
        'never stored and no security code is ever collected. Nothing is sent '
        'to a bank or to any server.',
  ),
  FaqEntry(
    'How do I track my order?',
    'Open Orders from the bottom bar and tap the order you want. The '
        'tracking timeline shows every stage the parcel has reached, with the '
        'date and time each stage was recorded.',
  ),
  FaqEntry(
    'Can I cancel an order?',
    'Yes, while the order is still with us. The Cancel order button appears '
        'on the order detail screen until the parcel is handed to the '
        'courier. Once the status reaches Shipped it can no longer be '
        'cancelled from the app. Cancelling returns the items to stock.',
  ),
  FaqEntry(
    'When can I review a product?',
    'Once an order containing that product is marked Delivered. Open the '
        'order and tap Write a review next to the item. You can give one '
        'review per product, and editing it replaces your earlier one.',
  ),
  FaqEntry(
    'How do I rate a seller?',
    'Open any product from that seller, tap the seller name to open their '
        'page, then tap Rate this seller. Seller ratings are separate from '
        'product reviews so a great product from a slow seller can be scored '
        'honestly on both.',
  ),
  FaqEntry(
    'How do I change my delivery address?',
    'Go to Profile, then Delivery addresses. You can save several addresses, '
        'mark one as the default, and pick a different one at checkout.',
  ),
  FaqEntry(
    'Where is my data stored?',
    'Everything stays in a database file on this device. There is no account '
        'server and nothing leaves the phone, so uninstalling the app removes '
        'your data permanently.',
  ),
];
