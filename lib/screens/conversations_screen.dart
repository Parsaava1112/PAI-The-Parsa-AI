import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../services/local_db.dart';
import '../routes/custom_page_route.dart';
import 'chat_screen.dart';
import 'dart:convert';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('conversations');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _conversations = data);
        // ذخیره محلی
        for (var conv in data) {
          LocalDatabase.saveConversation(conv);
        }
      }
    } catch (_) {
      // بارگیری از دیتابیس محلی
      final local = await LocalDatabase.getConversations();
      setState(() => _conversations = local);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مکالمات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: ConversationSearch(_conversations));
            },
          ),
        ],
      ),
      body: _loading
          ? Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 16, color: Colors.grey),
                            const SizedBox(height: 8),
                            Container(height: 12, color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset('assets/lottie/empty_robot.json', width: 200),
                      const Text('هنوز مکالمه‌ای ندارید'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (ctx, i) {
                      final conv = _conversations[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: FaIcon(FontAwesomeIcons.comment, color: Theme.of(context).primaryColor),
                          title: Text(conv['title']),
                          subtitle: Text(conv['last_message'] ?? 'بدون پیام'),
                          trailing: conv['pinned'] ? const FaIcon(FontAwesomeIcons.thumbtack, size: 16) : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              CustomPageRoute(
                                page: ChatScreen(conversationId: conv['id']),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class ConversationSearch extends SearchDelegate {
  final List<dynamic> conversations;
  ConversationSearch(this.conversations);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = conversations
        .where((c) => c['title'].toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _buildList(results, context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = conversations
        .where((c) => c['title'].toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _buildList(results, context);
  }

  Widget _buildList(List<dynamic> items, BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final conv = items[i];
        return ListTile(
          title: Text(conv['title']),
          onTap: () {
            close(context, null);  // اینجا context مربوط به buildResults/buildSuggestions هست
            Navigator.push(
              context,
              CustomPageRoute(page: ChatScreen(conversationId: conv['id'])),
            );
          },
        );
      },
    );
  }
}