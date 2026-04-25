import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HandoverScreen extends StatelessWidget {
  const HandoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Handover'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandoverItem(
              context,
              'Resident Safety',
              'All residents are stable. No falls reported in the last 12 hours.',
              Icons.security,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildHandoverItem(
              context,
              'Priority Engagements',
              'Alice Smith is feeling energetic today. Suggest "Gardening" or "Watering Plants" activities.',
              Icons.star,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildHandoverItem(
              context,
              'Facility Updates',
              'Lunch will be served in the courtyard today due to pleasant weather.',
              Icons.info_outline,
              AppTheme.primaryColor,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Acknowledge Handover'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandoverItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description),
          ],
        ),
      ),
    );
  }
}
