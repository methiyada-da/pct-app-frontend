// tutor_course_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets.dart';
import '../appbar.dart';
import '../config.dart';

class TutorCoursePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const TutorCoursePage({super.key, required this.userProfile});

  @override
  State<TutorCoursePage> createState() => _TutorCoursePageState();
}

class _TutorCoursePageState extends State<TutorCoursePage> {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final startTimeCtrl = TextEditingController();
  final endTimeCtrl = TextEditingController();

  List courseGroups = [];
  List allCourses = [];
  List filteredCourses = [];

  String? selectedCgId;
  String? selectedCrsId;
  bool tutcStatus = true;
  bool isLoading = false;
  bool isFree = false;

  List<bool> selectedDays = List.filled(7, false);
  List<Map<String, dynamic>> timeSlots = [];

  @override
  void initState() {
    super.initState();
    fetchOptions();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    startTimeCtrl.dispose();
    endTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchOptions() async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .get(Uri.parse("$kBaseUrl/get_course_options.php"))
          .timeout(kApiTimeout);
      if (!mounted) return;
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          courseGroups = data['course_groups'];
          allCourses = data['courses'];
        });
      }
    } catch (e) {
      if (mounted) showSnackBar(context, "โหลดข้อมูลล้มเหลว", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void addTimeSlot() {
    final start = startTimeCtrl.text.trim();
    final end = endTimeCtrl.text.trim();
    final startMin = toMinutes(start);
    final endMin = toMinutes(end);

    final days = <int>[
      for (int i = 0; i < selectedDays.length; i++)
        if (selectedDays[i]) i + 1,
    ];
    if (days.isEmpty) {
      showSnackBar(
        context,
        "กรุณาเลือกวันที่สอนก่อนเพิ่มช่วงเวลา",
        Colors.orange,
      );
      return;
    }

    if (startMin == -1 || endMin == -1) {
      showSnackBar(
        context,
        "กรุณากรอกเวลาให้ถูกต้อง เช่น 09:00",
        Colors.orange,
      );
      return;
    }
    if (endMin <= startMin) {
      showSnackBar(context, "เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น", Colors.red);
      return;
    }
    final diffMin = endMin - startMin;
    final hours = diffMin ~/ 60;
    final mins = diffMin % 60;
    final durationText = mins == 0 ? '$hours ชม.' : '$hours ชม. $mins น.';
    if (timeSlots.any(
      (s) =>
          s['start'] == start &&
          s['end'] == end &&
          _sameDays(List<int>.from(s['days'] ?? []), days),
    )) {
      showSnackBar(context, "ช่วงเวลานี้มีอยู่แล้ว", Colors.orange);
      return;
    }
    setState(() {
      timeSlots.add({
        "start": start,
        "end": end,
        "duration": durationText,
        "days": days,
      });
      startTimeCtrl.clear();
      endTimeCtrl.clear();
    });
  }

  bool _sameDays(List<int> first, List<int> second) {
    first.sort();
    second.sort();
    return first.length == second.length &&
        List.generate(
          first.length,
          (i) => first[i] == second[i],
        ).every((v) => v);
  }

  Future<void> saveAction() async {
    if (nameCtrl.text.isEmpty) {
      showSnackBar(context, "กรุณากรอกชื่อคอร์ส", Colors.orange);
      return;
    }
    if (selectedCrsId == null) {
      showSnackBar(context, "กรุณาเลือกรายวิชา", Colors.orange);
      return;
    }
    final parsedPrice = double.tryParse(priceCtrl.text);
    if (!isFree &&
        (priceCtrl.text.isEmpty || parsedPrice == null || parsedPrice < 0)) {
      showSnackBar(context, "กรุณากรอกราคาให้ถูกต้อง", Colors.orange);
      return;
    }
    if (timeSlots.isEmpty) {
      showSnackBar(
        context,
        "กรุณาเพิ่มช่วงเวลาอย่างน้อย 1 ช่วง",
        Colors.orange,
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final List<Map<String, dynamic>> schedules = [];
      for (final slot in timeSlots) {
        for (final day in List<int>.from(slot['days'] ?? [])) {
          schedules.add({
            "sch_day": day,
            "sch_start": slot['start'],
            "sch_end": slot['end'],
          });
        }
      }
      final response = await http
          .post(
            Uri.parse("$kBaseUrl/create_tutor_course.php"),
            headers: apiHeaders(widget.userProfile),
            body: jsonEncode({
              "crs_id": selectedCrsId,
              "tutc_name": nameCtrl.text.trim(),
              "tutc_desc": descCtrl.text.trim(),
              "tutc_price": isFree ? 0 : parsedPrice,
              "tutc_status": tutcStatus ? 1 : 0,
              "schedules": schedules,
            }),
          )
          .timeout(kApiTimeout);
      if (!mounted) return;
      final res = jsonDecode(response.body);
      if (res['status'] == 'success') {
        showSnackBar(context, "สร้างคอร์สสำเร็จ!", Colors.green);
        Navigator.pop(context, 'success');
      } else {
        showSnackBar(context, res['message'] ?? "เกิดข้อผิดพลาด", Colors.red);
      }
    } catch (e) {
      if (mounted) showSnackBar(context, "การเชื่อมต่อขัดข้อง", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: myAppBar(
        titleText: 'เพิ่มคอร์สเรียน',
        onPrimaryAction: () => Navigator.pop(context),
        isLoginPage: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section 0: สถานะ ──
                  sectionCard(
                    icon: Icons.toggle_on_rounded,
                    title: 'สถานะคอร์ส',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tutcStatus ? 'เปิดรับนักเรียน' : 'ปิดรับชั่วคราว',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: tutcStatus
                                ? const Color(0xFF3c83f6)
                                : Colors.grey,
                          ),
                        ),
                        Switch(
                          value: tutcStatus,
                          onChanged: (val) => setState(() => tutcStatus = val),
                          activeThumbColor: const Color(0xFF3c83f6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Section 1: ข้อมูลวิชาการ ──
                  sectionCard(
                    icon: Icons.school,
                    title: 'ข้อมูลวิชาการ',
                    child: Column(
                      children: [
                        inputDropdown(
                          label: 'กลุ่มวิชา',
                          hint: 'เลือกกลุ่มวิชา',
                          icon: Icons.folder_outlined,
                          value: selectedCgId,
                          items: courseGroups,
                          itemKey: 'cg_id',
                          itemLabel: 'cg_name',
                          onChanged: (val) => setState(() {
                            selectedCgId = val;
                            selectedCrsId = null;
                            filteredCourses = allCourses
                                .where((c) => c['cg_id'].toString() == val)
                                .toList();
                          }),
                        ),
                        const SizedBox(height: 16),
                        inputDropdown(
                          label: 'รายวิชา',
                          hint: 'เลือกรายวิชา',
                          icon: Icons.book_outlined,
                          value: selectedCrsId,
                          items: filteredCourses,
                          itemKey: 'crs_id',
                          itemLabel: 'crs_name',
                          onChanged: (val) =>
                              setState(() => selectedCrsId = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Section 2: รายละเอียดคอร์ส ──
                  sectionCard(
                    icon: Icons.menu_book,
                    title: 'รายละเอียดคอร์ส',
                    child: Column(
                      children: [
                        inputText(
                          nameCtrl,
                          'เช่น เข้าใจโปรแกรมภายใน 1 คอร์ส',
                          label: 'ชื่อคอร์ส',
                        ),
                        const SizedBox(height: 16),
                        inputText(
                          descCtrl,
                          'อธิบายสิ่งที่นักเรียนจะได้เรียนรู้...',
                          label: 'คำอธิบาย',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Section 3: ตารางเวลา ──
                  sectionCard(
                    icon: Icons.calendar_month,
                    title: 'ตารางเวลา',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'วันที่สอน',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF344054),
                          ),
                        ),
                        const SizedBox(height: 10),
                        daySelector(
                          selectedDays: selectedDays,
                          onToggle: (i) => setState(
                            () => selectedDays[i] = !selectedDays[i],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ช่วงเวลา',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF344054),
                          ),
                        ),
                        const SizedBox(height: 10),
                        timeSlotInput(
                          startCtrl: startTimeCtrl,
                          endCtrl: endTimeCtrl,
                          timeSlots: timeSlots,
                          onAdd: addTimeSlot,
                          onRemove: (slot) =>
                              setState(() => timeSlots.remove(slot)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Section 4: ราคา ──
                  sectionCard(
                    icon: Icons.attach_money,
                    title: 'ราคา',
                    child: Row(
                      children: [
                        Expanded(
                          child: inputText(
                            priceCtrl,
                            'ราคา',
                            label: 'ราคาต่อครั้ง (บาท)',
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            const Text(
                              'ฟรี',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF344054),
                              ),
                            ),
                            Checkbox(
                              value: isFree,
                              activeColor: const Color(0xFF3c83f6),
                              onChanged: (val) => setState(() {
                                isFree = val!;
                                if (isFree) priceCtrl.clear();
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── ปุ่ม ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: const Text(
                            'ยกเลิก',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: buttonAction('บันทึก', saveAction)),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
