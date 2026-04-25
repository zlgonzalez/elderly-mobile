import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'residents_provider.dart';

class ResidentsListScreen extends ConsumerWidget {
  const ResidentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residentsAsync = ref.watch(residentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Residents'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search residents...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: residentsAsync.when(
        data: (residents) => ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: residents.length,
          itemBuilder: (context, index) {
            final resident = residents[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withAlpha(26),
                  child: Text(
                    '${resident.firstName[0]}${resident.lastName[0]}',
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text('${resident.firstName} ${resident.lastName}'),
                subtitle: Text('Room ${resident.roomNumber} • ${resident.careLevel} Care'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/residents/${resident.remoteId}'),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
