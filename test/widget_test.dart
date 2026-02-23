import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_timer/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Timer starts at 25:00', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => TimerService(),
        child: const PomodoroApp(),
      ),
    );

    // Verify that our timer starts at 25:00.
    expect(find.text('25:00'), findsOneWidget);
  });

  testWidgets('Updating focus duration updates the timer display', (WidgetTester tester) async {
    final timerService = TimerService();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => timerService,
        child: const PomodoroApp(),
      ),
    );

    expect(find.text('25:00'), findsOneWidget);

    timerService.setFocusDuration(10 * 60); // 10 minutes
    await tester.pump();

    expect(find.text('10:00'), findsOneWidget);
  });
}
