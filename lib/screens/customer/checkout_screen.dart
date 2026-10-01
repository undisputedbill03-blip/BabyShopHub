import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/formats.dart';
import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../data/order_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'address_form_screen.dart';
import 'order_confirmation_screen.dart';
import 'payment_form_screen.dart';

/// Checkout: choose an address, choose a (simulated) payment method, review
/// the order and place it.
///
/// The payment step is deliberately a simulation, as the brief specifies.
/// No card number is captured here — a saved card is chosen by its masked
/// label, the "payment" is a short delay, and the order is written locally.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final AuthRepository _auth = AuthRepository();
  final OrderRepository _orders = OrderRepository();

  late Future<_CheckoutData> _future;
  Address? _address;
  PaymentMethod? _payment;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CheckoutData> _load() async {
    final int userId = context.read<SessionProvider>().userId!;
    final List<Address> addresses = await _auth.addressesFor(userId);
    final List<PaymentMethod> cards = await _auth.paymentMethodsFor(userId);

    // Keep any earlier choice if it still exists, otherwise fall back to the
    // default so the review section is never empty when something is saved.
    _address = _pickAddress(addresses, _address?.id);
    _payment = _pickCard(cards, _payment?.id);

    return _CheckoutData(addresses: addresses, cards: cards);
  }

  /// Chooses which address to preselect: the one already chosen if it still
  /// exists, then the default, then the first, then none.
  Address? _pickAddress(List<Address> list, int? preferredId) {
    if (list.isEmpty) return null;
    for (final Address a in list) {
      if (a.id == preferredId) return a;
    }
    for (final Address a in list) {
      if (a.isDefault) return a;
    }
    return list.first;
  }

  PaymentMethod? _pickCard(List<PaymentMethod> list, int? preferredId) {
    if (list.isEmpty) return null;
    for (final PaymentMethod c in list) {
      if (c.id == preferredId) return c;
    }
    for (final PaymentMethod c in list) {
      if (c.isDefault) return c;
    }
    return list.first;
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _addAddress() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddressFormScreen()),
    );
    if (saved == true) _reload();
  }

  Future<void> _addCard() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const PaymentFormScreen()),
    );
    if (saved == true) _reload();
  }

  Future<void> _placeOrder(CartProvider cart) async {
    if (_address == null) {
      showSnack(context, 'Please add a delivery address.', error: true);
      return;
    }
    if (_payment == null) {
      showSnack(context, 'Please add a payment method.', error: true);
      return;
    }

    setState(() => _placing = true);

    // Read the session id before the await, so no BuildContext is used across
    // the simulated gateway round-trip; the signed-in user cannot change here.
    final int userId = context.read<SessionProvider>().userId!;

    // Simulated payment authorisation. This stands in for a real gateway
    // round-trip; nothing leaves the device.
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final PlaceOrderResult result = await _orders.placeOrder(
      userId: userId,
      address: _address!,
      paymentLabel: _payment!.orderLabel,
    );

    if (!mounted) return;
    setState(() => _placing = false);

    if (!result.ok) {
      showSnack(context, result.error ?? 'Could not place order.', error: true);
      return;
    }

    await cart.reload();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationScreen(order: result.order!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CartProvider cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: AsyncView<_CheckoutData>(
        future: _future,
        builder: (_CheckoutData data) => Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  _AddressSection(
                    addresses: data.addresses,
                    selected: _address,
                    onSelect: (Address a) => setState(() => _address = a),
                    onAdd: _addAddress,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _PaymentSection(
                    cards: data.cards,
                    selected: _payment,
                    onSelect: (PaymentMethod c) => setState(() => _payment = c),
                    onAdd: _addCard,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _OrderSummary(cart: cart),
                  const SizedBox(height: AppSpacing.md),
                  _SimulationNote(),
                ],
              ),
            ),
            _PlaceOrderBar(
              total: cart.total,
              placing: _placing,
              onPlace: () => _placeOrder(cart),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  final List<Address> addresses;
  final Address? selected;
  final ValueChanged<Address> onSelect;
  final VoidCallback onAdd;

  const _AddressSection({
    required this.addresses,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(child: Text('Delivery address', style: AppText.h3)),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (addresses.isEmpty)
          const _EmptyPicker(
            icon: Icons.location_on_outlined,
            message: 'No saved address. Add one to continue.',
          )
        else
          for (final Address address in addresses)
            _SelectableCard(
              selected: selected?.id == address.id,
              onTap: () => onSelect(address),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(address.label,
                          style: AppText.body
                              .copyWith(fontWeight: FontWeight.w700)),
                      if (address.isDefault) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        const StatusPill(
                            label: 'Default', color: AppColors.accent),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(address.fullName, style: AppText.small),
                  Text(address.oneLine, style: AppText.small),
                  Text(address.phone, style: AppText.small),
                ],
              ),
            ),
      ],
    );
  }
}

class _PaymentSection extends StatelessWidget {
  final List<PaymentMethod> cards;
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onSelect;
  final VoidCallback onAdd;

  const _PaymentSection({
    required this.cards,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(child: Text('Payment method', style: AppText.h3)),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (cards.isEmpty)
          const _EmptyPicker(
            icon: Icons.credit_card_outlined,
            message: 'No saved card. Add one to continue.',
          )
        else
          for (final PaymentMethod card in cards)
            _SelectableCard(
              selected: selected?.id == card.id,
              onTap: () => onSelect(card),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.credit_card, color: AppColors.primaryDark),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('${card.cardBrand} ${Formats.maskedCard(card.last4)}',
                            style: AppText.body
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text('Expires ${card.expiryLabel}  ·  ${card.cardHolder}',
                            style: AppText.tiny),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(color: AppColors.surfaceAlt),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Order summary (${cart.lineCount} item'
              '${cart.lineCount == 1 ? '' : 's'})', style: AppText.h3),
          const SizedBox(height: AppSpacing.sm),
          for (final CartItem item in cart.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text('${item.quantity} × ${item.product.name}',
                        style: AppText.small,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(Formats.money(item.lineTotal), style: AppText.small),
                ],
              ),
            ),
          const Divider(height: AppSpacing.lg),
          _row('Subtotal', Formats.money(cart.subtotal)),
          _row('Delivery',
              cart.shipping == 0 ? 'Free' : Formats.money(cart.shipping)),
          _row('VAT (${(AppConfig.taxRate * 100).round()}%)',
              Formats.money(cart.tax)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              const Text('Total', style: AppText.h3),
              const Spacer(),
              Text(Formats.money(cart.total), style: AppText.price),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Text(label, style: AppText.bodyMuted),
          const Spacer(),
          Text(value, style: AppText.body),
        ],
      ),
    );
  }
}

class _SimulationNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: AppColors.accent),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Payment is simulated for this demo. No real card is charged '
              'and no card details leave your device.',
              style: AppText.tiny,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  final double total;
  final bool placing;
  final VoidCallback onPlace;

  const _PlaceOrderBar({
    required this.total,
    required this.placing,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: placing ? null : onPlace,
          style: AppButtons.primary(),
          child: placing
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Text('Processing payment...'),
                  ],
                )
              : Text('Pay ${Formats.money(total)}'),
        ),
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _SelectableCard({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPicker({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: AppText.bodyMuted)),
        ],
      ),
    );
  }
}

class _CheckoutData {
  final List<Address> addresses;
  final List<PaymentMethod> cards;

  const _CheckoutData({required this.addresses, required this.cards});
}
