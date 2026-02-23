import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  static const Map<String, String> _ja = {
    'focus': '集中',
    'break': '休憩',
    'reset': 'リセット',
    'start': '開始',
    'stop': '停止',
    'settings': '設定',
    'settings_message': '集中時間と休憩時間を設定します',
    'focus_duration': '集中時間',
    'break_duration': '休憩時間',
    'cancel': 'キャンセル',
    'done': '完了',
  };

  static String get(String key) => _ja[key] ?? key;
}

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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ja', 'JP'),
        Locale('en', 'US'),
      ],
      home: HomeScreen(),
    );
  }
}

class TimerService extends ChangeNotifier {
  int _focusDuration = 1500; // 25 minutes
  int _breakDuration = 300;  // 5 minutes

  int get focusDuration => _focusDuration;
  int get breakDuration => _breakDuration;

  late int _remainingSeconds;
  bool _isRunning = false;

  TimerService() {
    _remainingSeconds = _focusDuration;
  }
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

  void setFocusDuration(int seconds) {
    _focusDuration = seconds;
    if (_isFocusMode && !_isRunning) {
      _remainingSeconds = _focusDuration;
    }
    notifyListeners();
  }

  void setBreakDuration(int seconds) {
    _breakDuration = seconds;
    if (!_isFocusMode && !_isRunning) {
      _remainingSeconds = _breakDuration;
    }
    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _isFocusMode = true;
    _remainingSeconds = _focusDuration;
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
    _remainingSeconds = _isFocusMode ? _focusDuration : _breakDuration;
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
    final statusColor = isFocus ? CupertinoColors.activeGreen : CupertinoColors.systemIndigo;
    
    // Calculate progress (0.0 to 1.0)
    // Calculate progress (0.0 to 1.0)
    // Progress starts at 0.0 and fills to 1.0 for both Focus and Break
    final totalDuration = isFocus ? timerService.focusDuration : timerService.breakDuration;
    final progress = 1.0 - (timerService.remainingSeconds / totalDuration);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 44), // Spacer to balance settings button
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
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.settings, color: CupertinoColors.systemGrey),
                    onPressed: () => _showSettings(context, timerService),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: CircularTimerPainter(
                        progress: progress,
                        color: statusColor,
                        backgroundColor: const Color(0xFF1C1C1E), // Dark gray for track
                        isFocusMode: isFocus,
                      ),
                      child: Center(
                        child: Text(
                          timerService.formattedTime,
                          style: const TextStyle(
                            fontSize: 80, 
                            fontWeight: FontWeight.w200, 
                            fontFeatures: [FontFeature.tabularFigures()], 
                            color: CupertinoColors.white,
                            fontFamily: '.SF Pro Display', 
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reset Button
                  _CupertinoTimerButton(
                    label: 'Reset',
                    icon: CupertinoIcons.arrow_counterclockwise,
                    color: CupertinoColors.systemGrey,
                    onPressed: timerService.resetTimer,
                  ),
                  
                  // Start/Stop Button
                  _CupertinoTimerButton(
                    label: timerService.isRunning ? 'Stop' : 'Start',
                    icon: timerService.isRunning ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                    color: timerService.isRunning ? const Color(0xFFFF3B30) : const Color(0xFF4CD964), // Red : Green
                    onPressed: timerService.isRunning ? timerService.stopTimer : timerService.startTimer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, TimerService timerService) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Localizations.override(
        context: context,
        locale: const Locale('ja', 'JP'),
        child: CupertinoActionSheet(
          title: Text(AppLocalizations.get('settings')),
          message: Text(AppLocalizations.get('settings_message')),
          actions: [
            CupertinoActionSheetAction(
              child: Text(AppLocalizations.get('focus_duration')),
              onPressed: () {
                Navigator.pop(context);
                _showDurationPicker(context, timerService, true);
              },
            ),
            CupertinoActionSheetAction(
              child: Text(AppLocalizations.get('break_duration')),
              onPressed: () {
                Navigator.pop(context);
                _showDurationPicker(context, timerService, false);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            child: Text(AppLocalizations.get('cancel')),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  void _showDurationPicker(BuildContext context, TimerService timerService, bool isFocus) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Localizations.override(
        context: context,
        locale: const Locale('ja', 'JP'),
        child: Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.ms,
                  initialTimerDuration: Duration(seconds: isFocus ? timerService.focusDuration : timerService.breakDuration),
                  onTimerDurationChanged: (duration) {
                    if (isFocus) {
                      timerService.setFocusDuration(duration.inSeconds);
                    } else {
                      timerService.setBreakDuration(duration.inSeconds);
                    }
                  },
                ),
              ),
              CupertinoButton(
                child: Text(AppLocalizations.get('done')),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final bool isFocusMode;

  CircularTimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.isFocusMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10; // Padding for stroke
    const strokeWidth = 15.0;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start at -90 degrees (12 o'clock)
    // Sweep matching progress * 2*pi
    // Direction depends on mode: Focus is clockwise, Break is counter-clockwise
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // -pi/2
      (isFocusMode ? 1 : -1) * 2 * 3.14159 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.isFocusMode != isFocusMode;
  }
}

class _CupertinoTimerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CupertinoTimerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
