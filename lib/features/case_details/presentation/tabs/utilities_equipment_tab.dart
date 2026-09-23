import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/utilities_equipment_form.dart';
import '../widgets/section_card.dart';
import '../widgets/tab_progress_bar.dart';

/// تاب المرافق والتجهيزات — قابل للتعديل، القسم 11+12 من Case Data Master.
/// نُقل لآخر ترتيب التابات حسب طلب المستخدم.
class UtilitiesEquipmentTab extends StatefulWidget {
  final UtilitiesEquipmentFormData initialData;
  final ValueChanged<UtilitiesEquipmentFormData> onChanged;

  const UtilitiesEquipmentTab({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<UtilitiesEquipmentTab> createState() => _UtilitiesEquipmentTabState();
}

class _UtilitiesEquipmentTabState extends State<UtilitiesEquipmentTab> {
  late final UtilitiesEquipmentFormData _data = widget.initialData;

  void _notify() => widget.onChanged(_data);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabProgressBar(progress: _data.progress),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              const Text(
                'المرافق',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final u in _data.utilities) ...[
                _UtilityTile(
                  item: u,
                  onChanged: () {
                    setState(() {});
                    _notify();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'الأجهزة والممتلكات',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final e in _data.equipment) ...[
                _EquipmentTile(
                  item: e,
                  onChanged: () {
                    setState(() {});
                    _notify();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UtilityTile extends StatelessWidget {
  final UtilityItemFormData item;
  final VoidCallback onChanged;

  const _UtilityTile({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Switch(
            value: item.isAvailable,
            onChanged: (v) {
              item.isAvailable = v;
              onChanged();
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  final EquipmentItemFormData item;
  final VoidCallback onChanged;

  const _EquipmentTile({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Checkbox(
            value: item.isPresent,
            onChanged: (v) {
              item.isPresent = v ?? false;
              onChanged();
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
