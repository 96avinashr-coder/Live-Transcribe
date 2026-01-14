import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// Live transcript display with auto-scroll and partial result highlighting.
class TranscriptView extends StatefulWidget {
  final String finalTranscript;
  final String partialTranscript;
  final bool isRecording;

  const TranscriptView({
    super.key,
    required this.finalTranscript,
    required this.partialTranscript,
    required this.isRecording,
  });

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(TranscriptView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new text arrives
    if (widget.finalTranscript != oldWidget.finalTranscript ||
        widget.partialTranscript != oldWidget.partialTranscript) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppTheme.animationFast,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent =
        widget.finalTranscript.isNotEmpty ||
        widget.partialTranscript.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: hasContent
          ? SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    color: AppTheme.textPrimary,
                  ),
                  children: [
                    // Final transcript
                    TextSpan(text: widget.finalTranscript),
                    // Space between final and partial
                    if (widget.finalTranscript.isNotEmpty &&
                        widget.partialTranscript.isNotEmpty)
                      const TextSpan(text: ' '),
                    // Partial transcript (highlighted)
                    if (widget.partialTranscript.isNotEmpty)
                      TextSpan(
                        text: widget.partialTranscript,
                        style: TextStyle(
                          color: AppTheme.secondary.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    // Blinking cursor when recording
                    if (widget.isRecording)
                      WidgetSpan(child: _BlinkingCursor()),
                  ],
                ),
              ),
            )
          : _EmptyState(isRecording: widget.isRecording),
    );
  }
}

/// Empty state placeholder for the transcript view.
class _EmptyState extends StatelessWidget {
  final bool isRecording;

  const _EmptyState({required this.isRecording});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRecording ? Icons.hearing : Icons.mic_none_rounded,
            size: 48,
            color: AppTheme.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            isRecording
                ? 'Listening...'
                : 'Tap the microphone to start transcribing',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Blinking cursor indicator.
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _animation,
      builder: (context, child) {
        return Container(
          width: 2,
          height: 18,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      },
    );
  }
}
