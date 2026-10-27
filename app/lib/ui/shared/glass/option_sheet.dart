// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/glass_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom sheet with a title and a list of options, the [current] one checked. Returns the picked
/// option, or null when dismissed. [searchable] adds a field to narrow the options down, for long
/// lists; the first option (e.g. "All artists") always stays.
Future<String?> showOptionSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String current,
  bool searchable = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: context.glass.sheet,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    // Size to the content instead of the default cap of 9/16 of the screen; scrolls when longer
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => searchable
        ? _SearchableOptionSheet(title: title, options: options, current: current)
        : _OptionSheet(title: title, options: options, current: current),
  );
}

class _OptionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String current;

  const _OptionSheet({required this.title, required this.options, required this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetTitle(title),
            for (final option in options) _OptionTile(option: option, checked: option == current),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A search field over the options; the list is built lazily, as it can be thousands long.
class _SearchableOptionSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String current;

  const _SearchableOptionSheet({required this.title, required this.options, required this.current});

  @override
  State<_SearchableOptionSheet> createState() => _SearchableOptionSheetState();
}

class _SearchableOptionSheetState extends State<_SearchableOptionSheet> {
  var _search = '';

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final search = _search.trim().toLowerCase();
    final options = [
      if (widget.options.isNotEmpty) widget.options.first,
      ...widget.options.skip(1).where((o) => search.isEmpty || o.toLowerCase().contains(search)),
    ];

    return SafeArea(
      child: SizedBox(
        // Fixed height, so the sheet doesn't jump while typing
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetTitle(widget.title),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (value) => setState(() => _search = value),
                style: TextStyle(color: glass.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: glass.textTertiary),
                  prefixIcon: Icon(LucideIcons.search, size: 18, color: glass.textTertiary),
                  isDense: true,
                  filled: true,
                  fillColor: glass.fill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: glass.edge),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: glass.edge),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: options.length,
                itemBuilder: (context, i) => _OptionTile(option: options[i], checked: options[i] == widget.current),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String title;

  const _SheetTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text(
        title,
        style: TextStyle(color: context.glass.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String option;
  final bool checked;

  const _OptionTile({required this.option, required this.checked});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return ListTile(
      title: Text(option, style: TextStyle(color: glass.textPrimary)),
      trailing: checked ? Icon(LucideIcons.check, size: 18, color: glass.textPrimary) : null,
      onTap: () => Navigator.pop(context, option),
    );
  }
}
