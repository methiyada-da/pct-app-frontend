import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'search/tutor_detail_page.dart';
import 'config.dart';

// ─────────────────────────────────────────────────────────────────
// SECTION 1: Helpers & URL Builder
// ใช้ใน: appbar, chat_page, chat_room_page, profile_detail_page,
//         profile_page, tutor_detail_page
// ─────────────────────────────────────────────────────────────────

/// URL base ของ server โฟลเดอร์ uploads — ใช้ kBaseUrl จาก config.dart
String get kImgBaseUrl => "$kBaseUrl/uploads/";

/// แปลงชื่อไฟล์รูปภาพเป็น URL เต็ม
/// - null / ว่าง → คืน ""
/// - URL เต็มอยู่แล้ว → คืนตรงๆ
/// - ชื่อไฟล์เปล่า → ต่อ kImgBaseUrl นำหน้า
String buildImageUrl(String? img) {
  if (img == null || img.isEmpty) return "";
  if (img.contains("http")) return img;
  return kImgBaseUrl + img;
}

/// InputDecoration มาตรฐาน — ใช้ภายในไฟล์นี้เท่านั้น
InputDecoration _buildInputDecoration(
  String hint, {
  Widget? prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3c83f6), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

/// BoxDecoration กล่องขาวมีเงา — ใช้ภายในไฟล์นี้เท่านั้น
BoxDecoration _commonShadow() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────
// SECTION 2: Form Widgets
// ใช้ใน: login_page, register_page, change_pwd_page,
//         tutor_register_page, tutor_course_page, edit_course_page,
//         profile_detail_page
// ─────────────────────────────────────────────────────────────────

/// ช่องกรอกข้อความทั่วไป
/// ใช้ใน: login, register, tutor_register, tutor_course, edit_course
Widget inputText(
  TextEditingController controller,
  String hint, {
  IconData? icon,
  String? label,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null) ...[
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 8),
      ],
      Container(
        decoration: _commonShadow(),
        child: TextField(
          controller: controller,
          decoration: _buildInputDecoration(
            hint,
            prefix: icon != null
                ? Icon(icon, color: const Color(0xFF3c83f6))
                : null,
          ),
        ),
      ),
    ],
  );
}

/// ช่องกรอกรหัสผ่านพร้อมปุ่มแสดง/ซ่อน
/// ใช้ใน: login_page, register_page, change_pwd_page
Widget inputPassword(
  TextEditingController controller,
  String hint,
  bool isVisible,
  VoidCallback onToggle, {
  String? label,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null) ...[
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 8),
      ],
      Container(
        decoration: _commonShadow(),
        child: TextField(
          controller: controller,
          obscureText: !isVisible,
          decoration: _buildInputDecoration(
            hint,
            prefix: const Icon(Icons.lock_outline, color: Color(0xFF3c83f6)),
            suffix: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ),
    ],
  );
}

/// Dropdown พร้อม label และ icon
/// ใช้ใน: register_page, tutor_course_page
Widget inputDropdown({
  required String label,
  required String hint,
  required IconData icon,
  required String? value,
  required List<dynamic> items,
  required String itemKey,
  required String itemLabel,
  required Function(String?) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF344054),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: _commonShadow(),
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: value,
          decoration: _buildInputDecoration(
            hint,
            prefix: Icon(icon, color: const Color(0xFF3c83f6)),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item[itemKey].toString(),
              child: Text(
                item[itemLabel],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
        ),
      ),
    ],
  );
}

/// กล่องแสดงข้อมูลแบบอ่านอย่างเดียว (label + value)
/// ใช้ใน: profile_detail_page, tutor_register_page, edit_course_page
Widget labeledDisplay(String label, String value, {IconData? icon}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF344054),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _commonShadow(),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFF3c83f6), size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF101722),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// ปุ่มบันทึกหลักสีฟ้า พร้อม icon ทางซ้าย (optional)
/// ใช้ใน: login, register, change_pwd, tutor_register, tutor_course, edit_course, profile_detail
Widget buttonAction(String label, VoidCallback onPressed, {IconData? icon}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3c83f6),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// SECTION 3: Home Page Widgets
// ใช้ใน: home_page (ทุกตัว), search_page (searchBar + TutorCard)
// ─────────────────────────────────────────────────────────────────

/// ช่องค้นหาพร้อมปุ่มค้นหา
/// ใช้ใน: home_page, search_page
Widget searchBar({
  required TextEditingController controller,
  required VoidCallback onSearch,
  VoidCallback? onClear,
  String hint = "ค้นหาติวเตอร์หรือวิชา",
}) {
  return StatefulBuilder(
    builder: (context, setState) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSearch(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  // แก้ (2026-03-11): เพิ่มปุ่ม X ล้างคำค้นหา
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 18,
                          ),
                          onPressed: () {
                            controller.clear();
                            setState(() {});
                            onClear?.call();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3c83f6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 0,
            ),
            child: const Text(
              'ค้นหา',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

/// การ์ดติวเตอร์แสดงในรายการ — กดแล้วเปิด TutorDetailPage
/// ใช้ใน: home_page, search_page
class TutorCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? userProfile;
  final Function(Map<String, dynamic>)? onUserUpdated;

  const TutorCard({
    super.key,
    required this.item,
    this.userProfile,
    this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final imgUrl = buildImageUrl(item['mb_img']);
    final price = double.tryParse(item['tutc_price']?.toString() ?? '0') ?? 0;
    final priceText = price == 0
        ? 'ฟรี'
        : '${price.toStringAsFixed(0)} บาท/ครั้ง';

    Future<void> openDetail() async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TutorDetailPage(tutorData: item, userProfile: userProfile),
        ),
      );
      if (result != null && result is Map<String, dynamic>) {
        onUserUpdated?.call(result);
      }
    }

    return GestureDetector(
      onTap: openDetail,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // รูปโปรไฟล์ใหญ่ขึ้น
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFEBF2FF),
              backgroundImage: imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
              child: imgUrl.isEmpty
                  ? const Icon(Icons.person, size: 36, color: Color(0xFF3c83f6))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['tutc_name'] ?? item['tut_skill'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'โดย ${item['mb_full_name'] ?? '-'}',
                    style: const TextStyle(
                      color: Color(0xFF3c83f6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ราคา + rating + ปุ่มจอง อยู่ row เดียวกัน
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            priceText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: openDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3c83f6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                        ),
                        child: const Text(
                          'รายละเอียด',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SECTION 4: Course / Schedule Widgets
// ใช้ใน: tutor_course_page, edit_course_page
// ─────────────────────────────────────────────────────────────────

/// Formatter อัตโนมัติสำหรับช่องพิมพ์เวลา HH:MM
/// พิมพ์ 0900 → แสดงเป็น 09:00 อัตโนมัติ
/// ใช้ใน: tutor_course_page, edit_course_page
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';
    if (digits.isEmpty) {
      formatted = '';
    } else if (digits.length == 1) {
      formatted = digits;
    } else if (digits.length == 2) {
      formatted = '$digits:';
    } else if (digits.length == 3) {
      formatted = '${digits.substring(0, 2)}:${digits.substring(2)}';
    } else if (digits.length >= 4) {
      formatted = '${digits.substring(0, 2)}:${digits.substring(2, 4)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// แปลง HH:MM → นาที เพื่อคำนวณระยะเวลา
/// คืน -1 ถ้ารูปแบบไม่ถูกต้อง
/// ใช้ใน: tutor_course_page, edit_course_page
int toMinutes(String time) {
  final parts = time.split(':');
  if (parts.length != 2) return -1;
  final h = int.tryParse(parts[0]) ?? -1;
  final m = int.tryParse(parts[1]) ?? -1;
  if (h < 0 || h > 23 || m < 0 || m > 59) return -1;
  return h * 60 + m;
}

/// Card มี header (icon + title) + divider + เนื้อหา
/// ใช้ใน: tutor_course_page, edit_course_page, tutor_detail_page
Widget sectionCard({
  required IconData icon,
  required String title,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF3c83f6), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(height: 24),
        child,
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// SECTION 5: Utility Functions
// ─────────────────────────────────────────────────────────────────

/// โลโก้แอปพลิเคชัน (icon school พื้นฟ้า)
/// ใช้ใน: login_page, register_page
Widget appLogo({double size = 60}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF3c83f6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Icon(Icons.school, size: size, color: Colors.white),
  );
}

/// แสดง SnackBar พร้อมสีที่กำหนด
/// ใช้ใน: login_page, register_page
void showSnackBar(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// แสดง SnackBar "ระบบอยู่ระหว่างพัฒนา"
/// ใช้ใน: main_navigation, profile_page, manage_course_page, login_page
void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      const SnackBar(
        content: Text('🚧 ระบบอยู่ระหว่างการพัฒนา'),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

// ─────────────────────────────────────────────────────────────────
// SECTION 6: Image Picker
// ใช้ใน: profile_detail_page เท่านั้น
// ─────────────────────────────────────────────────────────────────

/// เปิด gallery เลือกรูป แล้วแปลงเป็น base64
/// คืน {"base64": "...", "path": "..."} หรือ null ถ้ายกเลิก
/// ใช้ใน: profile_detail_page
Future<Map<String, String>?> pickAndConvertImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 50,
  );

  if (image != null) {
    File imageFile = File(image.path);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    return {
      "base64": "data:image/jpeg;base64,$base64Image",
      "path": image.path,
    };
  }
  return null;
}
// ─────────────────────────────────────────────────────────────────
// SECTION 7: Course Schedule Widgets
// ใช้ใน: tutor_course_page, edit_course_page
// ─────────────────────────────────────────────────────────────────

/// ปุ่มเลือกวันสอน 7 วัน
/// ใช้ใน: tutor_course_page, edit_course_page
Widget daySelector({
  required List<bool> selectedDays,
  required void Function(int index) onToggle,
}) {
  const dayLabels = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(7, (i) {
      final selected = selectedDays[i];
      return GestureDetector(
        onTap: () => onToggle(i),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3c83f6) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFF3c83f6) : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              dayLabels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }),
  );
}

/// ช่องกรอกเวลาเริ่ม-สิ้นสุด + ปุ่มเพิ่ม + แสดง chips
/// ใช้ใน: tutor_course_page, edit_course_page
Widget timeSlotInput({
  required TextEditingController startCtrl,
  required TextEditingController endCtrl,
  required List<Map<String, dynamic>> timeSlots,
  required VoidCallback onAdd,
  required void Function(Map<String, dynamic> slot) onRemove,
}) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: startCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [TimeInputFormatter()],
              decoration: InputDecoration(
                hintText: '09:00',
                labelText: 'เริ่ม',
                prefixIcon: const Icon(
                  Icons.access_time,
                  color: Color(0xFF3c83f6),
                  size: 18,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '—',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
          Expanded(
            child: TextField(
              controller: endCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [TimeInputFormatter()],
              decoration: InputDecoration(
                hintText: '11:00',
                labelText: 'สิ้นสุด',
                prefixIcon: const Icon(
                  Icons.access_time_filled,
                  color: Color(0xFF3c83f6),
                  size: 18,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('เพิ่ม'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3c83f6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ],
      ),
      if (timeSlots.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeSlots.map((slot) {
            const labels = ['', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
            final days = (slot['days'] as List? ?? [])
                .map((day) => labels[int.tryParse(day.toString()) ?? 0])
                .where((label) => label.isNotEmpty)
                .join(', ');
            return Chip(
              label: Text(
                '$days ${slot['start']} - ${slot['end']} น. (${slot['duration']})',
                style: const TextStyle(fontSize: 12),
              ),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => onRemove(slot),
              backgroundColor: const Color(0xFFEBF2FF),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    ],
  );
}
