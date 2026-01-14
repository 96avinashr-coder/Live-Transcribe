import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/transcription_provider.dart';
import '../../core/services/api_key_service.dart';

/// Settings screen for managing API keys.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Consumer<TranscriptionProvider>(
            builder: (context, provider, child) {
              final keyService = provider.apiKeyService;

              return ListView(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                children: [
                  // API Keys Section
                  _SectionHeader(
                    title: 'API Keys',
                    subtitle:
                        'Add your AssemblyAI API keys. Keys rotate per session.',
                  ),
                  const SizedBox(height: AppTheme.spacing16),

                  // Add new key input
                  _AddKeyCard(
                    controller: _keyController,
                    onAdd: () => _addKey(provider),
                  ),

                  const SizedBox(height: AppTheme.spacing24),

                  // Key list
                  if (keyService.apiKeys.isNotEmpty) ...[
                    Text(
                      'Saved Keys (${keyService.keyCount})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    ...List.generate(
                      keyService.apiKeys.length,
                      (index) => _ApiKeyCard(
                        index: index,
                        apiKey: keyService.apiKeys[index],
                        isActive: index == keyService.currentIndex,
                        onDelete: () => _deleteKey(provider, index),
                      ),
                    ),
                  ] else
                    _EmptyKeysCard(),

                  const SizedBox(height: AppTheme.spacing32),

                  // Info section
                  _InfoCard(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _addKey(TranscriptionProvider provider) async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      _showSnackBar('Please enter an API key');
      return;
    }

    await provider.addApiKey(key);
    _keyController.clear();
    _showSnackBar('API key added successfully');
  }

  Future<void> _deleteKey(TranscriptionProvider provider, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text('Remove API Key?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.removeApiKey(index);
      _showSnackBar('API key removed');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }
}

/// Section header with title and subtitle.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppTheme.spacing4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Card for adding new API key.
class _AddKeyCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _AddKeyCard({required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add New Key', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacing12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter your AssemblyAI API key',
              prefixIcon: Icon(Icons.key_rounded),
            ),
            obscureText: true,
            onSubmitted: (_) => onAdd(),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Key'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card displaying an API key with delete option.
class _ApiKeyCard extends StatelessWidget {
  final int index;
  final String apiKey;
  final bool isActive;
  final VoidCallback onDelete;

  const _ApiKeyCard({
    required this.index,
    required this.apiKey,
    required this.isActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final maskedKey = ApiKeyService.maskKey(apiKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.5)
                : AppTheme.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Index badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppTheme.spacing12),

            // Key info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maskedKey,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontFamily: 'monospace'),
                  ),
                  if (isActive)
                    Text(
                      'Next in rotation',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.primary),
                    ),
                ],
              ),
            ),

            // Copy button
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: apiKey));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('API key copied'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                );
              },
              color: AppTheme.textMuted,
              tooltip: 'Copy key',
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: onDelete,
              color: AppTheme.error,
              tooltip: 'Remove key',
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when no keys are added.
class _EmptyKeysCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        children: [
          Icon(
            Icons.key_off_rounded,
            size: 48,
            color: AppTheme.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'No API keys added yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Add your AssemblyAI API key above to start transcribing.',
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

/// Info card about API keys and free tier.
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      backgroundColor: AppTheme.primary,
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.secondary),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'About API Keys',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            '• Get your free API key at assemblyai.com\n'
            '• Free tier includes 333 hours of real-time transcription\n'
            '• Add multiple keys to extend your free usage\n'
            '• Keys automatically rotate with each new session',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
