// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:async';

import 'package:app/domain/models/user/sync_code.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/settings/view_models/sync_code_viewmodel.dart';
import 'package:app/ui/settings/widgets/setting_row.dart';
import 'package:app/ui/shared/glass/loading_indicator.dart';
import 'package:app/ui/shared/view_model_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// "Sync": a button to create a sync code, to continue with this collection on another device. A
/// new code shows in a popup; after that, under the button with how long it's still valid. Below
/// that, a field to enter another device's code and continue with its collection here.
class SyncSettings extends StatelessWidget {
  final Color accent;

  const SyncSettings({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ViewModelHost(
      create: (context) => SyncCodeViewModel(syncRepository: context.read()),
      builder: (context, viewModel) => _SyncSettingsView(viewModel: viewModel, accent: accent),
    );
  }
}

class _SyncSettingsView extends StatefulWidget {
  final SyncCodeViewModel viewModel;
  final Color accent;

  const _SyncSettingsView({required this.viewModel, required this.accent});

  @override
  State<_SyncSettingsView> createState() => _SyncSettingsViewState();
}

class _SyncSettingsViewState extends State<_SyncSettingsView> {
  Timer? _ticker; // Counts down the code's validity, while there is one
  final _redeemField = TextEditingController();

  static const _codeLength = 8; // Like the API's

  @override
  void dispose() {
    _ticker?.cancel();
    _redeemField.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmRedeemDialog(accent: widget.accent),
    );
    if (confirmed != true || !mounted) return;

    // On success the app reloads as the other device's user, so there's only a failure to show
    await widget.viewModel.redeem.execute(_redeemField.text);
    if (!mounted) return;
    final failure = widget.viewModel.redeemFailure;
    if (failure == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (failure) {
          RedeemFailure.invalidCode => 'This code is wrong, already used or expired',
          RedeemFailure.ownCode => 'This code is from this device',
          RedeemFailure.tooManyAttempts => 'Too many attempts, try again later',
          RedeemFailure.unavailable => "Couldn't redeem the code, try again later",
        }),
      ),
    );
  }

  Future<void> _create() async {
    final viewModel = widget.viewModel;
    await viewModel.create.execute();
    if (!mounted) return;

    final code = viewModel.code;
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't create a sync code")));
      return;
    }

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (viewModel.code == null) _ticker?.cancel(); // Expired: the row goes away
      setState(() {});
    });
    setState(() {});
    await showDialog<void>(
      context: context,
      builder: (context) => _SyncCodeDialog(code: code, accent: widget.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return ListenableBuilder(
      listenable: Listenable.merge([widget.viewModel, widget.viewModel.create, widget.viewModel.redeem, _redeemField]),
      builder: (context, _) {
        final code = widget.viewModel.code;
        final running = widget.viewModel.create.running;
        final redeeming = widget.viewModel.redeem.running;
        final canRedeem = !redeeming && _redeemField.text.trim().length == _codeLength;

        return SettingsGroup(
          title: 'Sync',
          rows: [
            SettingRow(
              icon: LucideIcons.smartphone,
              title: 'Create sync code',
              subtitle: 'Continue with this collection on another device',
              trailing: running ? LoadingIndicator(size: 18, color: widget.accent) : null,
              onTap: running ? null : _create,
            ),
            if (code != null)
              SettingRow(
                icon: LucideIcons.keyRound,
                title: code.code,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.timer, size: 14, color: glass.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      _countdown(code.remaining),
                      style: TextStyle(
                        color: glass.textTertiary,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Row(
                children: [
                  Icon(LucideIcons.download, size: 18, color: glass.textSecondary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _redeemField,
                      enabled: !redeeming,
                      maxLength: _codeLength,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                        TextInputFormatter.withFunction((_, value) => value.copyWith(text: value.text.toUpperCase())),
                      ],
                      onSubmitted: (_) => canRedeem ? _redeem() : null,
                      style: TextStyle(color: glass.textPrimary, fontSize: 15, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'Enter a sync code',
                        hintStyle: TextStyle(color: glass.textTertiary, fontSize: 15, letterSpacing: 0),
                        counterText: '',
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (redeeming)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: LoadingIndicator(size: 18, color: widget.accent),
                    )
                  else
                    TextButton(
                      onPressed: canRedeem ? _redeem : null,
                      child: Text(
                        'Redeem',
                        style: TextStyle(
                          color: canRedeem ? widget.accent : glass.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Asks before redeeming: this device's own collection and lists are replaced.
class _ConfirmRedeemDialog extends StatelessWidget {
  final Color accent;

  const _ConfirmRedeemDialog({required this.accent});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return AlertDialog(
      backgroundColor: glass.sheet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        "Use the other device's collection?",
        style: TextStyle(color: glass.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: Text(
        'The collection and wishlist on this device are replaced by those of the device that made the code. '
        "This can't be undone.",
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
            'Continue',
            style: TextStyle(color: accent, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Popup with a new sync code, and how long it's valid.
class _SyncCodeDialog extends StatelessWidget {
  final SyncCode code;
  final Color accent;

  const _SyncCodeDialog({required this.code, required this.accent});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return AlertDialog(
      backgroundColor: glass.sheet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Sync code',
        style: TextStyle(color: glass.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: glass.fill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: glass.edge),
            ),
            child: SelectableText(
              code.code,
              textAlign: TextAlign.center,
              style: TextStyle(color: glass.textPrimary, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 4),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This code is valid for ${_validFor(code.remaining)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: glass.textSecondary, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: accent)),
        ),
      ],
    );
  }
}

/// As "59:12", or "1:00:00" from an hour.
String _countdown(Duration left) {
  String two(int n) => n.toString().padLeft(2, '0');
  final minutes = two(left.inMinutes % 60);
  final seconds = two(left.inSeconds % 60);
  return left.inHours > 0 ? '${left.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

/// As "1 hour", "45 minutes" or "less than a minute", rounded to the nearest minute.
String _validFor(Duration left) {
  final minutes = (left.inSeconds / 60).round();
  if (minutes < 1) return 'less than a minute';
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hour' : '$hours hours';
  }
  return minutes == 1 ? '1 minute' : '$minutes minutes';
}
