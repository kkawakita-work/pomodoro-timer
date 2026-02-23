import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_timer/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';

void main() {
  testWidgets('resetTimer should switch from Break mode to Focus mode', (WidgetTester tester) async {
    final timerService = TimerService();

    await tester.pumpWidget(
      ChangeNotifierProvider<TimerService>.value(
        value: timerService,
        child: const PomodoroApp(),
      ),
    );

    // Initial state
    expect(timerService.isFocusMode, true);
    expect(timerService.remainingSeconds, timerService.focusDuration);

    // Set a short focus duration to quickly switch to Break mode
    timerService.setFocusDuration(1);
    await tester.pump();

    // Start timer
    timerService.startTimer();
    await tester.pump(const Duration(seconds: 2)); // Wait for it to complete and switch

    // Now it should be in Break mode
    expect(timerService.isFocusMode, false, reason: 'Expected to be in Break mode after focus timer ends');

    // Call reset
    timerService.resetTimer();
    await tester.pump();

    // Verify it switched back to Focus mode
    // Note: Currently this is expected to FAIL until we apply the fix.
    // If we want it to pass now to verify the failure, we'd expect(timerService.isFocusMode, false);
    // But the goal is to define the DESIRED behavior.
    expect(timerService.isFocusMode, true, reason: 'Expected to return to Focus mode after reset');
    expect(timerService.remainingSeconds, timerService.focusDuration);
  });
}
