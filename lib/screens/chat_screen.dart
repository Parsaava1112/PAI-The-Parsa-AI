import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/local_db.dart';
import '../services/weather_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/weather_background.dart';
import '../routes/custom_page_route.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _currentConvId;
  String _modelId = 'text';
  bool _isImmersive = false;
  bool _isSending = false;
  String? _convTitle;
  Map<String, dynamic>? _weatherData; // وضعیت آب‌وهوا

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null) {
      _currentConvId = widget.conversationId;
      _loadMessages();
    } else {
      _createNewConversation();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fetchWeather();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ══════════════════════ آب و هوا ══════════════════════
  Future<void> _fetchWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final useDynamic = prefs.getBool('use_dynamic_background') ?? false;
    if (!useDynamic) return;

    final data = await WeatherService.getCurrentWeather();
    if (mounted) {
      setState(() => _weatherData = data);
    }
  }

  // ══════════════════════ پیام‌ها ══════════════════════
  Future<void> _loadMessages() async {
    try {
      final res = await ApiService.get('conversations/$_currentConvId/messages');
      if (res.statusCode == 200) {
        final List<dynamic> msgs = jsonDecode(res.body);
        setState(() {
          _messages = msgs.map((m) => {
            'id': m['id'],
            'role': m['role'],
            'content': m['content'],
            'feedback': m['feedback'],
          }).toList();
        });
        for (var msg in _messages) {
          LocalDatabase.saveMessage({
            'conversation_id': _currentConvId,
            'role': msg['role'],
            'content': msg['content'],
            'timestamp': DateTime.now().toIso8601String(),
            'feedback': msg['feedback'],
          });
        }
      }
    } catch (_) {
      final localMsgs = await LocalDatabase.getMessages(_currentConvId!);
      if (localMsgs.isNotEmpty) {
        setState(() {
          _messages = localMsgs.map((m) => {
            'id': m['id'],
            'role': m['role'],
            'content': m['content'],
            'feedback': m['feedback'],
          }).toList();
        });
      }
    }
  }

  Future<void> _createNewConversation() async {
    try {
      final res = await ApiService.post('conversations', {'model_id': _modelId});
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        setState(() {
          _currentConvId = data['id'];
          _convTitle = data['title'];
          _messages = [];
        });
        LocalDatabase.saveConversation(data);
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty || _currentConvId == null || _isSending) return;

    final message = _msgController.text.trim();
    _msgController.clear();
    setState(() => _isSending = true);
    setState(() {
      _messages.add({'role': 'user', 'content': message});
    });
    HapticFeedback.mediumImpact();

    try {
      final res = await ApiService.post('chat/send', {
        'conversation_id': _currentConvId,
        'message': message,
        'model_id': _modelId,
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _messages.add({
            'role': 'ai',
            'content': data['ai_response'],
            'feedback': null,
          });
          if (data['title'] != null) _convTitle = data['title'];
        });
        LocalDatabase.saveMessage({
          'conversation_id': _currentConvId,
          'role': 'ai',
          'content': data['ai_response'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'content': 'خطا در ارتباط با سرور'});
      });
    }
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ════════════════════ پین / فول‌اسکرین ════════════════════
  Future<void> _togglePin() async {
    if (_currentConvId == null) return;
    try {
      final res = await ApiService.put('conversations/$_currentConvId/pin', {});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final db = await LocalDatabase.database;
        db.update('conversations', {'pinned': data['pinned'] ? 1 : 0},
            where: 'id = ?', whereArgs: [_currentConvId]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['pinned'] ? 'پین شد' : 'حذف پین')),
        );
      }
    } catch (_) {}
  }

  void _toggleImmersive() {
    setState(() => _isImmersive = !_isImmersive);
    if (_isImmersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  // ════════════════════ انتخاب‌گر مدل ════════════════════
  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return FutureBuilder<http.Response>(
          future: ApiService.get('models'),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final models = jsonDecode(snap.data!.body) as List;
            return ListView.separated(
              itemCount: models.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final m = models[i];
                return ListTile(
                  leading: const CircleAvatar(child: FaIcon(FontAwesomeIcons.robot)),
                  title: Text(m['name']),
                  subtitle: Text(m['short_desc'] ?? ''),
                  onTap: () {
                    setState(() => _modelId = m['id']);
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ════════════════════ ساختار صفحه ════════════════════
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final themeProv = context.watch<ThemeProvider>();

    // محتوای اصلی چت
    Widget bodyContent = Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (ctx, i) {
              final msg = _messages[i];
              final isUser = msg['role'] == 'user';
              return ChatBubble(
                message: msg['content'],
                isUser: isUser,
                showFeedback: !isUser,
                feedback: msg['feedback'],
                messageId: msg['id'],
                conversationId: _currentConvId,
              );
            },
          ),
        ),
        if (_isSending)
          SizedBox(
            height: 60,
            child: Lottie.asset('assets/lottie/ai_loader.json'),
          ),
        if (!_isImmersive)
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 8 + bottomPadding,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'پیام خود را بنویسید...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const FaIcon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 20),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    // ═══════════ پس‌زمینه (پویا یا ثابت) ═══════════
    Widget backgroundWrapper = WeatherBackground(
      weatherData: _weatherData,
      child: bodyContent,
    );

    // تصویر ثابت انتخابی کاربر (در صورت غیرفعال بودن پویا و وجود مسیر)
    if (!themeProv.useDynamicBackground && themeProv.customBackgroundPath != null) {
      backgroundWrapper = Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              themeProv.customBackgroundPath!,
              fit: BoxFit.cover,
            ),
          ),
          backgroundWrapper,
        ],
      );
    }

    return Scaffold(
      appBar: _isImmersive
          ? null
          : AppBar(
              title: Text(_convTitle ?? 'گفتگوی جدید'),
              actions: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.thumbtack),
                  onPressed: _togglePin,
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _toggleImmersive,
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.plus),
                  onPressed: () {
                    setState(() {
                      _currentConvId = null;
                      _messages = [];
                    });
                    _createNewConversation();
                  },
                ),
              ],
            ),
      drawer: _isImmersive ? null : const AppDrawer(),
      floatingActionButton: _isImmersive
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: FloatingActionButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showModelPicker();
                },
                child: const FaIcon(FontAwesomeIcons.robot),
              ),
            ),
      body: backgroundWrapper,
    );
  }
}