import 'dart:ui';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class AppFormWizard extends StatelessWidget {
  const AppFormWizard({
    super.key,
    required this.currentStep,
    required this.steps,
    required this.onStepTapped,
  });

  final int currentStep;
  final List<String> steps;
  final ValueChanged<int> onStepTapped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Connecting Line
          Positioned(
            left: 40,
            right: 40,
            top: 20,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.1),
                    cs.primary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (currentStep / (steps.length - 1)).clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary,
                        cs.primaryFixedDim ?? cs.primary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Steps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final isActive = index <= currentStep;
              final isCurrent = index == currentStep;
              
              return GestureDetector(
                onTap: () => onStepTapped(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCurrent 
                            ? cs.primary 
                            : (isActive ? cs.primary.withValues(alpha: 0.8) : cs.surface),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? cs.primary : cs.outlineVariant,
                          width: 2,
                        ),
                        boxShadow: isCurrent ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ] : [],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isActive && !isCurrent
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                              : Text(
                                  '${index + 1}',
                                  key: ValueKey(index),
                                  style: TextStyle(
                                    color: isActive ? Colors.white : cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                        color: isCurrent ? cs.primary : cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class AppFormInputField extends StatefulWidget {
  const AppFormInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.readOnly = false,
    this.prefix,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool readOnly;
  final Widget? prefix;
  final int maxLines;

  @override
  State<AppFormInputField> createState() => _AppFormInputFieldState();
}

class _AppFormInputFieldState extends State<AppFormInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (!_focusNode.hasFocus) {
        _validate();
      }
    });
  }

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasError = _errorText != null;
    final isValid = _errorText == null && widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
              color: hasError ? cs.error : (_isFocused ? cs.primary : cs.onSurfaceVariant),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: AppRadii.r16,
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: (hasError ? cs.error : (isValid ? Colors.green : cs.primary)).withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            validator: widget.validator,
            onChanged: (v) {
              if (hasError) _validate();
              widget.onChanged?.call(v);
            },
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: Icon(
                widget.icon,
                size: 20,
                color: hasError ? cs.error : (_isFocused ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.7)),
              ),
              suffixIcon: isValid && !hasError
                  ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                  : (hasError ? const Icon(Icons.error_rounded, color: Colors.red, size: 20) : null),
              filled: true,
              fillColor: _isFocused ? cs.surface : cs.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: AppRadii.r16,
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.r16,
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.r16,
                borderSide: BorderSide(
                  color: hasError ? cs.error : (isValid ? Colors.green : cs.primary),
                  width: 2,
                ),
              ),
              errorStyle: const TextStyle(height: 0), // Hide default error text to use custom
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6),
            child: Text(
              _errorText!,
              style: TextStyle(color: cs.error, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
