import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CollectionValue extends StatelessWidget {
  final double value;
  final int collected;
  final int wishlisted;

  const CollectionValue({
    super.key,
    required this.value,
    required this.collected,
    required this.wishlisted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Total collection value'),
        Text('€ $value'),
        Row(
          children: [
            _CollectionCataloged(amount: collected),
            _CollectionWishlisted(amount: wishlisted)
          ],
        ),
      ],
    );
  }
}


class _CollectionCataloged extends _CollectionSummary {
  final int amount;

  const _CollectionCataloged({
    required this.amount
  }) : super(
    icon: LucideIcons.layers,
    title: 'Cataloged',
    body: '$amount cards'
  );
}

class _CollectionWishlisted extends _CollectionSummary {
  final int amount;

  const _CollectionWishlisted({
    required this.amount
  }) : super(
    icon: LucideIcons.heart,
    title: 'Wishlisted',
    body: '$amount cards'
  );
}

class _CollectionSummary extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _CollectionSummary({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        Column(
          children: [
            Text(title),
            Text(body),
          ],
        ),
      ],
    );
  }
}
