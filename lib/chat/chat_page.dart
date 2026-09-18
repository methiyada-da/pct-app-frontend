// chat_page.dart — รายการแชททั้งหมด (bottom nav tab)
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets.dart';
import 'package:http/http.dart' as http;
import 'chat_room_page.dart';
import '../config.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback? onLogin; // ✅ callback ให้ MainNavigation เปิด login

  const ChatPage({super.key, this.userProfile, this.onLogin});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List conversations = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.userProfile != null) fetchConversations();
  }

  Future<void> fetchConversations() async {
    setState(() => isLoading = true);
    try {
      final res = await http
          .get(
            Uri.parse("$kBaseUrl/get_conversations.php"),
            headers: apiHeaders(widget.userProfile),
          )
          .timeout(kApiTimeout);
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        if (!mounted) return;
        setState(() => conversations = data['conversations'] ?? []);
      }
    } catch (e) {
      debugPrint("fetchConversations error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatTime(String? dt) {
    if (dt == null || dt.isEmpty) return '';
    final d = DateTime.parse(dt).toLocal();
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }
    return "${d.day}/${d.month}/${d.year}";
  }

  // ── เปิดห้องแชท ──
  void _openRoom(Map conv) {
    final otherName = conv['other_name']?.toString() ?? 'ผู้ใช้';
    final otherImg = conv['other_img']?.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          convId: int.parse(conv['conv_id'].toString()),
          session: widget.userProfile!,
          otherName: otherName,
          otherImg: otherImg,
        ),
      ),
    ).then((_) => fetchConversations());
  }

  @override
  Widget build(BuildContext context) {
    // ยังไม่ล็อกอิน
    if (widget.userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'กรุณาเข้าสู่ระบบเพื่อดูข้อความ',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // ✅ ให้ MainNavigation จัดการ login เอง ไม่ต้อง push จาก ChatPage
                widget.onLogin?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3c83f6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ยังไม่มีการสนทนา',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ค้นหาติวเตอร์และเริ่มแชทได้เลย',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchConversations,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: conversations.length,
                itemBuilder: (ctx, i) {
                  final conv = conversations[i];
                  final otherName = conv['other_name']?.toString() ?? 'ผู้ใช้';
                  final otherImg = buildImageUrl(conv['other_img']?.toString());
                  final lastMsg =
                      conv['last_msg']?.toString() ?? 'ยังไม่มีข้อความ';
                  final lastTime = _formatTime(conv['last_time']);
                  final unread =
                      int.tryParse(conv['unread_count']?.toString() ?? '0') ??
                      0;

                  return GestureDetector(
                    onTap: () => _openRoom(conv),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFEBF2FF),
                            backgroundImage: otherImg.isNotEmpty
                                ? NetworkImage(otherImg)
                                : null,
                            child: otherImg.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xFF3c83f6),
                                    size: 28,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      otherName,
                                      style: TextStyle(
                                        fontWeight: unread > 0
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      lastTime,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: unread > 0
                                            ? const Color(0xFF3c83f6)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lastMsg,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: unread > 0
                                              ? Colors.black87
                                              : Colors.grey,
                                          fontWeight: unread > 0
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (unread > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF3c83f6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$unread',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
