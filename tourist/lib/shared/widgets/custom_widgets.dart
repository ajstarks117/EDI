import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/ui_constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.08,
    this.color = Colors.white,
    this.borderRadius = UiConstants.radiusMD,
    this.padding = const EdgeInsets.all(UiConstants.spaceMD),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primary;
    final fg = textColor ?? Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.radiusMD),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.buttonText.copyWith(color: fg),
              ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final int maxLines;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      style: AppTextStyles.bodyText,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: AppTextStyles.caption,
        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText.withValues(alpha: 0.6)),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.safetyTeal)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UiConstants.spaceMD,
          vertical: UiConstants.spaceMD,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusSM),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusSM),
          borderSide: BorderSide(color: Colors.grey.shade100, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusSM),
          borderSide: const BorderSide(color: AppColors.safetyTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusSM),
          borderSide: const BorderSide(color: AppColors.alertRed, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusSM),
          borderSide: const BorderSide(color: AppColors.alertRed, width: 1.5),
        ),
      ),
    );
  }
}

class CountryCodePicker extends StatelessWidget {
  final String selectedCode;
  final ValueChanged<String> onChanged;

  static const List<Map<String, String>> _countries = [
    {'code': '+91', 'name': 'India (🇮🇳)'},
    {'code': '+1', 'name': 'USA (🇺🇸)'},
    {'code': '+44', 'name': 'UK (🇬🇧)'},
    {'code': '+61', 'name': 'Australia (🇦🇺)'},
    {'code': '+65', 'name': 'Singapore (🇸🇬)'},
    {'code': '+977', 'name': 'Nepal (🇳🇵)'},
  ];

  const CountryCodePicker({
    super.key,
    required this.selectedCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.spaceSM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UiConstants.radiusSM),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCode,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.safetyTeal),
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          items: _countries.map((c) {
            return DropdownMenuItem<String>(
              value: c['code'],
              child: Text(c['code']!),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ProfileStepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ProfileStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            height: 6.0,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.successGreen
                  : isCurrent
                      ? AppColors.safetyTeal
                      : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3.0),
            ),
          ),
        );
      }),
    );
  }
}

class EmergencyContactInputCard extends StatelessWidget {
  final int index;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController relationController;
  final VoidCallback? onRemove;

  const EmergencyContactInputCard({
    super.key,
    required this.index,
    required this.nameController,
    required this.phoneController,
    required this.relationController,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiConstants.radiusSM),
        side: BorderSide(color: Colors.grey.shade200, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emergency Contact #${index + 1}',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.alertRed, size: 20),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: UiConstants.spaceSM),
            AppTextField(
              controller: nameController,
              labelText: 'Full Name',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: UiConstants.spaceSM),
            AppTextField(
              controller: phoneController,
              labelText: 'Phone Number',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: UiConstants.spaceSM),
            AppTextField(
              controller: relationController,
              labelText: 'Relation (e.g. Spouse, Parent)',
              prefixIcon: Icons.family_restroom_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.35),
            child: const Center(
              child: GlassCard(
                blur: 10,
                opacity: 0.15,
                borderRadius: UiConstants.radiusSM,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
