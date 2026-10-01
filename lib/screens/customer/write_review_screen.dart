import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/review_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Writes or edits a product review. Pops with `true` when a review was
/// saved, so the product page knows to reload its rating.
class WriteReviewScreen extends StatefulWidget {
  final Product product;
  final Review? existing;

  const WriteReviewScreen({
    super.key,
    required this.product,
    this.existing,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final ReviewRepository _reviews = ReviewRepository();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _comment = TextEditingController();
  int _rating = 5;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final Review? existing = widget.existing;
    if (existing != null) {
      _rating = existing.rating;
      _title.text = existing.title;
      _comment.text = existing.comment;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final SessionProvider session = context.read<SessionProvider>();
    final AppUser? user = session.user;
    if (user == null) {
      showSnack(context, 'Please sign in first.', error: true);
      return;
    }
    setState(() => _busy = true);
    final String? error = await _reviews.submit(
      productId: widget.product.id!,
      userId: user.id!,
      userName: user.name,
      rating: _rating,
      title: _title.text,
      comment: _comment.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      showSnack(context, 'Thanks! Your review has been saved.');
      Navigator.of(context).pop(true);
    } else {
      showSnack(context, error, error: true);
    }
  }

  Future<void> _delete() async {
    final SessionProvider session = context.read<SessionProvider>();
    final int? userId = session.userId;
    if (userId == null) return;
    setState(() => _busy = true);
    await _reviews.deleteOwn(userId: userId, productId: widget.product.id!);
    if (!mounted) return;
    setState(() => _busy = false);
    showSnack(context, 'Your review has been removed.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit your review' : 'Write a review'),
        actions: <Widget>[
          if (editing)
            IconButton(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete review',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          ProductRow(
            imagePath: widget.product.imagePath,
            name: widget.product.name,
            brand: widget.product.brand,
            priceLabel: '',
          ),
          const Divider(height: AppSpacing.xl),
          Center(
            child: Column(
              children: <Widget>[
                const Text('How would you rate it?', style: AppText.h3),
                const SizedBox(height: AppSpacing.sm),
                StarRatingInput(
                  value: _rating,
                  onChanged: (int v) => setState(() => _rating = v),
                ),
                Text(_ratingWord(_rating), style: AppText.small),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            decoration: AppInput.decoration(
              label: 'Title (optional)',
              hint: 'Sum it up in a few words',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _comment,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 5,
            maxLength: 500,
            decoration: AppInput.decoration(
              label: 'Your review (optional)',
              hint: 'What did you like or dislike?',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: AppButtons.primary(),
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(editing ? 'Save changes' : 'Submit review'),
          ),
        ],
      ),
    );
  }

  String _ratingWord(int rating) {
    switch (rating) {
      case 5:
        return 'Love it';
      case 4:
        return 'Really good';
      case 3:
        return 'It is okay';
      case 2:
        return 'Not great';
      default:
        return 'Disappointing';
    }
  }
}
