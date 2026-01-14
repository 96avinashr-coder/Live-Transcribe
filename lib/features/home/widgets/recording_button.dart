import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_theme.dart';

/// Animated recording button with pulse effect and gradient border.
class RecordingButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onPressed;
  final bool isEnabled;

  const RecordingButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(RecordingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat(reverse: true);
        _rotationController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEnabled
          ? () {
              HapticFeedback.mediumImpact();
              widget.onPressed();
            }
          : null,
      child: ListenableBuilder(
        listenable: Listenable.merge([_pulseController, _rotationController]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring (only when recording)
              if (widget.isRecording)
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),

              // Gradient border ring
              Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.isRecording
                        ? const SweepGradient(
                            colors: [
                              AppTheme.error,
                              AppTheme.accent,
                              AppTheme.error,
                            ],
                          )
                        : const SweepGradient(
                            colors: [
                              AppTheme.primary,
                              AppTheme.secondary,
                              AppTheme.primary,
                            ],
                          ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surface,
                      ),
                    ),
                  ),
                ),
              ),

              // Inner button
              Transform.scale(
                scale: widget.isRecording ? _scaleAnimation.value : 1.0,
                child: AnimatedContainer(
                  duration: AppTheme.animationNormal,
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.isRecording
                        ? const LinearGradient(
                            colors: [AppTheme.error, AppTheme.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (widget.isRecording
                                    ? AppTheme.error
                                    : AppTheme.primary)
                                .withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: AppTheme.textPrimary,
                    size: 32,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
