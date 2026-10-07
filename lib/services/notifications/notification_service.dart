import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreference {
  const NotificationPreference({
    this.enabled = false,
    this.conversationReminders = true,
    this.dateBriefings = true,
    this.insights = true,
  });

  final bool enabled;
  final bool conversationReminders;
  final bool dateBriefings;
  final bool insights;

  NotificationPreference copyWith({
    bool? enabled,
    bool? conversationReminders,
    bool? dateBriefings,
    bool? insights,
  }) {
    return NotificationPreference(
      enabled: enabled ?? this.enabled,
      conversationReminders:
          conversationReminders ?? this.conversationReminders,
      dateBriefings: dateBriefings ?? this.dateBriefings,
      insights: insights ?? this.insights,
    );
  }
}

abstract class NotificationService {
  Future<NotificationPreference> preferences();
  Future<NotificationPreference> update(NotificationPreference prefs);
  Future<bool> requestPermission();
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService(this._prefs);

  final SharedPreferences _prefs;
  static const _keyEnabled = 'notif_enabled';
  static const _keyReminders = 'notif_reminders';
  static const _keyBriefings = 'notif_briefings';
  static const _keyInsights = 'notif_insights';

  @override
  Future<NotificationPreference> preferences() async {
    return NotificationPreference(
      enabled: _prefs.getBool(_keyEnabled) ?? false,
      conversationReminders: _prefs.getBool(_keyReminders) ?? true,
      dateBriefings: _prefs.getBool(_keyBriefings) ?? true,
      insights: _prefs.getBool(_keyInsights) ?? true,
    );
  }

  @override
  Future<NotificationPreference> update(NotificationPreference prefs) async {
    await _prefs.setBool(_keyEnabled, prefs.enabled);
    await _prefs.setBool(_keyReminders, prefs.conversationReminders);
    await _prefs.setBool(_keyBriefings, prefs.dateBriefings);
    await _prefs.setBool(_keyInsights, prefs.insights);
    return prefs;
  }

  @override
  Future<bool> requestPermission() async {
    // Only call after explicit user tap on "Allow notifications".
    final status = await Permission.notification.request();
    final granted = status.isGranted;
    await update((await preferences()).copyWith(enabled: granted));
    return granted;
  }
}
