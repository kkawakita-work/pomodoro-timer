import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_timer/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Timer starts at 00:30', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => TimerService(),
        child: const PomodoroApp(),
      ),
    );

    // Verify that our timer starts at 00:30.
    expect(find.text('00:30'), findsOneWidget);
  });
}
