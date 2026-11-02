// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:flutter/material.dart';

/// Asks for a collection's or wishlist's name: for a new one, or to rename one ([initial] is its
/// name). Returns the trimmed name, or null when cancelled.
Future<String?> showCollectionNameDialog(
  BuildContext context, {
  required ListKind kind,
  required Color accent,
  String initial = '',
}) => showDialog<String>(
  context: context,
  builder: (context) => _NameDialog(kind: kind, accent: accent, initial: initial),
);

/// Asks whether to delete the collection or wishlist [name] and its cards. True when confirmed.
Future<bool> confirmDeleteCollection(BuildContext context, {required ListKind kind, required String name}) async {
  final glass = context.glass;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: glass.sheet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Delete "$name"?',
        style: TextStyle(color: glass.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: Text(
        "The ${kind.name} and the cards in it, of every game, are removed. This can't be undone.",
        style: TextStyle(color: glass.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: glass.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Delete',
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _NameDialog extends StatefulWidget {
  final ListKind kind;
  final Color accent;
  final String initial;

  const _NameDialog({required this.kind, required this.accent, required this.initial});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  static const _maxLength = 100; // As the API allows

  late final _field = TextEditingController(text: widget.initial);

  bool get _isNew => widget.initial.isEmpty;

  void _submit() {
    final name = _field.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return AlertDialog(
      backgroundColor: glass.sheet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        _isNew ? 'New ${widget.kind.name}' : 'Rename ${widget.kind.name}',
        style: TextStyle(color: glass.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _field,
        autofocus: true,
        maxLength: _maxLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        cursorColor: widget.accent,
        style: TextStyle(color: glass.textPrimary),
        decoration: InputDecoration(
          hintText: switch (widget.kind) {
            ListKind.collection => 'E.g. Binder, Trades, Graded',
            ListKind.wishlist => 'E.g. Deck upgrades, Set to finish, Gifts',
          },
          hintStyle: TextStyle(color: glass.textTertiary),
          counterText: '',
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.accent)),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: glass.textSecondary)),
        ),
        ListenableBuilder(
          listenable: _field,
          builder: (context, _) => TextButton(
            onPressed: _field.text.trim().isEmpty ? null : _submit,
            child: Text(
              _isNew ? 'Create' : 'Save',
              style: TextStyle(
                color: _field.text.trim().isEmpty ? glass.textTertiary : widget.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
