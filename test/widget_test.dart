import 'package:flutter_test/flutter_test.dart';
import 'package:conversa_voice_app/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ConversaVoiceApp());
    // HomeScreen should show "ConversaVoice" text
    expect(find.text('ConversaVoice'), findsOneWidget);
  });
}
