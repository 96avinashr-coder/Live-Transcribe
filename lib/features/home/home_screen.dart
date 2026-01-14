import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/transcription_provider.dart';
import '../settings/settings_screen.dart';
import 'widgets/recording_button.dart';
import 'widgets/transcript_view.dart';
import 'widgets/waveform_visualizer.dart';
import '../history/history_screen.dart';

/// Main home screen for live transcription.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Live Transcribe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _openSettings(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Consumer<TranscriptionProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  // Error banner
                  if (provider.error != null)
                    _ErrorBanner(error: provider.error!),

                  // API key status indicator
                  _ApiKeyIndicator(provider: provider),

                  // Waveform visualizer
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing24,
                      vertical: AppTheme.spacing16,
                    ),
                    child: WaveformVisualizer(
                      amplitude: provider.amplitude,
                      isActive: provider.isRecording,
                    ),
                  ),

                  // Transcript display
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                      ),
                      child: TranscriptView(
                        finalTranscript: provider.fullTranscript,
                        partialTranscript: provider.partialTranscript,
                        isRecording: provider.isRecording,
                      ),
                    ),
                  ),

                  // Bottom controls
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing24),
                    child: Column(
                      children: [
                        // Record button
                        RecordingButton(
                          isRecording: provider.isRecording,
                          isEnabled: provider.hasApiKeys,
                          onPressed: () => _toggleRecording(context, provider),
                        ),

                        const SizedBox(height: AppTheme.spacing16),

                        // Clear button (when not recording and has transcript)
                        if (!provider.isRecording &&
                            provider.fullTranscript.isNotEmpty)
                          TextButton.icon(
                            onPressed: () =>
                                _clearTranscript(context, provider),
                            icon: const Icon(Icons.clear_rounded),
                            label: const Text('Clear Transcript'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                            ),
                          ),

                        // Add API key prompt (when no keys)
                        if (!provider.hasApiKeys)
                          TextButton.icon(
                            onPressed: () => _openSettings(context),
                            icon: const Icon(Icons.key_rounded),
                            label: const Text('Add API Key to Start'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.warning,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  Future<void> _toggleRecording(
    BuildContext context,
    TranscriptionProvider provider,
  ) async {
    HapticFeedback.mediumImpact();
    if (provider.isRecording) {
      await provider.stopSession();
    } else {
      await provider.startSession();
    }
  }

  void _clearTranscript(BuildContext context, TranscriptionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text('Clear Transcript?'),
        content: const Text(
          'This will remove all transcribed text. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearTranscript();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// Error banner displayed at the top of the screen.
class _ErrorBanner extends StatelessWidget {
  final String error;

  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      margin: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// API key status indicator.
class _ApiKeyIndicator extends StatelessWidget {
  final TranscriptionProvider provider;

  const _ApiKeyIndicator({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (!provider.hasApiKeys) return const SizedBox.shrink();

    final keyService = provider.apiKeyService;
    final currentKey = keyService.currentKey;
    final maskedKey = currentKey != null
        ? '••••${currentKey.substring(currentKey.length - 4.clamp(0, currentKey.length))}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: provider.isConnected
                    ? AppTheme.success
                    : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              'Key ${keyService.currentIndex + 1}/${keyService.keyCount}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              maskedKey,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
