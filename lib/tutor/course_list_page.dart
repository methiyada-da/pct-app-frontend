// course_list_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../appbar.dart';
import '../widgets.dart';
import 'edit_course_page.dart';
import '../config.dart';

class CourseListPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const CourseListPage({super.key, required this.userProfile});

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  List courseList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse("$kBaseUrl/get_tutor_courses.php"),
            headers: apiHeaders(widget.userProfile),
            body: jsonEncode({}),
          )
          .timeout(kApiTimeout);
      if (!mounted) return;
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        setState(() => courseList = data['courses']);
      } else {
        showSnackBar(
          context,
          "โหลดข้อมูลล้มเหลว: ${data['message']}",
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) showSnackBar(context, "โหลดข้อมูลล้มเหลว: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> toggleStatus(String tutcId, int currentStatus) async {
    final newStatus = currentStatus == 1 ? 0 : 1;
    try {
      final response = await http
          .post(
            Uri.parse("$kBaseUrl/toggle_course_status.php"),
            headers: apiHeaders(widget.userProfile),
            body: jsonEncode({"tutc_id": tutcId, "tutc_status": newStatus}),
          )
          .timeout(kApiTimeout);
      if (!mounted) return;
      final res = jsonDecode(response.body);
      if (res['status'] == 'success') {
        setState(() {
          final idx = courseList.indexWhere((c) => c['tutc_id'] == tutcId);
          if (idx != -1) courseList[idx]['tutc_status'] = newStatus;
        });
      } else {
        showSnackBar(
          context,
          res['message']?.toString() ?? 'เปลี่ยนสถานะไม่สำเร็จ',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) showSnackBar(context, "เปลี่ยนสถานะไม่สำเร็จ", Colors.red);
    }
  }

  Future<void> deleteCourse(String tutcId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ยืนยันการลบ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('ต้องการลบคอร์สนี้หรือไม่? ไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      final response = await http
          .post(
            Uri.parse("$kBaseUrl/delete_tutor_course.php"),
            headers: apiHeaders(widget.userProfile),
            body: jsonEncode({"tutc_id": tutcId}),
          )
          .timeout(kApiTimeout);
      if (!mounted) return;
      final res = jsonDecode(response.body);
      if (res['status'] == 'success') {
        showSnackBar(context, "ลบคอร์สสำเร็จ", Colors.green);
        setState(() => courseList.removeWhere((c) => c['tutc_id'] == tutcId));
      } else {
        showSnackBar(
          context,
          res['message']?.toString() ?? 'ลบคอร์สไม่สำเร็จ',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) showSnackBar(context, "ลบไม่สำเร็จ", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: myAppBar(
        titleText: 'คอร์สเรียน',
        onPrimaryAction: () => Navigator.pop(context),
        isLoginPage: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : courseList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'ยังไม่มีคอร์สเรียน',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'กลับไปเพิ่มคอร์สใหม่ได้เลย',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courseList.length,
              itemBuilder: (context, index) {
                final course = courseList[index];
                final isOpen = course['tutc_status'] == 1;
                final price =
                    double.tryParse(course['tutc_price'].toString()) ?? 0;
                final priceText = price == 0
                    ? 'ฟรี'
                    : '${price.toStringAsFixed(0)} บาท';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditCoursePage(
                            course: course,
                            session: widget.userProfile,
                          ),
                        ),
                      );
                      if (result == 'updated') fetchCourses();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── ชื่อคอร์ส + badge สถานะ ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  course['tutc_name'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isOpen ? 'เปิดรับ' : 'ปิด',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isOpen ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // ── รายวิชา ──
                          Row(
                            children: [
                              const Icon(
                                Icons.book_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                course['crs_name'] ?? '-',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // ── ราคา ──
                          Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 14,
                                color: Color(0xFF3c83f6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                priceText,
                                style: const TextStyle(
                                  color: Color(0xFF3c83f6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey.shade100),
                          const SizedBox(height: 8),

                          // ── toggle + ลบ ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Switch(
                                    value: isOpen,
                                    onChanged: (_) => toggleStatus(
                                      course['tutc_id'],
                                      course['tutc_status'],
                                    ),
                                    activeThumbColor: const Color(0xFF3c83f6),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOpen
                                        ? 'เปิดรับนักเรียน'
                                        : 'ปิดรับชั่วคราว',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOpen
                                          ? const Color(0xFF3c83f6)
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'แก้ไข',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () =>
                                        deleteCourse(course['tutc_id']),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 14,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'ลบ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
