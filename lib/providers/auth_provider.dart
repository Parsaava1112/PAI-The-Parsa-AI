import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _loading = false;

  bool get isLoggedIn => _token != null;
  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userStr = prefs.getString('user');
    if (userStr != null) {
      try {
        _user = jsonDecode(userStr) as Map<String, dynamic>;
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.post('auth/login', {
        'email': email,
        'password': password,
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _user = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(_user));
        _loading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.post('auth/register', {
        'username': username,
        'email': email,
        'password': password,
      });
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _user = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(_user));
        _loading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}