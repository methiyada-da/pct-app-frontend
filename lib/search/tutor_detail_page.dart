// tutor_detail_page.dart
import 'package:flutter/material.dart';
import '../widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../chat/chat_room_page.dart';
import '../auth/login_page.dart';
import '../config.dart';

class TutorDetailPage extends StatefulWidget {
  final Map<String, dynamic> tutorData;
  final Map<String, dynamic>? userProfile;

  const TutorDetailPage({super.key, required this.tutorData, this.userProfile});

  @override
  State<TutorDetailPage> createState() => _TutorDetailPageState();
}

class _TutorDetailPageState extends State<TutorDetailPage> {
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;

  // ✅ เก็บ userProfile ใน state เผื่อ login แล้วอัปเดตได้
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? selectedSlot;
  int attendees = 1;
  final noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUser = widget.userProfile;
    fetchCourseSchedule();
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchCourseSchedule() async {
    setState(() => isLoading = true);
    try {
      final tutId =
          (widget.tutorData['tut_id'] ?? widget.tutorData['mb_id'])
              ?.toString() ??
          '';
      final tutcId = widget.tutorData['tutc_id']?.toString() ?? '';

      final response = await http
          .post(
            Uri.parse("$kBaseUrl/get_tutor_courses.php"),
            headers: apiHeaders(),
            body: jsonEncode({"tut_id": tutId, "tutc_id": tutcId}),
          )
          .timeout(kApiTimeout);
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        final List courses = data['courses'] ?? [];
        // filter ฝั่ง Flutter อีกชั้น กันเผื่อ PHP ส่งมาหลายคอร์ส
        final course = courses.firstWhere(
          (c) => c['tutc_id'].toString() == tutcId,
          orElse: () => courses.isNotEmpty ? courses.first : null,
        );
        if (course != null) {
          if (!mounted) return;
          setState(() {
            schedules = (course['schedules'] as List? ?? [])
                .map((s) => Map<String, dynamic>.from(s))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("fetchCourseSchedule error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  double get price =>
      double.tryParse(widget.tutorData['tutc_price']?.toString() ?? '0') ?? 0;

  double get totalPrice => price * attendees;

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutor = widget.tutorData;
    final imgUrl = buildImageUrl(tutor['mb_img']);
    final tutcName = tutor['tutc_name']?.toString() ?? '-';
    final tutcDesc = tutor['tutc_desc']?.toString() ?? '';
    final crsName = tutor['crs_name']?.toString() ?? '';
    final priceText = price == 0
        ? 'ฟรี'
        : '${price.toStringAsFixed(0)} บาท / ครั้ง';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── AppBar ──
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: const Color(0xFF3c83f6),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context, _currentUser),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        final tutorId =
                            (widget.tutorData['tut_id'] ??
                                    widget.tutorData['mb_id'])
                                ?.toString() ??
                            '';

                        // ยังไม่ล็อกอิน → เปิด login แล้วรอผล
                        if (_currentUser == null) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                          if (result == null || !context.mounted) return;
                          setState(
                            () => _currentUser = result,
                          ); // ✅ อัปเดต state
                        }

                        final myId = _currentUser?['mb_id']?.toString() ?? '';

                        // ไม่สามารถแชทกับตัวเอง
                        if (myId == tutorId) {
                          showSnackBar(
                            context,
                            'ไม่สามารถแชทกับตัวเองได้',
                            Colors.orange,
                          );
                          return;
                        }

                        try {
                          final res = await http
                              .post(
                                Uri.parse(
                                  "$kBaseUrl/get_or_create_conversation.php",
                                ),
                                headers: apiHeaders(_currentUser),
                                body: jsonEncode({"user_b": tutorId}),
                              )
                              .timeout(kApiTimeout);
                          if (!context.mounted) return;
                          final data = jsonDecode(res.body);
                          if (data['status'] == 'success') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomPage(
                                  convId: data['conv_id'],
                                  session: _currentUser!,
                                  otherName:
                                      widget.tutorData['mb_full_name'] ??
                                      'ติวเตอร์',
                                  otherImg: widget.tutorData['mb_img'],
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint("open chat error: $e");
                        }
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: const Color(0xFF3c83f6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 50),
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white,
                            backgroundImage: imgUrl.isNotEmpty
                                ? NetworkImage(imgUrl)
                                : null,
                            child: imgUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 46,
                                    color: Color(0xFF3c83f6),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tutor['mb_full_name'] ?? '-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'โปรไฟล์ติวเตอร์และรายละเอียดคอร์ส',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. เกี่ยวกับฉัน
                        sectionCard(
                          icon: Icons.person_outline,
                          title: 'เกี่ยวกับฉัน',
                          child: Text(
                            (tutor['tut_desc']?.toString().isNotEmpty == true)
                                ? tutor['tut_desc']
                                : 'ยังไม่มีข้อมูลแนะนำตัว',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. ตารางเรียน (วันที่สอน + ช่วงเวลา)
                        sectionCard(
                          icon: Icons.calendar_today,
                          title: 'ตารางเรียน',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              schedules.isEmpty
                                  ? const Text(
                                      'ยังไม่มีช่วงเวลา',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    )
                                  : Column(
                                      children: schedules
                                          .map(
                                            (schedule) => ListTile(
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                              leading: const Icon(
                                                Icons.schedule,
                                                color: Color(0xFF3c83f6),
                                              ),
                                              title: Text(
                                                schedule['day_label']
                                                        ?.toString() ??
                                                    '-',
                                              ),
                                              trailing: Text(
                                                '${schedule['start']} - ${schedule['end']} น.',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. คอร์สเรียน — แสดงเฉพาะคอร์สที่กดมา
                        sectionCard(
                          icon: Icons.menu_book,
                          title: 'คอร์สเรียน',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tutcName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              if (crsName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  crsName,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (tutcDesc.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  tutcDesc,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5. อัตราค่าบริการ + จำนวนคน
                        sectionCard(
                          icon: Icons.attach_money,
                          title: 'อัตราค่าบริการ',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ราคาต่อคน',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    priceText,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3c83f6),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'จำนวนคน',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '$attendees',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  setState(() => attendees++),
                                              child: const Icon(
                                                Icons.keyboard_arrow_up,
                                                size: 22,
                                                color: Color(0xFF3c83f6),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                if (attendees > 1) {
                                                  setState(() => attendees--);
                                                }
                                              },
                                              child: Icon(
                                                Icons.keyboard_arrow_down,
                                                size: 22,
                                                color: attendees > 1
                                                    ? const Color(0xFF3c83f6)
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 6. สรุปการจอง
                        sectionCard(
                          icon: Icons.receipt_long,
                          title: 'สรุปการจอง',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Prototype: ส่วนการจองเป็นตัวอย่างหน้าจอและยังไม่บันทึกข้อมูล',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _summaryRow(
                                'อัตราค่าบริการ',
                                price == 0
                                    ? 'ฟรี'
                                    : '${price.toStringAsFixed(0)} บาท',
                              ),
                              _summaryRow('จำนวนคน', '$attendees คน'),
                              _summaryRow(
                                'ระยะเวลา',
                                'กรุณาเลือกช่วงเวลา',
                                valueColor: Colors.orange,
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ทั้งหมด',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${totalPrice.toStringAsFixed(2)} บาท',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3c83f6),
                                    ),
                                  ),
                                ],
                              ),
                              if (price > 0)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '(${price.toStringAsFixed(0)} × $attendees คน)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              // รายละเอียดเพิ่มเติม ย้ายมาอยู่ในนี้
                              const Text(
                                'รายละเอียดเพิ่มเติม',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: noteCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText:
                                      'เช่น หัวข้อที่ต้องการเน้น หรือข้อมูลเพิ่มเติมสำหรับติวเตอร์...',
                                  hintMaxLines: 2,
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF3c83f6),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3c83f6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'การจอง (Prototype)',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
