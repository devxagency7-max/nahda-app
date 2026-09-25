import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class EditableDropdown extends StatefulWidget {
  final String label;
  final bool required;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool? allowOther;
  final String otherLabel;
  final String? hintText;

  const EditableDropdown({
    super.key,
    required this.label,
    this.required = false,
    required this.value,
    required this.options,
    required this.onChanged,
    this.allowOther,
    this.otherLabel = 'أخرى',
    this.hintText,
  });

  @override
  State<EditableDropdown> createState() => _EditableDropdownState();
}

class _EditableDropdownState extends State<EditableDropdown> {
  late final TextEditingController _customCtrl;
  late final FocusNode _focusNode;
  bool _isCustom = false;

  bool get _hasOtherOption =>
      widget.allowOther ?? widget.options.contains(widget.otherLabel);

  @override
  void initState() {
    super.initState();
    _customCtrl = TextEditingController();
    _focusNode = FocusNode();
    _determineInitialState();
  }

  void _determineInitialState() {
    if (_hasOtherOption && widget.value != null && widget.value!.isNotEmpty) {
      if (widget.value == widget.otherLabel) {
        _isCustom = true;
        _customCtrl.text = '';
      } else if (!widget.options.contains(widget.value)) {
        // Value is a custom entered string from previous input
        _isCustom = true;
        _customCtrl.text = widget.value!;
      }
    }
  }

  @override
  void didUpdateWidget(covariant EditableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (_hasOtherOption) {
        if (widget.value == widget.otherLabel) {
          if (!_isCustom) {
            setState(() {
              _isCustom = true;
              _customCtrl.text = '';
            });
          }
        } else if (widget.value != null &&
            widget.value!.isNotEmpty &&
            !widget.options.contains(widget.value)) {
          if (!_isCustom || _customCtrl.text != widget.value) {
            setState(() {
              _isCustom = true;
              _customCtrl.text = widget.value!;
            });
          }
        } else if (widget.value == null ||
            widget.options.contains(widget.value)) {
          if (_isCustom) {
            setState(() {
              _isCustom = false;
              _customCtrl.clear();
            });
          }
        }
      } else if (_isCustom) {
        setState(() {
          _isCustom = false;
          _customCtrl.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetToDropdown() {
    setState(() {
      _isCustom = false;
      _customCtrl.clear();
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final labelText = widget.label.isEmpty
        ? null
        : (widget.required ? '${widget.label} *' : widget.label);

    if (_isCustom) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: TextField(
          controller: _customCtrl,
          focusNode: _focusNode,
          textInputAction: TextInputAction.done,
          onChanged: (text) {
            final trimmed = text.trim();
            widget.onChanged(trimmed.isEmpty ? widget.otherLabel : trimmed);
          },
          decoration: InputDecoration(
            labelText: labelText != null
                ? '$labelText (أخرى / كتابة مخصصة)'
                : 'أخرى (كتابة مخصصة)',
            hintText: 'اكتب الاختيار المخصص هنا...',
            prefixIcon: const Icon(
              Icons.edit_note_rounded,
              size: 22,
              color: AppColors.primary,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.undo_rounded, size: 20),
              tooltip: 'الرجوع للقائمة المنسدلة',
              color: AppColors.primary,
              onPressed: _resetToDropdown,
            ),
          ),
        ),
      );
    }

    final dropdownValue =
        widget.value != null && widget.options.contains(widget.value)
            ? widget.value
            : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: DropdownButtonFormField<String>(
        key: ValueKey(dropdownValue),
        initialValue: dropdownValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: labelText,
          hintText:
              widget.hintText ?? (widget.label.isEmpty ? 'اختر...' : null),
        ),
        items: [
          for (final option in widget.options)
            DropdownMenuItem(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (val) {
          if (_hasOtherOption && val == widget.otherLabel) {
            setState(() {
              _isCustom = true;
              _customCtrl.text = '';
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _focusNode.requestFocus();
              }
            });
            widget.onChanged(widget.otherLabel);
          } else {
            widget.onChanged(val);
          }
        },
      ),
    );
  }
}
