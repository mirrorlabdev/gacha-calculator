import 'package:flutter/material.dart';
import '../utils/themes.dart';

class GachaInputField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final GachaTheme theme;
  final bool enabled;
  final bool noBorder;

  const GachaInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    required this.theme,
    this.enabled = true,
    this.noBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          enabled: enabled,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? theme.text : theme.textDim,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? theme.bgInput : theme.bgCard,
            border: noBorder
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.border),
                  ),
            enabledBorder: noBorder
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.border),
                  ),
            disabledBorder: noBorder
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.border),
                  ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
