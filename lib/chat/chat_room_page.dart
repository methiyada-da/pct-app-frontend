// chat_room_page.dart — ห้องแชทระหว่าง 2 คน
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets.dart';
import '../config.dart';
import 'package:http/http.dart' as http;

bool shouldClearSentMessage(String currentText, String originalDraft) =>
    currentText == originalDraft;

class RequestInFlightGuard {
  bool _inFlight = false;
  int _revision = 0;

  int get revision => _revision;

  bool tryStart() {
    if (_inFlight) return false;
    _inFlight = true;
    return true;
  }

  void finish() => _inFlight = false;

  void invalidateResponses() => _revision++;

  bool isCurrent(int revision) => revision == _revision;
}

class ChatRoomPage extends StatefulWidget {
  final int convId;
  final Map<String, dynamic> session;
  final String otherName; // ชื่อคู่สนทนา
  final String? otherImg;

  const ChatRoomPage({
    super.key,
    required this.convId,
    required this.session,
    required this.otherName,
    this.otherImg,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  List messages = [];
  bool isLoading = true;
  final msgCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  Timer? _timer;
  bool _isSending = false;
  final RequestInFlightGuard _messageLoadGuard = RequestInFlightGuard();

  String get currentUserId => widget.session['mb_id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    loadMessages();
    // polling ทุก 5 วินาที
    // TODO: เปลี่ยนเป็น WebSocket หรือ FCM สำหรับ production ???
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => loadMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    msgCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> loadMessages() async {
    if (!_messageLoadGuard.tryStart()) return;
    final requestRevision = _messageLoadGuard.revision;
    try {
      final res = await http
          .post(
            Uri.parse("$kBaseUrl/get_messages.php"),
            headers: apiHeaders(widget.session),
            body: jsonEncode({"conv_id": widget.convId}),
          )
          .timeout(kApiTimeout);
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        if (!_messageLoadGuard.isCurrent(requestRevision)) return;
        if (!mounted) return;
        setState(() {
          messages = data['messages'] ?? [];
          isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("loadMessages error: $e");
      if (mounted) setState(() => isLoading = false);
    } finally {
      _messageLoadGuard.finish();
    }
  }

  Future<void> sendMessage() async {
    final originalDraft = msgCtrl.text;
    final text = originalDraft.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      final response = await http
          .post(
            Uri.parse("$kBaseUrl/send_message.php"),
            headers: apiHeaders(widget.session),
            body: jsonEncode({"conv_id": widget.convId, "msg_text": text}),
          )
          .timeout(kApiTimeout);
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        _messageLoadGuard.invalidateResponses();
        if (shouldClearSentMessage(msgCtrl.text, originalDraft)) {
          msgCtrl.clear();
        }
        await loadMessages();
      } else if (mounted) {
        showSnackBar(
          context,
          data['message'] ?? 'ส่งข้อความไม่สำเร็จ',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'ส่งข้อความไม่สำเร็จ กรุณาลองใหม่', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String dt) {
    final d = DateTime.parse(dt).toLocal();
    return "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  // แปลงวันที่เป็นภาษาไทย พ.ศ.
  String _formatDate(String dt) {
    final d = DateTime.parse(dt).toLocal();
    const months = [
      '',
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    final buddhistYear = d.year + 543;
    return '${d.day} ${months[d.month]} $buddhistYear';
  }

  // เช็คว่าเป็นวันใหม่หรือไม่
  bool _isNewDay(int index) {
    if (index == 0) return true;
    final prev = DateTime.parse(messages[index - 1]['created_at']).toLocal();
    final curr = DateTime.parse(messages[index]['created_at']).toLocal();
    return prev.year != curr.year ||
        prev.month != curr.month ||
        prev.day != curr.day;
  }

  Widget _dateSeparator(String dt) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _formatDate(dt),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherImgUrl = buildImageUrl(widget.otherImg);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3c83f6),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: otherImgUrl.isNotEmpty
                  ? NetworkImage(otherImgUrl)
                  : null,
              child: otherImgUrl.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFF3c83f6), size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.otherName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีข้อความ เริ่มสนทนาได้เลย!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isMe = msg['sender_id'].toString() == currentUserId;
                      return Column(
                        children: [
                          if (_isNewDay(i)) _dateSeparator(msg['created_at']),
                          _bubble(msg, isMe),
                        ],
                      );
                    },
                  ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(Map msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF3c83f6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg['msg_text'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg['created_at'] ?? ''),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white60 : Colors.grey,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg['is_read'].toString() == '1'
                        ? Icons.done_all
                        : Icons.done,
                    size: 13,
                    color: msg['is_read'].toString() == '1'
                        ? Colors.white
                        : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: msgCtrl,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => sendMessage(),
              decoration: InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F7F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF3c83f6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
