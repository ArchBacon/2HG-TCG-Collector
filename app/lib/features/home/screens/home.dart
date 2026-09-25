import 'package:app/features/home/widgets/collection_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/identity/token.dart';

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(storedTokenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('TCG Collector')),
      body: Column(
        children: [
          Column(
            children: [
              // Total collection value
              CollectionValue(
                  value: 3896.20,
                  collected: 263,
                  wishlisted: 14
              ),
              // TODO: TCG game selection list
            ],
          )
        ],
      ),
    );
  }
}
