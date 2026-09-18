// tutor_register_page.dart
import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets.dart';
import '../appbar.dart';

class TutorRegisterPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const TutorRegisterPage({super.key, required this.userProfile});

  @override
  State<TutorRegisterPage> createState() => _TutorRegisterPageState();
}

class _TutorRegisterPageState extends State<TutorRegisterPage> {
  final descCtrl = TextEditingController();
  final skillCtrl = TextEditingController();
  final gpaxCtrl = TextEditingController();
  final expDescCtrl = TextEditingController();

  bool hasExp = false;
  bool isLoading = true;
  bool isAlreadyRegistered = false;
  Map<String, dynamic>? registeredData;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  @override
  void dispose() {
    descCtrl.dispose();
    skillCtrl.dispose();
    gpaxCtrl.dispose();
    expDescCtrl.dispose();
    super.dispose();
  }

  // ✅ ฟังก์ชันเช็คสถานะการลงทะเบียน (GET)
  Future<void> _checkRegistrationStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse("$kBaseUrl/create_tutor.php"),
            headers: apiHeaders(widget.userProfile),
          )
          .timeout(kApiTimeout);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == "exists") {
          setState(() {
            isAlreadyRegistered = true;
            registeredData = res['data'];
            // ดึงข้อมูลเก่ามาใส่ใน Controller เพื่อให้แก้ไขได้ในกรณีถูกปฏิเสธ
            descCtrl.text = registeredData!['tut_desc'] ?? "";
            skillCtrl.text = registeredData!['tut_skill'] ?? "";
            gpaxCtrl.text = registeredData!['tut_gpax']?.toString() ?? "";
            hasExp = registeredData!['tut_has_exp'] == 1;
            expDescCtrl.text = registeredData!['tut_exp_desc'] ?? "";
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking status: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ ฟังก์ชันส่งข้อมูล (POST) พร้อมเช็คเกรด 4.00
  Future<void> submitAction() async {
    if (descCtrl.text.isEmpty ||
        skillCtrl.text.isEmpty ||
        gpaxCtrl.text.isEmpty) {
      showSnackBar("กรุณากรอกข้อมูลให้ครบถ้วน", Colors.orange);
      return;
    }

    double? gpaxValue = double.tryParse(gpaxCtrl.text);
    if (gpaxValue == null || gpaxValue < 0 || gpaxValue > 4.00) {
      showSnackBar("กรุณากรอกเกรดเฉลี่ยให้ถูกต้อง (0.00 - 4.00)", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse("$kBaseUrl/create_tutor.php"),
            headers: apiHeaders(widget.userProfile),
            body: jsonEncode({
              "tut_desc": descCtrl.text,
              "tut_skill": skillCtrl.text,
              "tut_gpax": gpaxValue.toStringAsFixed(2),
              "tut_has_exp": hasExp ? 1 : 0,
              "tut_exp_desc": hasExp ? expDescCtrl.text : "",
            }),
          )
          .timeout(kApiTimeout);

      if (!mounted) return;
      final res = jsonDecode(response.body);
      if (res['status'] == "success") {
        showSnackBar("ส่งคำขอลงทะเบียนสำเร็จ", Colors.green);
        Navigator.pop(context, "success");
      } else {
        showSnackBar(res['message'] ?? "เกิดข้อผิดพลาด", Colors.red);
      }
    } catch (e) {
      if (mounted) showSnackBar("การเชื่อมต่อขัดข้อง: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    String text = "รออนุมัติ";
    Color color = Colors.orange;
    if (status == 1) {
      text = "อนุมัติแล้ว";
      color = Colors.green;
    }
    if (status == 2) {
      text = "ไม่ผ่านการอนุมัติ";
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: myAppBar(
        titleText: isAlreadyRegistered ? 'สถานะติวเตอร์' : 'สมัครเป็นติวเตอร์',
        onPrimaryAction: () => Navigator.pop(context),
        isLoginPage: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ ส่วนแสดงผลแบบสลับโหมดตามสถานะ
                  if (isAlreadyRegistered &&
                      registeredData!['tut_status'] != 2) ...[
                    // ✅ กรณี: รออนุมัติ (0) หรือ อนุมัติแล้ว (1) -> อ่านอย่างเดียว
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "สถานะปัจจุบัน:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildStatusBadge(
                          int.parse(registeredData!['tut_status'].toString()),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text(
                      "ข้อมูลสมาชิก",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    labeledDisplay(
                      "คณะ",
                      widget.userProfile['fac_name'] ?? "-",
                      icon: Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: 16),
                    labeledDisplay(
                      "สาขาวิชา",
                      widget.userProfile['mj_name'] ?? "-",
                      icon: Icons.book_outlined,
                    ),
                    const SizedBox(height: 16),
                    labeledDisplay(
                      "ชื่อ-นามสกุล",
                      widget.userProfile['mb_full_name'] ?? "-",
                      icon: Icons.badge_outlined,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),
                    const Text(
                      "ข้อมูลติวเตอร์",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    labeledDisplay(
                      "รายละเอียดติวเตอร์",
                      registeredData!['tut_desc'],
                      icon: Icons.description,
                    ),
                    const SizedBox(height: 16),
                    labeledDisplay(
                      "วิชาที่ถนัด",
                      registeredData!['tut_skill'],
                      icon: Icons.star,
                    ),
                    const SizedBox(height: 16),
                    labeledDisplay(
                      "เกรดเฉลี่ย",
                      registeredData!['tut_gpax'].toString(),
                      icon: Icons.grade,
                    ),
                    if (hasExp) ...[
                      const SizedBox(height: 16),
                      labeledDisplay(
                        "ประสบการณ์",
                        registeredData!['tut_exp_desc'],
                        icon: Icons.history_edu,
                      ),
                    ],
                  ] else ...[
                    // ✅ กรณี: ใหม่ หรือ ถูกปฏิเสธ (2) -> แก้ไขได้และส่งใหม่ได้
                    if (isAlreadyRegistered &&
                        registeredData!['tut_status'] == 2) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "สถานะปัจจุบัน:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          _buildStatusBadge(2),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "โปรดแก้ไขข้อมูลและส่งคำขอใหม่",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                    ],
                    const Text(
                      "ข้อมูลผู้สมัคร",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    labeledDisplay(
                      "คณะ",
                      widget.userProfile['fac_name'] ?? "-",
                      icon: Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: 16),
                    labeledDisplay(
                      "สาขาวิชา",
                      widget.userProfile['mj_name'] ?? "-",
                      icon: Icons.book_outlined,
                    ),
                    const SizedBox(height: 16),
                    labeledDisplay(
                      "ชื่อ-นามสกุล",
                      widget.userProfile['mb_full_name'] ?? "-",
                      icon: Icons.badge_outlined,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),
                    const Text(
                      "รายละเอียดการติว",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    inputText(
                      descCtrl,
                      "แนะนำตัว",
                      label: "รายละเอียดติวเตอร์",
                      icon: Icons.description,
                    ),
                    const SizedBox(height: 16),
                    inputText(
                      skillCtrl,
                      "วิชาที่ถนัด",
                      label: "วิชาที่ถนัด",
                      icon: Icons.star,
                    ),
                    const SizedBox(height: 16),
                    inputText(
                      gpaxCtrl,
                      "0.00-4.00",
                      label: "เกรดเฉลี่ย (GPAX)",
                      icon: Icons.grade,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text("เคยมีประสบการณ์สอนมาก่อน"),
                      value: hasExp,
                      onChanged: (val) => setState(() => hasExp = val ?? false),
                      activeColor: const Color(0xFF3c83f6),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (hasExp)
                      inputText(
                        expDescCtrl,
                        "ระบุประสบการณ์",
                        label: "รายละเอียดประสบการณ์",
                        icon: Icons.history_edu,
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: buttonAction(
                        isAlreadyRegistered
                            ? "ส่งคำขอใหม่อีกครั้ง"
                            : "ยืนยันลงทะเบียน",
                        submitAction,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
