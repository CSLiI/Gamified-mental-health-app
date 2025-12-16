import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/services/api_service.dart';

enum NotificationType {
  encouragement,
  challenge,
  systemAlert,
  systemMotivation,
}

class SystemNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;
  final String? redirectRoute;

  SystemNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.redirectRoute,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.index,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
        'redirect_route': redirectRoute,
      };

  factory SystemNotification.fromJson(Map<String, dynamic> json) {
    return SystemNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values[json['type']],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      redirectRoute: json['redirect_route'],
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _apiEncouragements = [];
  List<dynamic> _apiMessages = [];
  List<SystemNotification> _systemNotifications = [];
  
  bool _isLoading = false;
  
  // Track if we've shown alerts this session
  bool _hasShownLowMoodAlert = false;
  
  bool get isLoading => _isLoading;
  bool get hasShownLowMoodAlert => _hasShownLowMoodAlert;

  List<dynamic> get allEncouragements {
    // Combine API encouragements + System Motivations
    final system = _systemNotifications
        .where((n) => n.type == NotificationType.systemMotivation)
        .map((n) => {
              'id': n.id,
              'sender_first_name': 'Echo',
              'sender_last_name': 'System',
              'message': n.message,
              'created_at': n.createdAt.toIso8601String(),
              'is_read': n.isRead,
              'is_system': true,
              'redirect_route': n.redirectRoute,
              'raw_object': n, 
            })
        .toList();
    
    // Sort combined list by date desc
    final combined = [..._apiEncouragements, ...system];
    combined.sort((a, b) {
      final da = DateTime.parse(a['created_at']);
      final db = DateTime.parse(b['created_at']);
      return db.compareTo(da); 
    });
    return combined;
  }

  List<dynamic> get allChallenges {
    // Combine API messages + System Alerts
    final system = _systemNotifications
        .where((n) => n.type == NotificationType.systemAlert)
        .map((n) => {
              'id': n.id,
              'sender_first_name': 'Echo',
              'sender_last_name': 'Support',
              'message': n.message,
              'created_at': n.createdAt.toIso8601String(),
              'is_read': n.isRead,
              'is_system': true,
              'redirect_route': n.redirectRoute,
              'raw_object': n,
            })
        .toList();
        
    final combined = [..._apiMessages, ...system];
    combined.sort((a, b) {
      final da = DateTime.parse(a['created_at']);
      final db = DateTime.parse(b['created_at']);
      return db.compareTo(da);
    });
    return combined;
  }
  
  Future<void> loadnotifications() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load Local
      await _loadLocalNotifications();
      
      // Load API
      await Future.wait([
        _fetchApiEncouragements(),
        _fetchApiMessages(),
      ]);
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchApiEncouragements() async {
    try {
      _apiEncouragements = await _apiService.getEncouragements();
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _fetchApiMessages() async {
    try {
      _apiMessages = await _apiService.getAllReceivedMessages();
    } catch (e) {
      // Ignore
    }
  }
  
  Future<void> _loadLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('system_notifications');
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      _systemNotifications = jsonList.map((j) => SystemNotification.fromJson(j)).toList();
    }
  }
  
  Future<void> _saveLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(_systemNotifications.map((n) => n.toJson()).toList());
    await prefs.setString('system_notifications', jsonStr);
    notifyListeners();
  }

  void addSystemNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? redirectRoute,
  }) {
    final notification = SystemNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      redirectRoute: redirectRoute,
    );
    _systemNotifications.insert(0, notification);
    _saveLocalNotifications();
    
    if (type == NotificationType.systemAlert) {
      _hasShownLowMoodAlert = true;
    }
  }
  
  void markSystemRead(String id) {
    final index = _systemNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _systemNotifications[index].isRead = true;
      _saveLocalNotifications();
    }
  }
  
  // Clear alerts flag on session start/end or explicit reset
  void resetSession() {
    _hasShownLowMoodAlert = false;
    notifyListeners();
  }
}
