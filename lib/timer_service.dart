import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String notifChannelId  = 'farm_timer_channel';
const int    notifFgId       = 888;
const int    notifCompleteId = 889;

// 서비스 초기화 (main에서 한 번 호출)
Future<void> initTimerService() async {
  final prefs = await SharedPreferences.getInstance();
  final service = FlutterBackgroundService();

  // 앱 시작 시 서비스가 돌고 있으면 강제 종료
  // (timer_running=false인데 서비스가 남아있는 경우 방지)
  if (await service.isRunning()) {
    final wasRunning = prefs.getBool('timer_running') ?? false;
    if (!wasRunning) {
      service.invoke('stop');
      await Future.delayed(const Duration(milliseconds: 300));
    }
  } else {
    // 서비스 없는데 timer_running=true면 상태 초기화
    await prefs.setBool('timer_running', false);
    await prefs.setInt('timer_remaining', 0);
  }
  final notifs = FlutterLocalNotificationsPlugin();

  await notifs.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await notifs
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
    const AndroidNotificationChannel(
      notifChannelId,
      '공부 타이머',
      description: '공부 타이머 백그라운드 실행',
      importance: Importance.low,
    ),
  );

  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _timerServiceMain,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: notifChannelId,
      initialNotificationTitle: '공부 중... 🔥',
      initialNotificationContent: '타이머 실행 중',
      foregroundServiceNotificationId: notifFgId,
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

// ── 서비스 시작 ──
Future<void> startTimerService(int totalSeconds, int remainingSeconds) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('timer_total', totalSeconds);
  await prefs.setInt('timer_remaining', remainingSeconds);
  await prefs.setBool('timer_running', true);
  await FlutterBackgroundService().startService();
}

// ── 서비스 중지 (일시정지/중지) ──
Future<void> stopTimerService() async {
  FlutterBackgroundService().invoke('stop');
}

// ── 서비스 실행 중 여부 ──
Future<bool> isTimerRunning() async {
  return FlutterBackgroundService().isRunning();
}

// ── 저장된 남은 시간 읽기 ──
Future<int> getSavedRemaining() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('timer_remaining') ?? 0;
}

// ── 백그라운드 엔트리포인트 ──
@pragma('vm:entry-point')
void _timerServiceMain(ServiceInstance service) async {
  final prefs = await SharedPreferences.getInstance();
  final notifs = FlutterLocalNotificationsPlugin();

  await notifs.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  int remaining = prefs.getInt('timer_remaining') ?? 0;
  final int total = prefs.getInt('timer_total') ?? remaining;

  Timer? timer;

  void updateNotification() {
    if (service is AndroidServiceInstance) {
      final m = remaining ~/ 60;
      final s = remaining % 60;
      service.setForegroundNotificationInfo(
        title: '공부 중... 🔥',
        content: '남은 시간: $m분 ${s.toString().padLeft(2, '0')}초',
      );
    }
  }

  // 즉시 UI에 현재 상태 전송
  service.invoke('timerTick', {'remaining': remaining, 'total': total});
  updateNotification();

  timer = Timer.periodic(const Duration(seconds: 1), (_) async {
    remaining--;
    await prefs.setInt('timer_remaining', remaining);

    if (remaining <= 0) {
      timer?.cancel();

      // 완료 알림
      await notifs.show(
        notifCompleteId,
        '🎉 타이머 완료!',
        '공부가 끝났어요! 수고했어요!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notifChannelId,
            '공부 타이머',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );

      service.invoke('timerComplete', {'total': total});
      await prefs.setBool('timer_running', false);
      await prefs.setInt('timer_remaining', 0);
      await prefs.setBool('timer_just_completed', true); // 완료 플래그
      await prefs.setInt('timer_completed_total', total);
      service.stopSelf();
      return;
    }

    service.invoke('timerTick', {'remaining': remaining, 'total': total});
    updateNotification();
  });

  // UI에서 중지 명령
  service.on('stop').listen((_) async {
    timer?.cancel();
    await prefs.setBool('timer_running', false);
    service.stopSelf();
  });
}