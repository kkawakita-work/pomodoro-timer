import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TimerService(),
      child: const PomodoroApp(),
    ),
  );
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple Pomodoro',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CupertinoColors.black,
        primaryColor: CupertinoColors.white,
      ),
      home: HomeScreen(),
    );
  }
}

class TimerService extends ChangeNotifier {
  static const int focusDuration = 25 * 60;
  static const int breakDuration = 5 * 60;

  int _remainingSeconds = focusDuration;
  bool _isRunning = false;
  bool _isFocusMode = true;
  Timer? _timer;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isFocusMode => _isFocusMode;

  void startTimer() {
    if (_timer != null || _remainingSeconds <= 0) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _handleTimerComplete();
      }
    });
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _remainingSeconds = _isFocusMode ? focusDuration : breakDuration;
    notifyListeners();
  }

  void _handleTimerComplete() {
    stopTimer();
    _vibrate();
    _switchMode();
    startTimer(); 
  }

  void _switchMode() {
    _isFocusMode = !_isFocusMode;
    _remainingSeconds = _isFocusMode ? focusDuration : breakDuration;
    notifyListeners();
  }

  Future<void> _vibrate() async {
    bool canVibrate = await Vibrate.canVibrate;
    if (canVibrate) {
      Vibrate.feedback(FeedbackType.heavy);
    }
  }

  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);
    final isFocus = timerService.isFocusMode;
    // iOS Colors for status
    final statusColor = isFocus ? CupertinoColors.activeGreen : CupertinoColors.systemIndigo;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Status Indicator (Subtle pill at top)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Icon(
                    isFocus ? CupertinoIcons.bolt_fill : CupertinoIcons.moon_fill, 
                    size: 14, 
                    color: statusColor
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFocus ? 'FOCUS' : 'BREAK',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Timer Display
            Text(
              timerService.formattedTime,
              style: const TextStyle(
                fontSize: 100, // Slightly smaller to ensure fit
                fontWeight: FontWeight.w100, // Ultra thin iOS style
                fontFeatures: [FontFeature.tabularFigures()], 
                color: CupertinoColors.white,
                fontFamily: '.SF Pro Display', // San Francisco (iOS default usually) or fallback
              ),
            ),
            const Spacer(),
            // Controls - iOS Timer Style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reset Button (Left)
                  _CupertinoTimerButton(
                    label: 'Reset',
                    textColor: CupertinoColors.systemGrey, // Light Grey Text
                    backgroundColor: const Color(0xFF333333), // Dark Grey BG
                    onPressed: timerService.resetTimer,
                  ),
                  
                  // Start/Stop Button (Right)
                  if (!timerService.isRunning)
                    _CupertinoTimerButton(
                      label: 'Start',
                      textColor: const Color(0xFF4CD964), // Bright Green Text
                      backgroundColor: const Color(0xFF1B381F), // Dark Green BG
                      onPressed: timerService.startTimer,
                    )
                  else
                    _CupertinoTimerButton(
                      label: 'Stop',
                      textColor: const Color(0xFFFF3B30), // Bright Red Text
                      backgroundColor: const Color(0xFF3B1716), // Dark Red BG
                      onPressed: timerService.stopTimer,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _CupertinoTimerButton extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _CupertinoTimerButton({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // iOS Timer buttons are huge circles (~80px diameter)
    // We use a Container with GestureDetector for custom touch feel
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          // Inner circle border effect (sometimes seen) or just clean
          border: Border.all(
            color: backgroundColor, // Match BG for cleaner look, or slight contrast
            width: 2,
          ),
        ),
        child: Container(
             decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CupertinoColors.black, width: 2), // The "double circle" effect
             ),
             alignment: Alignment.center,
             child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
        ),
      ),
    );
  }
}
