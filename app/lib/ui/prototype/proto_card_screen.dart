// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: card details, full screen over the nav bar. Collection and shop in one place: the
// card, its price, your copies and wishlist status, and the store listings to buy it from, with an
// "Add to cart" bar at the bottom. Borrows from Discogs: community have/want counts, and the
// marketplace listings right on the item page.

import 'dart:math';
import 'dart:ui';

import 'package:app/tmp/core/utils/format.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/prototype/glass.dart';
import 'package:app/ui/prototype/proto_common.dart';
import 'package:app/ui/prototype/proto_data.dart';
import 'package:app/ui/shared/glass_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProtoCardScreen extends StatefulWidget {
  final String cardId;

  const ProtoCardScreen({super.key, required this.cardId});

  @override
  State<ProtoCardScreen> createState() => _ProtoCardScreenState();
}

class _Listing {
  final String condition;
  final String seller;
  final double price;
  final int stock;

  const _Listing(this.condition, this.seller, this.price, this.stock);
}

class _ProtoCardScreenState extends State<ProtoCardScreen> {
  late final ProtoCard? _card = ProtoData.card(widget.cardId);
  late final _random = Random(widget.cardId.hashCode);

  late String _finish = _finishes.first;
  late int _owned = _card?.owned ?? 0;
  late bool _wishlisted = _card?.wishlisted ?? false;
  late final _change = (_random.nextDouble() * 18 - 6); // 7-day price change in %, mostly up
  late final _have = 200 + _random.nextInt(4000);
  late final _want = 40 + _random.nextInt(900);
  late final _history = _makeHistory();
  late final _listings = _card == null || !_card.inStore
      ? const <_Listing>[]
      : [
          _Listing('Near Mint', 'TCG Collector Store', _card.price, 1 + _random.nextInt(4)),
          _Listing('Near Mint', 'Partner seller', _card.price * 1.06, 1),
          _Listing('Lightly Played', 'TCG Collector Store', _card.price * 0.82, 2),
        ];

  List<String> get _finishes => switch (_card?.game) {
    Tcg.pokemon => const ['Normal', 'Holofoil', 'Reverse Holo'],
    Tcg.mtg => const ['Nonfoil', 'Foil'],
    _ => const ['Normal', 'Foil'],
  };

  // 30 days of made-up prices, ending at today's price, moving by roughly _change overall.
  List<double> _makeHistory() {
    final end = _card?.price ?? 1;
    final start = end / (1 + _change / 100);
    return [
      for (var i = 0; i < 30; i++) start + (end - start) * (i / 29) + (_random.nextDouble() - 0.5) * end * 0.06,
    ]..[29] = end;
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    if (card == null) {
      return Scaffold(
        backgroundColor: (ProtoTheme.isDark ? Colors.black : const Color(0xFFF4F6FA)),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(child: Text('Card not found', style: TextStyle(color: GlassText.secondary))),
      );
    }

    final palette = GamePalette.of(card.game);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: (ProtoTheme.isDark ? Colors.black : const Color(0xFFF4F6FA)),
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        actions: [
          IconButton(
            onPressed: () => setState(() => _wishlisted = !_wishlisted),
            icon: Icon(LucideIcons.heart, color: _wishlisted ? palette.accent : GlassText.primary),
          ),
          IconButton(onPressed: () {}, icon: Icon(LucideIcons.share2, color: GlassText.primary)),
          const CartButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: ProtoBackdrop(game: card.game)),
          Builder(
            builder: (context) => ListView(
              padding: EdgeInsets.fromLTRB(16, GlassAppBar.contentTopPadding(context) + 12, 16, 120),
              children: [
                // The card, with a soft glow in the game's color
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: palette.glows.first.withValues(alpha: 0.45), blurRadius: 60, spreadRadius: 4),
                        const BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 12)),
                      ],
                    ),
                    child: CardThumb(game: card.game, width: screenWidth * 0.58, radius: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Name and where it's from
                Text(
                  card.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GlassText.primary, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  '${card.setName} · ${card.number}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GlassText.secondary, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (card.rarity != null) GlassChip(label: card.rarity!, icon: LucideIcons.gem),
                    GlassChip(label: card.game.displayName),
                  ],
                ),
                const SizedBox(height: 24),

                // Finish
                _Segmented(
                  options: _finishes,
                  selected: _finish,
                  accent: palette.accent,
                  onChanged: (finish) => setState(() => _finish = finish),
                ),
                const SizedBox(height: 14),

                // Price
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Market price', style: TextStyle(color: GlassText.secondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            formatEuro(card.price),
                            style: TextStyle(
                              color: GlassText.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 10),
                          GlassChip(
                            icon: _change >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                            label: '${_change >= 0 ? '+' : ''}${_change.toStringAsFixed(1)}% · 7d',
                            color: _change >= 0 ? GlassText.positive : GlassText.negative,
                            filled: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 64,
                        width: double.infinity,
                        child: CustomPaint(painter: _Sparkline(_history, palette.accent)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('30 days ago', style: TextStyle(color: GlassText.tertiary, fontSize: 11)),
                          Spacer(),
                          Text('Today', style: TextStyle(color: GlassText.tertiary, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Your copies, wishlist, and what other collectors have/want
                ProtoListCard(
                  rows: [
                    _Row(
                      icon: LucideIcons.layers,
                      title: 'In your collection',
                      trailing: _Stepper(value: _owned, onChanged: (v) => setState(() => _owned = v)),
                    ),
                    _Row(
                      icon: LucideIcons.heart,
                      title: 'On your wishlist',
                      trailing: Switch(
                        value: _wishlisted,
                        activeThumbColor: palette.accent,
                        activeTrackColor: palette.accent.withValues(alpha: 0.35),
                        onChanged: (v) => setState(() => _wishlisted = v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Row(
                        children: [
                          Expanded(child: ProtoStat(value: _compact(_have), label: 'Collectors have this')),
                          Expanded(child: ProtoStat(value: _compact(_want), label: 'Collectors want this')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Store listings
                ProtoHeading(
                  'For sale',
                  trailing: _listings.isEmpty
                      ? null
                      : Text(
                          '${_listings.length} listings · from ${formatEuro(_listings.map((l) => l.price).reduce(min))}',
                          style: TextStyle(color: GlassText.tertiary, fontSize: 13),
                        ),
                ),
                if (_listings.isEmpty)
                  GlassCard(
                    child: Row(
                      children: [
                        Icon(LucideIcons.bellRing, size: 18, color: GlassText.secondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Not in store right now. Wishlist it to get notified when it is.',
                            style: TextStyle(color: GlassText.secondary, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ProtoListCard(
                    rows: [for (final listing in _listings) _ListingRow(listing: listing, onAdd: () => _addToCart(card, listing))],
                  ),
                const SizedBox(height: 24),

                // Details
                const ProtoHeading('Details'),
                ProtoListCard(
                  rows: [
                    _Detail('Set', card.setName),
                    _Detail('Number', card.number),
                    if (card.rarity != null) _Detail('Rarity', card.rarity!),
                    const _Detail('Language', 'English'),
                    const _Detail('Artist', 'Mock Artist'),
                  ],
                ),
              ],
            ),
          ),

          // Buy bar, frosted, over the bottom of the page
          if (_listings.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 14, 16, 14 + MediaQuery.paddingOf(context).bottom),
                    decoration: BoxDecoration(
                      color: GlassColors.current.bar,
                      border: Border(top: BorderSide(color: GlassColors.current.edge)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatEuro(_listings.first.price),
                                style: TextStyle(color: GlassText.primary, fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Near Mint · $_finish',
                                style: TextStyle(color: GlassText.secondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _addToCart(card, _listings.first),
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.accent,
                            foregroundColor: GlassText.onAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          icon: const Icon(LucideIcons.shoppingCart, size: 18),
                          label: const Text('Add to cart'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _addToCart(ProtoCard card, _Listing listing) {
    addToCart(card, finish: _finish, condition: listing.condition);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        content: Text('${card.name} added to cart'),
      ));
  }

  static String _compact(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

// Glass segmented control.
class _Segmented extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Color accent;
  final ValueChanged<String> onChanged;

  const _Segmented({required this.options, required this.selected, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: GlassColors.of(context).fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GlassColors.current.edge),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: option == selected ? accent.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: option == selected ? accent.withValues(alpha: 0.5) : Colors.transparent),
                  ),
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: option == selected ? accent : GlassText.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;

  const _Row({required this.icon, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Icon(icon, size: 18, color: GlassText.secondary),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: GlassText.primary, fontSize: 15, fontWeight: FontWeight.w500))),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback? onTap) => IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      color: GlassText.primary,
      disabledColor: GlassText.tertiary,
      style: IconButton.styleFrom(backgroundColor: GlassColors.of(context).fill),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(LucideIcons.minus, value > 0 ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(color: GlassText.primary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        button(LucideIcons.plus, () => onChanged(value + 1)),
      ],
    );
  }
}

class _ListingRow extends StatelessWidget {
  final _Listing listing;
  final VoidCallback onAdd;

  const _ListingRow({required this.listing, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.condition, style: TextStyle(color: GlassText.primary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${listing.seller} · ${listing.stock} available',
                  style: TextStyle(color: GlassText.tertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatEuro(listing.price),
            style: TextStyle(color: GlassText.primary, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus, size: 18),
            color: GlassText.primary,
            style: IconButton.styleFrom(backgroundColor: GlassColors.of(context).fill),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;

  const _Detail(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: GlassText.tertiary, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: GlassText.primary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Price line with a soft fill under it.
class _Sparkline extends CustomPainter {
  final List<double> values;
  final Color color;

  _Sparkline(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final low = values.reduce(min);
    final high = values.reduce(max);
    final range = high - low == 0 ? 1 : high - low;

    Offset point(int i) => Offset(
      size.width * i / (values.length - 1),
      size.height - (values[i] - low) / range * (size.height - 4) - 2,
    );

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(point(i).dx, point(i).dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(point(values.length - 1), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Sparkline oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}
