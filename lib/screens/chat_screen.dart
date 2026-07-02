import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';   // AppThemeMode از اینجا میاد
import '../services/api_service.dart';
import '../services/local_db.dart';
import '../services/weather_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/weather_background.dart';
import '../routes/custom_page_route.dart';

// ─── رنگ اختصاصی هر مدل ──────────────────────────────
const Map<String, Color> kModelColors = {
  'text': Color(0xFF4CAF50),
  'creative': Color(0xFF9C27B0),
  'code': Color(0xFF2196F3),
  'vision': Color(0xFFFF9800),
};

// ─── جداکننده تاریخ ──────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final String text;
  const _DateSeparator(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(text, style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    );
  }
}

// ─── دکمه اسکرول هوشمند ──────────────────────────────
class _ScrollDownButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ScrollDownButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 16,
      child: FloatingActionButton.small(
        onPressed: onPressed,
        child: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }
}

// ═══════════════════ ChatScreen ═══════════════════════
class ChatScreen extends StatefulWidget {
  final String? conversationId;
  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _displayItems = [];       // شامل پیام‌ها + جداکننده‌ها
  List<Map<String, dynamic>> _messages = [];
  String? _currentConvId;
  String _modelId = 'text';
  bool _isImmersive = false;
  bool _isSending = false;
  String? _convTitle;
  Map<String, dynamic>? _weatherData;

  bool _showScrollDown = false;

  // زبان (fa/en)
  String _language = 'fa';

  // Immersive AppBar
  late AnimationController _appBarAnimCtrl;
  late Animation<Offset> _appBarSlide;
  bool _showImmersiveAppBar = false;

  // واکنش‌های سریع
  final List<String> _reactions = ['👍', '👎', '❤️', '🔥', '😮', '💡'];

  @override
  void initState() {
    super.initState();
    _appBarAnimCtrl = AnimationController(vsync: this, duration: 300.ms);
    _appBarSlide = Tween<Offset>(begin: Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _appBarAnimCtrl, curve: Curves.easeInOut));

    if (widget.conversationId != null) {
      _currentConvId = widget.conversationId;
      _loadMessages();
    } else {
      _createNewConversation();
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fetchWeather();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _appBarAnimCtrl.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _msgController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ─── اسکرول ───────────────────────────────────────
  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    setState(() => _showScrollDown = (maxScroll - currentScroll) > 100);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: 300.ms,
        curve: Curves.easeOut,
      );
    }
  }

  // ─── آب و هوا ──────────────────────────────────────
  Future<void> _fetchWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final useDynamic = prefs.getBool('use_dynamic_background') ?? false;
    if (!useDynamic) return;
    final data = await WeatherService.getCurrentWeather();
    if (mounted) setState(() => _weatherData = data);
  }

  // ─── ساخت لیست نمایشی (تاریخ‌ها) ──────────────────
  void _buildDisplayItems() {
    _displayItems.clear();
    if (_messages.isEmpty) return;

    final todayLabel = _language == 'fa' ? 'امروز' : 'Today';
    final yesterdayLabel = _language == 'fa' ? 'دیروز' : 'Yesterday';

    DateTime? lastDate;
    for (final msg in _messages) {
      final ts = msg['timestamp'] != null ? DateTime.tryParse(msg['timestamp']) : null;
      final msgDate = ts != null ? DateTime(ts.year, ts.month, ts.day) : null;

      if (msgDate != null && (lastDate == null || msgDate != lastDate)) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        String label;
        if (msgDate == today) {
          label = todayLabel;
        } else if (msgDate == yesterday) {
          label = yesterdayLabel;
        } else {
          label = msgDate.toLocal().toString().substring(0, 10);
        }
        _displayItems.add(_DateSeparator(label));
      }
      _displayItems.add(msg);
      lastDate = msgDate;
    }
  }

  // ─── بارگذاری پیام‌ها ─────────────────────────────
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
            'timestamp': m['timestamp'] ?? DateTime.now().toIso8601String(),
            'reaction': null,
          }).toList();
          _buildDisplayItems();
        });
        for (var msg in _messages) {
          LocalDatabase.saveMessage({
            'conversation_id': _currentConvId,
            'role': msg['role'],
            'content': msg['content'],
            'timestamp': msg['timestamp'],
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
            'timestamp': m['timestamp'] ?? DateTime.now().toIso8601String(),
            'reaction': null,
          }).toList();
          _buildDisplayItems();
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
          _displayItems = [];
        });
        LocalDatabase.saveConversation(data);
      }
    } catch (_) {}
  }

  // ─── ارسال پیام (دو زبانه) ────────────────────────
  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty || _currentConvId == null || _isSending) return;

    final message = _msgController.text.trim();
    _msgController.clear();
    setState(() => _isSending = true);

    final now = DateTime.now().toIso8601String();
    setState(() {
      _messages.add({'role': 'user', 'content': message, 'timestamp': now, 'reaction': null});
      _buildDisplayItems();
    });

    HapticFeedback.mediumImpact();
    _scrollToBottom();

    try {
      final res = await ApiService.post('chat/send', {
        'conversation_id': _currentConvId,
        'message': message,
        'model_id': _modelId,
        'language': _language,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        HapticFeedback.lightImpact();

        setState(() {
          _messages.add({
            'role': 'ai',
            'content': data['ai_response'],
            'feedback': null,
            'timestamp': DateTime.now().toIso8601String(),
            'reaction': null,
          });
          if (data['title'] != null) _convTitle = data['title'];
          _buildDisplayItems();
        });

        LocalDatabase.saveMessage({
          'conversation_id': _currentConvId,
          'role': 'ai',
          'content': data['ai_response'],
          'timestamp': DateTime.now().toIso8601String(),
        });
        _scrollToBottom();
      }
    } catch (_) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'content': _language == 'fa' ? 'خطا در ارتباط با سرور' : 'Connection error',
          'timestamp': DateTime.now().toIso8601String(),
          'reaction': null,
        });
        _buildDisplayItems();
      });
    }
    setState(() => _isSending = false);
  }

  // ─── Quick Reactions ──────────────────────────────
  void _showReactionPicker(int messageIndex) {
    final msg = _messages[messageIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _reactions.map((emoji) => GestureDetector(
            onTap: () {
              setState(() => msg['reaction'] = emoji);
              HapticFeedback.selectionClick();
              Navigator.pop(ctx);
            },
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          )).toList(),
        ),
      ),
    );
  }

  // ─── منوی طولانی ─────────────────────────────────
  void _showMessageMenu(int messageIndex) {
    final msg = _messages[messageIndex];
    final isUser = msg['role'] == 'user';
    final content = msg['content'] as String;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(_language == 'fa' ? 'کپی متن' : 'Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: content));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_language == 'fa' ? 'کپی شد' : 'Copied')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(_language == 'fa' ? 'اشتراک‌گذاری' : 'Share'),
              onTap: () {
                Share.share(content);
                Navigator.pop(ctx);
              },
            ),
            if (isUser)
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(_language == 'fa' ? 'حذف' : 'Delete'),
                onTap: () {
                  setState(() {
                    _messages.removeAt(messageIndex);
                    _buildDisplayItems();
                  });
                  Navigator.pop(ctx);
                },
              ),
            if (!isUser)
              ListTile(
                leading: const Icon(Icons.replay),
                title: Text(_language == 'fa' ? 'بازسازی پاسخ' : 'Regenerate'),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: logic for regenerate
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─── پین / آرشیو ──────────────────────────────────
  Future<void> _togglePin() async {
    if (_currentConvId == null) return;
    try {
      final res = await ApiService.put('conversations/$_currentConvId/pin', {});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final pinned = data['pinned'] ?? false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(pinned
                ? (_language == 'fa' ? 'پین شد' : 'Pinned')
                : (_language == 'fa' ? 'حذف پین' : 'Unpinned'))),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _archiveConversation() async {
    if (_currentConvId == null) return;
    try {
      await ApiService.put('conversations/$_currentConvId/archive', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_language == 'fa' ? 'بایگانی شد' : 'Archived')),
        );
        Navigator.pop(context);
      }
    } catch (_) {}
  }

  // ─── Immersive هوشمند ─────────────────────────────
  void _toggleImmersive() {
    setState(() => _isImmersive = !_isImmersive);
    if (_isImmersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      _appBarAnimCtrl.reverse();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _appBarAnimCtrl.forward();
    }
  }

  void _onTopTap() {
    if (!_isImmersive) return;
    setState(() => _showImmersiveAppBar = !_showImmersiveAppBar);
    if (_showImmersiveAppBar) {
      _appBarAnimCtrl.forward();
      Future.delayed(3.seconds, () {
        if (mounted && _showImmersiveAppBar) {
          setState(() => _showImmersiveAppBar = false);
          _appBarAnimCtrl.reverse();
        }
      });
    } else {
      _appBarAnimCtrl.reverse();
    }
  }

  // ─── انتخاب‌گر مدل ────────────────────────────────
  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FutureBuilder<http.Response>(
        future: ApiService.get('models'),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final models = jsonDecode(snap.data!.body) as List;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _language == 'fa' ? 'انتخاب مدل' : 'Choose Model',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: models.length,
                  itemBuilder: (_, i) {
                    final m = models[i];
                    final selected = _modelId == m['id'];
                    final color = kModelColors[m['id']] ?? Colors.blue;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      color: selected ? color.withOpacity(0.2) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: selected ? BorderSide(color: color, width: 2) : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(Icons.auto_awesome, color: color),
                        ),
                        title: Text(m['name']),
                        subtitle: Text(m['short_desc'] ?? ''),
                        trailing: selected ? Icon(Icons.check_circle, color: color) : null,
                        onTap: () {
                          setState(() => _modelId = m['id']);
                          Navigator.pop(context);
                          HapticFeedback.lightImpact();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${_language == 'fa' ? 'مدل به' : 'Switched to'} ${m['name']}',
                                ),
                                duration: 1.seconds,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── تغییر زبان (دو زبانه) ────────────────────────
  void _toggleLanguage() {
    setState(() => _language = _language == 'fa' ? 'en' : 'fa');
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_language == 'fa' ? 'زبان فارسی' : 'English Mode'),
        duration: 1.seconds,
      ),
    );
  }

  // ─── شکل حباب بر اساس AppThemeMode ─────────────────
  BorderRadius _bubbleBorderRadius(AppThemeMode mode, {required bool isUser}) {
    switch (mode) {
      case AppThemeMode.happy:
        return BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isUser ? const Radius.circular(4) : const Radius.circular(20),
          bottomRight: isUser ? const Radius.circular(20) : const Radius.circular(4),
        );
      case AppThemeMode.cyberpunk:
        return BorderRadius.only(
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(20),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(2),
        );
      default:
        return const BorderRadius.all(Radius.circular(16));
    }
  }

  // ═══════════════════ build ═══════════════════════
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final themeProv = context.watch<ThemeProvider>();
    final appThemeMode = themeProv.appThemeMode;  // AppThemeMode از ThemeProvider

    // رشته‌های دو زبانه
    final hintText = _language == 'fa' ? 'پیام خود را بنویسید...' : 'Type your message...';
    final newChatLabel = _language == 'fa' ? 'گفتگوی جدید' : 'New Chat';
    final pinLabel = _language == 'fa' ? 'پین' : 'Pin';
    final archiveLabel = _language == 'fa' ? 'بایگانی' : 'Archive';
    final fullscreenLabel = _language == 'fa' ? 'تمام‌صفحه' : 'Fullscreen';
    final modelLabel = _language == 'fa' ? 'مدل' : 'Model';

    // اپ‌بار Immersive شناور
    Widget? immersiveAppBar;
    if (_isImmersive && _showImmersiveAppBar) {
      immersiveAppBar = SlideTransition(
        position: _appBarSlide,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: AppBar(
            title: Text(_convTitle ?? (_language == 'fa' ? 'گفتگوی جدید' : 'New Chat')),
            actions: [
              IconButton(icon: const FaIcon(FontAwesomeIcons.thumbtack), onPressed: _togglePin),
              IconButton(icon: const Icon(Icons.archive), onPressed: _archiveConversation),
              IconButton(icon: const Icon(Icons.fullscreen_exit), onPressed: _toggleImmersive),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      );
    }

    // لیست چت
    Widget chatList = ListView.builder(
      controller: _scrollController,
      itemCount: _displayItems.length,
      itemBuilder: (ctx, i) {
        final item = _displayItems[i];
        if (item is _DateSeparator) return item;

        final msg = item as Map<String, dynamic>;
        final isUser = msg['role'] == 'user';
        final content = msg['content'] ?? '';
        final reaction = msg['reaction'] as String?;
        final modelColor = isUser ? null : (kModelColors[_modelId] ?? Theme.of(context).primaryColor);

        Widget bubble;
        if (isUser) {
          bubble = ChatBubble(
            message: content,
            isUser: true,
            showFeedback: false,
          );
        } else {
          bubble = GestureDetector(
            onLongPress: () => _showMessageMenu(i),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (modelColor ?? Colors.grey).withOpacity(0.15),
                    borderRadius: _bubbleBorderRadius(appThemeMode, isUser: false),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: MarkdownBody(
                    data: content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      code: TextStyle(
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                if (reaction != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 2),
                    child: Text(reaction, style: const TextStyle(fontSize: 20)),
                  ),
              ],
            ),
          );
        }

        return bubble.animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
      },
    );

    final scrollDownButton = _showScrollDown
        ? _ScrollDownButton(onPressed: _scrollToBottom)
        : null;

    Widget bodyContent = Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              chatList,
              if (scrollDownButton != null) scrollDownButton,
            ],
          ),
        ),
        if (_isSending)
          SizedBox(height: 60, child: Lottie.asset('assets/lottie/ai_loader.json')),
        if (!_isImmersive)
          Container(
            padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8 + bottomPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: hintText,
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

    Widget backgroundWrapper = WeatherBackground(
      weatherData: _weatherData,
      child: bodyContent,
    );

    if (!themeProv.useDynamicBackground && themeProv.customBackgroundPath != null) {
      backgroundWrapper = Stack(
        children: [
          Positioned.fill(
            child: Image.asset(themeProv.customBackgroundPath!, fit: BoxFit.cover),
          ),
          backgroundWrapper,
        ],
      );
    }

    return Scaffold(
      appBar: _isImmersive ? null : AppBar(
        title: Text(_convTitle ?? (_language == 'fa' ? 'گفتگوی جدید' : 'New Chat')),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _toggleLanguage,
            tooltip: _language == 'fa' ? 'English' : 'فارسی',
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.thumbtack),
            onPressed: _togglePin,
            tooltip: pinLabel,
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: _archiveConversation,
            tooltip: archiveLabel,
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: _toggleImmersive,
            tooltip: fullscreenLabel,
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus),
            onPressed: () {
              setState(() {
                _currentConvId = null;
                _messages = [];
                _displayItems = [];
              });
              _createNewConversation();
            },
            tooltip: newChatLabel,
          ),
        ],
      ),
      drawer: _isImmersive ? null : const AppDrawer(),
      floatingActionButton: _isImmersive ? null : Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showModelPicker();
          },
          tooltip: modelLabel,
          child: const FaIcon(FontAwesomeIcons.robot),
        ),
      ),
      body: Stack(
        children: [
          backgroundWrapper,
          if (immersiveAppBar != null)
            Positioned(top: 0, left: 0, right: 0, child: immersiveAppBar),
          if (_isImmersive)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).padding.top + 50,
              child: GestureDetector(
                onTap: _onTopTap,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }
}
