import 'package:flutter/material.dart';
import '../utils/themes.dart';
import 'chunked_text.dart';

// 범위 조정 결과 (message는 청크 배열)
class RangeAdjustResult {
  final bool wasAdjusted;
  final List<String>? message;  // 한글 줄바꿈 최적화를 위한 청크 배열
  final String correctedValue;

  const RangeAdjustResult({
    required this.wasAdjusted,
    this.message,
    required this.correctedValue,
  });
}

class GachaInputField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final GachaTheme theme;
  final bool enabled;
  final bool noBorder;
  final RangeAdjustResult Function(String value)? onValidate;  // 범위 검증 콜백

  const GachaInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    required this.theme,
    this.enabled = true,
    this.noBorder = false,
    this.onValidate,
  });

  @override
  State<GachaInputField> createState() => _GachaInputFieldState();
}

class _GachaInputFieldState extends State<GachaInputField> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(GachaInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 포커스가 없을 때만 외부 값으로 업데이트
    if (!_hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: widget.theme.text,
          ),
        ),
        const SizedBox(height: 6),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _hasFocus = hasFocus);
            // 포커스를 잃을 때 범위 검증
            if (!hasFocus && widget.onValidate != null) {
              final result = widget.onValidate!(_controller.text);
              if (result.wasAdjusted) {
                _controller.text = result.correctedValue;
                widget.onChanged(result.correctedValue);
                if (result.message != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: ChunkedText(chunks: result.message!),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }
          },
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: TextStyle(
              fontSize: 16,
              color: widget.enabled ? widget.theme.text : widget.theme.textDim,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.enabled ? widget.theme.bgInput : widget.theme.bgCard,
              border: widget.noBorder
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.theme.border),
                    ),
              enabledBorder: widget.noBorder
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.theme.border),
                    ),
              disabledBorder: widget.noBorder
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.theme.border),
                    ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
