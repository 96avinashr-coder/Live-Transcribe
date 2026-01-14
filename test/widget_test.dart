// Basic widget test for Live Transcribe app

import 'package:flutter_test/flutter_test.dart';
import 'package:live_transcribe/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LiveTranscribeApp());
    await tester.pump();

    // Verify that the app title is displayed
    expect(find.text('Live Transcribe'), findsOneWidget);
  });
}
