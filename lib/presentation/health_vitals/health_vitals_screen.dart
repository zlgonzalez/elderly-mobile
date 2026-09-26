import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/vital_sign.dart';
import '../family_portal/resident_provider.dart';
import '../shared/resident_header.dart';
import '../shared/ask_kubo_floating_button.dart';
import 'health_vitals_provider.dart';
import 'widgets/meal_tracker_widget.dart';
import 'widgets/record_vitals_form.dart';

class HealthVitalsScreen extends ConsumerWidget {
  final VoidCallback? onAskKuboTap;

  const HealthVitalsScreen({super.key, this.onAskKuboTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider);
    final vitalsState = ref.watch(healthVitalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Resident Switch Header
            const ResidentHeader(activeTabIndex: 4),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Conditions & Allergies Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.health_and_safety_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Medical Profile & Warnings',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Conditions
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...resident.conditions.map((cond) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Text(
                                    cond,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }),
                              // Allergies
                              ...resident.allergies.map((allergy) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.allergyRedBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.allergyRed.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    allergy,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.allergyRed,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Physical State Logger (Record Vitals Form)
                    const RecordVitalsForm(),
                    const SizedBox(height: 16),

                    // Meal Logger (Nutrition & Meals)
                    const MealTrackerWidget(),
                    const SizedBox(height: 16),

                    // Recent Vitals Log Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Recent Vitals History',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                '${vitalsState.vitals.length} records',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (vitalsState.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (vitalsState.vitals.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('No vitals recorded yet.', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: vitalsState.vitals.length,
                              separatorBuilder: (_, __) => const Divider(height: 20, color: AppColors.borderLight),
                              itemBuilder: (context, idx) {
                                final item = vitalsState.vitals[idx];
                                return _buildVitalRecordRow(context, item);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
      floatingActionButton: AskKuboFloatingButton(
        onPressed: onAskKuboTap,
        contextScreen: 'Health & Vitals',
      ),
    );
  }

  Widget _buildVitalRecordRow(BuildContext context, VitalSign item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${item.timestamp.year}-${item.timestamp.month.toString().padLeft(2, '0')}-${item.timestamp.day.toString().padLeft(2, '0')} ${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Spacer(),
            Text(
              'By ${item.recordedBy}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _buildMetricPill('BP', item.bloodPressure),
            _buildMetricPill('Heart Rate', '${item.heartRate} BPM'),
            _buildMetricPill('Temp', '${item.temperature} °F'),
            if (item.weight != null) _buildMetricPill('Weight', '${item.weight} lbs'),
            if (item.mobilityLevel != null) _buildMetricPill('Mobility', item.mobilityLevel!),
            _buildMetricPill('Pain', '${item.painLevel}/10'),
          ],
        ),
        if (item.clinicalNotes != null && item.clinicalNotes!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '"${item.clinicalNotes}"',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
