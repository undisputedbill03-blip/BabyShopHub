import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A row of stars showing an average rating, with optional count beside it.
///
/// Read-only. The tappable version used on the review form is
/// [StarRatingInput] below.
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final int? count;
  final bool showValue;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.count,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= 5; i++) _star(i),
        if (showValue) ...<Widget>[
          SizedBox(width: size * 0.35),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.85,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        if (count != null) ...<Widget>[
          SizedBox(width: size * 0.25),
          Text(
            '($count)',
            style: TextStyle(fontSize: size * 0.8, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _star(int position) {
    final IconData icon;
    if (rating >= position) {
      icon = Icons.star_rounded;
    } else if (rating >= position - 0.5) {
      icon = Icons.star_half_rounded;
    } else {
      icon = Icons.star_outline_rounded;
    }
    return Icon(icon, size: size, color: AppColors.star);
  }
}

/// A tappable star row for choosing a rating on the review form.
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= 5; i++)
          IconButton(
            onPressed: () => onChanged(i),
            visualDensity: VisualDensity.compact,
            iconSize: size,
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppColors.star,
            ),
            tooltip: '$i star${i == 1 ? '' : 's'}',
          ),
      ],
    );
  }
}
