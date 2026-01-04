import 'dart:io';
import 'package:flutter/material.dart';
import '../models/damage_detection_result.dart';

class ResultScreen extends StatelessWidget {
  final DamageDetectionResult result;
  final File imageFile;

  const ResultScreen({
    Key? key,
    required this.result,
    required this.imageFile,
  }) : super(key: key);

  Color _getUrgencyColor() {
    final urgency = result.damageDetails.urgency.toLowerCase();
    if (urgency.contains('critical') || urgency.contains('immediate')) {
      return Colors.red;
    } else if (urgency.contains('high')) {
      return Colors.orange;
    } else if (urgency.contains('medium')) {
      return Colors.yellow[700]!;
    } else {
      return Colors.green;
    }
  }

  IconData _getDamageIcon() {
    switch (result.damageType.toLowerCase()) {
      case 'dent':
        return Icons.circle_outlined;
      case 'scratch':
        return Icons.linear_scale;
      case 'crack':
        return Icons.broken_image;
      case 'glass shatter':
        return Icons.broken_image_outlined;
      case 'lamp broken':
        return Icons.lightbulb_outline;
      case 'tire flat':
        return Icons.tire_repair;
      default:
        return Icons.car_crash;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Damage Analysis'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image display
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black,
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Primary damage card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            _getDamageIcon(),
                            size: 64,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            result.damageType.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoChip(
                                'Confidence',
                                '${(result.confidence * 100).toStringAsFixed(1)}%',
                                Colors.blue,
                              ),
                              _buildInfoChip(
                                'Severity',
                                '${result.severityScore}/5',
                                Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Urgency banner
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _getUrgencyColor()),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: _getUrgencyColor()),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Urgency Level',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(result.damageDetails.urgency),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description section
                  _buildSection(
                    'Description',
                    Icons.description,
                    result.damageDetails.description,
                  ),

                  const SizedBox(height: 20),

                  // What happened section
                  _buildSection(
                    'What Happened',
                    Icons.help_outline,
                    result.damageDetails.whatHappened,
                  ),

                  const SizedBox(height: 20),

                  // Immediate actions
                  _buildListSection(
                    'Immediate Actions',
                    Icons.flash_on,
                    result.damageDetails.immediateActions,
                    Colors.red,
                  ),

                  const SizedBox(height: 20),

                  // Repair options
                  _buildListSection(
                    'Repair Options',
                    Icons.build,
                    result.damageDetails.repairOptions,
                    Colors.blue,
                  ),

                  const SizedBox(height: 20),

                  // Estimated time
                  _buildInfoRow(
                    'Estimated Repair Time',
                    result.damageDetails.estimatedTime,
                    Icons.access_time,
                  ),

                  const SizedBox(height: 20),

                  // Prevention tips
                  _buildSection(
                    'Prevention Tips',
                    Icons.lightbulb_outline,
                    result.damageDetails.preventionTips,
                  ),

                  // Additional detected damages
                  if (result.detectedDamages.length > 1) ...[
                    const SizedBox(height: 20),
                    _buildAdditionalDamages(),
                  ],

                  const SizedBox(height: 30),

                  // Back button
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Analyze Another Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(
    String title,
    IconData icon,
    List<String> items,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}. ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDamages() {
    final otherDamages = result.detectedDamages
        .where((d) => d != result.damageType)
        .toList();

    if (otherDamages.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 10),
            Text(
              'Additional Damages Detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: otherDamages
              .map(
                (damage) => Chip(
                  label: Text(damage.toUpperCase()),
                  backgroundColor: Colors.orange[100],
                  side: BorderSide(color: Colors.orange[300]!),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
