import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// Real-time audio waveform visualizer that responds to actual audio amplitude.
class WaveformVisualizer extends StatefulWidget {
  final double amplitude;
  final bool isActive;
  final int barCount;
  final double barWidth;
  final double maxHeight;

  const WaveformVisualizer({
    super.key,
    required this.amplitude,
    required this.isActive,
    this.barCount = 40,
    this.barWidth = 4,
    this.maxHeight = 80,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> {
  List<double> _barHeights = [];
  double _lastAmplitude = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize bar heights to minimum
    _barHeights = List.generate(widget.barCount, (_) => 0.1);
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset when recording stops
    if (!widget.isActive && oldWidget.isActive) {
      setState(() {
        _barHeights = List.generate(widget.barCount, (_) => 0.1);
        _lastAmplitude = 0.0;
      });
    }

    // Update bars when amplitude changes
    if (widget.isActive && widget.amplitude != _lastAmplitude) {
      _updateBarsFromAmplitude();
      _lastAmplitude = widget.amplitude;
    }
  }

  void _updateBarsFromAmplitude() {
    setState(() {
      // Shift existing bars to the left
      for (int i = 0; i < _barHeights.length - 1; i++) {
        _barHeights[i] = _barHeights[i + 1];
      }

      // Add new amplitude at the end - directly use the amplitude value
      // The amplitude from audio service is already 0.0-1.0
      final newHeight = widget.amplitude.clamp(0.1, 1.0);
      _barHeights[_barHeights.length - 1] = newHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          final height = _barHeights[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              width: widget.barWidth,
              height: math.max(4, height * widget.maxHeight),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.barWidth / 2),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.primary,
                    Color.lerp(AppTheme.primary, AppTheme.secondary, height)!,
                  ],
                ),
                boxShadow: widget.isActive && height > 0.3
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
