// search_page.dart
import 'package:flutter/material.dart';
import '../widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class SearchPage extends StatefulWidget {
  final String initialKeyword;
  final Map<String, dynamic>? userProfile;
  final Function(Map<String, dynamic>)? onUserUpdated;

  const SearchPage({
    super.key,
    this.initialKeyword = "",
    this.userProfile,
    this.onUserUpdated,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;

  List<dynamic> dataList = [];
  bool isLoading = false;

  // ── filter ──
  List courseGroups = [];
  List allCourses = [];
  List filteredCourses = [];
  String? selectedCgId;
  String? selectedCrsId;
  double minPrice = 0;
  double maxPrice = 1000;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialKeyword);
    fetchOptions();
    fetchData(widget.initialKeyword);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialKeyword != widget.initialKeyword) {
      _searchController.text = widget.initialKeyword;
      // ✅ ถ้า keyword ว่าง ให้ล้างผลและ filter ด้วย
      if (widget.initialKeyword.isEmpty) {
        setState(() {
          dataList = [];
          selectedCgId = null;
          selectedCrsId = null;
          filteredCourses = [];
          minPrice = 0;
          maxPrice = 1000;
        });
      } else {
        fetchData(widget.initialKeyword);
      }
    }
  }

  Future<void> fetchOptions() async {
    try {
      final response = await http
          .get(Uri.parse("$kBaseUrl/get_course_options.php"))
          .timeout(kApiTimeout);
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          courseGroups = data['course_groups'];
          allCourses = data['courses'];
        });
      }
    } catch (e) {
      debugPrint("fetchOptions error: $e");
    }
  }

  Future<void> fetchData(String keyword) async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse("$kBaseUrl/get_tutor_list.php"),
            headers: apiHeaders(),
            body: jsonEncode({
              "search_name": keyword,
              "cg_id": selectedCgId ?? "", // ✅ เพิ่ม filter กลุ่มวิชา
              "crs_id": selectedCrsId ?? "",
              "min_price": minPrice,
              "max_price": maxPrice,
            }),
          )
          .timeout(kApiTimeout);
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() => dataList = data['datalist'] ?? []);
    } catch (e) {
      debugPrint("fetchData error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List get _filteredList => dataList;

  String get _selectedCgName {
    if (selectedCgId == null) return 'กลุ่มวิชา';
    // cast<Map?>() เพื่อให้ orElse: () => null ถูกต้องตาม null-safety
    final found = courseGroups.cast<Map?>().firstWhere(
      (g) => g?['cg_id'].toString() == selectedCgId,
      orElse: () => null,
    );
    return found?['cg_name'] ?? 'กลุ่มวิชา';
  }

  String get _selectedCrsName {
    if (selectedCrsId == null) return 'รายวิชา';
    // cast<Map?>() เพื่อให้ orElse: () => null ถูกต้องตาม null-safety
    final found = allCourses.cast<Map?>().firstWhere(
      (c) => c?['crs_id'].toString() == selectedCrsId,
      orElse: () => null,
    );
    return found?['crs_name'] ?? 'รายวิชา';
  }

  // ── popup กลุ่มวิชา ──
  void _showCgPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // จำกัดความสูงไว้ที่ 70% ของหน้าจอ ป้องกัน overflow
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'เลือกกลุ่มวิชา',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          // ห่อด้วย Flexible + SingleChildScrollView ให้เลื่อนได้เมื่อมีรายการเยอะ
          Flexible(
            child: SingleChildScrollView(
              child: RadioGroup<String?>(
                groupValue: selectedCgId,
                onChanged: (val) {
                  setState(() {
                    selectedCgId = val;
                    selectedCrsId = null;
                    filteredCourses = val == null
                        ? []
                        : allCourses
                              .where((c) => c['cg_id'].toString() == val)
                              .toList();
                  });
                  Navigator.pop(ctx);
                  fetchData(_searchController.text);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text('ทุกกลุ่มวิชา'),
                      leading: Radio<String?>(
                        value: null,
                        activeColor: Color(0xFF3c83f6),
                      ),
                    ),
                    ...courseGroups.map(
                      (g) => ListTile(
                        title: Text(g['cg_name']),
                        leading: Radio<String?>(
                          value: g['cg_id'].toString(),
                          activeColor: const Color(0xFF3c83f6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── popup รายวิชา ──
  void _showCrsPicker() {
    if (selectedCgId == null) {
      showSnackBar(context, 'กรุณาเลือกกลุ่มวิชาก่อน', Colors.orange);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'เลือกรายวิชา',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: RadioGroup<String?>(
                groupValue: selectedCrsId,
                onChanged: (val) {
                  setState(() => selectedCrsId = val);
                  Navigator.pop(ctx);
                  fetchData(_searchController.text);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text('ทุกรายวิชา'),
                      leading: Radio<String?>(
                        value: null,
                        activeColor: Color(0xFF3c83f6),
                      ),
                    ),
                    ...filteredCourses.map(
                      (c) => ListTile(
                        title: Text(c['crs_name']),
                        leading: Radio<String?>(
                          value: c['crs_id'].toString(),
                          activeColor: const Color(0xFF3c83f6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── popup ราคา ──
  void _showPricePicker() {
    double tempMin = minPrice;
    double tempMax = maxPrice;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ช่วงราคา (บาท/ครั้ง)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '${tempMin.toInt()} ฿',
                    style: const TextStyle(
                      color: Color(0xFF3c83f6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: RangeSlider(
                      values: RangeValues(tempMin, tempMax),
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      activeColor: const Color(0xFF3c83f6),
                      labels: RangeLabels(
                        '${tempMin.toInt()}',
                        '${tempMax.toInt()}',
                      ),
                      onChanged: (val) => setSheet(() {
                        tempMin = val.start;
                        tempMax = val.end;
                      }),
                    ),
                  ),
                  Text(
                    '${tempMax.toInt()} ฿',
                    style: const TextStyle(
                      color: Color(0xFF3c83f6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          minPrice = 0;
                          maxPrice = 1000;
                        });
                        Navigator.pop(ctx);
                        fetchData(_searchController.text);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('ล้าง'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          minPrice = tempMin;
                          maxPrice = tempMax;
                        });
                        Navigator.pop(ctx);
                        fetchData(_searchController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3c83f6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('ยืนยัน'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── ปุ่ม filter dropdown ──
  Widget _filterBtn(String label, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEBF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF3c83f6) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? const Color(0xFF3c83f6) : Colors.black87,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isActive ? const Color(0xFF3c83f6) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F7F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ──
          searchBar(
            controller: _searchController,
            hint: "ค้นหาติวเตอร์หรือวิชา",
            onSearch: () => fetchData(_searchController.text),
            onClear: () => fetchData(''),
          ),

          // ── แถว filter + ปุ่มล้าง ──
          Row(
            children: [
              // ปุ่ม filter เลื่อนได้
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      _filterBtn(
                        _selectedCgName,
                        _showCgPicker,
                        isActive: selectedCgId != null,
                      ),
                      const SizedBox(width: 8),
                      _filterBtn(
                        _selectedCrsName,
                        _showCrsPicker,
                        isActive: selectedCrsId != null,
                      ),
                      const SizedBox(width: 8),
                      _filterBtn(
                        (minPrice == 0 && maxPrice == 1000)
                            ? 'ราคา'
                            : '${minPrice.toInt()} - ${maxPrice.toInt()} ฿',
                        _showPricePicker,
                        isActive: minPrice > 0 || maxPrice < 1000,
                      ),
                    ],
                  ),
                ),
              ),
              // ── ปุ่มล้างทั้งหมด — อยู่ขวาสุด ไม่อยู่ใน scroll ──
              if (selectedCgId != null ||
                  selectedCrsId != null ||
                  minPrice > 0 ||
                  maxPrice < 1000)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCgId = null;
                        selectedCrsId = null;
                        filteredCourses = [];
                        minPrice = 0;
                        maxPrice = 1000;
                      });
                      fetchData(_searchController.text);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ล้าง',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── หัวข้อ + จำนวน ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchController.text.isEmpty
                      ? 'ติวเตอร์ทั้งหมด'
                      : 'ผลการค้นหา',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isLoading)
                  Text(
                    '${_filteredList.length} ผลลัพธ์',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3c83f6),
                    ),
                  ),
              ],
            ),
          ),

          // ── รายการการ์ด ──
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'ไม่พบติวเตอร์',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ลองเปลี่ยนคำค้นหาหรือตัวกรอง',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredList.length,
                    itemBuilder: (context, index) {
                      final item = _filteredList[index];
                      return TutorCard(
                        item: item,
                        userProfile: widget.userProfile,
                        onUserUpdated: widget.onUserUpdated,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
