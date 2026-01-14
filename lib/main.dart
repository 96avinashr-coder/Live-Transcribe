import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme/app_theme.dart';
import 'core/providers/transcription_provider.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const LiveTranscribeApp());
}

class LiveTranscribeApp extends StatelessWidget {
  const LiveTranscribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TranscriptionProvider()..initialize(),
      child: MaterialApp(
        title: 'Live Transcribe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}
