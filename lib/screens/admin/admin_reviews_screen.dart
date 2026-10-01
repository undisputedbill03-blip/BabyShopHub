import 'package:flutter/material.dart';

import '../../core/formats.dart';
import '../../core/theme.dart';
import '../../data/review_repository.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// Review moderation. Every review in the shop is listed here with the product
/// it belongs to. An admin can hide a review (it keeps the row but stops
/// counting toward the product's rating) or delete it outright. Hiding is
/// reversible; deleting is not, so the row offers both.
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final ReviewRepository _reviews = ReviewRepository();
  final TextEditingController _search = TextEditingController();

  late Future<List<Review>> _future;
  String _query = '';
  bool _onlyHidden = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Review>> _load() =>
      _reviews.allForModeration(query: _query, onlyHidden: _onlyHidden);

  void _reload() => setState(() => _future = _load());

  Future<void> _toggleHidden(Review review) async {
    final String? error = await _reviews.setHidden(
      reviewId: review.id!,
      hidden: !review.isHidden,
    );
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      showSnack(context, review.isHidden ? 'Review restored.' : 'Review hidden.');
      _reload();
    }
  }

  Future<void> _delete(Review review) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this review?'),
        content: const Text(
            'This permanently removes the review. Consider hiding it instead '
            'if you may want to restore it later.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;

    final String? error = await _reviews.deleteAsAdmin(review.id!);
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      showSnack(context, 'Review deleted.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _search,
              onChanged: (String v) {
                _query = v;
                _reload();
              },
              decoration: AppInput.decoration(
                label: 'Search product, author or text',
                icon: Icons.search,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: <Widget>[
                FilterChip(
                  label: const Text('Hidden only'),
                  selected: _onlyHidden,
                  onSelected: (bool v) {
                    setState(() {
                      _onlyHidden = v;
                      _future = _load();
                    });
                  },
                  showCheckmark: true,
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primarySoft,
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    side: BorderSide(
                        color: _onlyHidden
                            ? AppColors.primary
                            : AppColors.border),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: AsyncView<List<Review>>(
                future: _future,
                builder: (List<Review> reviews) {
                  if (reviews.isEmpty) {
                    return const EmptyState(
                      icon: Icons.reviews_outlined,
                      title: 'No reviews',
                      message: 'Customer reviews appear here for moderation.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int i) => _ReviewCard(
                      review: reviews[i],
                      onToggleHidden: () => _toggleHidden(reviews[i]),
                      onDelete: () => _delete(reviews[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback onToggleHidden;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.review,
    required this.onToggleHidden,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: review.isHidden ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(review.productName,
                      style: AppText.small
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (review.isHidden)
                  const StatusPill(label: 'Hidden', color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                StarRating(rating: review.rating.toDouble(), size: 15),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${review.userName}  ·  ${Formats.relative(review.createdAt)}',
                    style: AppText.tiny,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (review.title.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(review.title,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
            ],
            if (review.comment.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(review.comment, style: AppText.small),
            ],
            const Divider(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                  onPressed: onToggleHidden,
                  icon: Icon(
                    review.isHidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  label: Text(review.isHidden ? 'Restore' : 'Hide'),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
