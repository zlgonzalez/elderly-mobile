import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../family_portal/resident_provider.dart';
import 'auth_provider.dart';

class DemoLoginScreen extends ConsumerWidget {
  const DemoLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(
                        Icons.spa,
                        size: 34,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kubo North',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Family care for your loved one',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Select a Demo Family Circle:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Dynamic Demo Accounts from Microservice
                  ref.watch(demoAccountsProvider).when(
                        data: (accounts) {
                          // Display family accounts first, then caregiver
                          return Column(
                            children: accounts.map((acc) {
                              final title = acc.role == 'caregiver'
                                  ? "${acc.fullName} (${acc.relation})"
                                  : "${acc.residentName.split(' ').first}'s family";
                              final details = acc.role == 'caregiver'
                                  ? "${acc.fullName} · Visiting Caregiver"
                                  : "${acc.fullName} (${acc.relation}) · ${acc.residentName.split(' ').first} (Age ${acc.residentAge})";

                              return _buildProfileCard(
                                context: context,
                                residentName: title,
                                username: acc.username,
                                details: details,
                                avatarUrl: acc.avatarUrl,
                                tag: acc.tag,
                                onTap: () async {
                                  final success = await ref
                                      .read(authProvider.notifier)
                                      .selectDemoProfile(acc.id);
                                  if (success) {
                                    await ref
                                        .read(residentProvider.notifier)
                                        .selectById(acc.linkedResidentId);
                                    if (context.mounted) {
                                      context.go('/portal');
                                    }
                                  }
                                },
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) => Column(
                          children: [
                            _buildProfileCard(
                              context: context,
                              residentName: "Margaret's family",
                              username: 'sarah.thompson',
                              details: 'Sarah Thompson (Daughter) · Margaret (Age 82)',
                              tag: 'Primary Demo',
                              onTap: () async {
                                final success = await ref
                                    .read(authProvider.notifier)
                                    .selectDemoProfile('user_sarah');
                                if (success) {
                                  await ref
                                      .read(residentProvider.notifier)
                                      .selectById('res_margaret');
                                  if (context.mounted) {
                                    context.go('/portal');
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                  const SizedBox(height: 20),
                  if (authState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    OutlinedButton.icon(
                      onPressed: () => context.push('/login'),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Username & Password'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required String residentName,
    required String username,
    required String details,
    String? avatarUrl,
    String? tag,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: (avatarUrl != null &&
                          avatarUrl.isNotEmpty &&
                          avatarUrl.startsWith('http'))
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null ||
                          avatarUrl.isEmpty ||
                          !avatarUrl.startsWith('http'))
                      ? Text(
                          residentName.substring(0, 1),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            residentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (tag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
