import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../widgets.dart';
import 'tutor_detail_page.dart';

const _primary = Color(0xFF3478F6);
const _primaryDark = Color(0xFF245BCC);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF697386);
const _surface = Color(0xFFF4F7FC);

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final int? count;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: _primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSearch extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _HeroSearch({
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -36,
              top: -48,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 74,
              bottom: -54,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'เรียนง่าย เข้าใจไว',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'ค้นหาติวเตอร์ที่ใช่\nสำหรับคุณ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'ค้นหาจากชื่อ วิชา หรือทักษะที่คุณสนใจ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 4, 5, 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF98A2B3),
                          size: 23,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: StatefulBuilder(
                            builder: (context, setInnerState) => TextField(
                              controller: controller,
                              onSubmitted: (_) => onSearch(),
                              onChanged: (_) => setInnerState(() {}),
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'ค้นหาติวเตอร์หรือวิชา',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF98A2B3),
                                  fontSize: 13.5,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: controller.text.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          controller.clear();
                                          setInnerState(() {});
                                          onClear();
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed: onSearch,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ค้นหา',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
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

class _TutorCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? userProfile;
  final Function(Map<String, dynamic>)? onUserUpdated;

  const _TutorCard({
    required this.item,
    this.userProfile,
    this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = buildImageUrl(item['mb_img']?.toString());
    final price = double.tryParse(item['tutc_price']?.toString() ?? '0') ?? 0;
    final priceText = price == 0 ? 'เรียนฟรี' : '${price.toStringAsFixed(0)} บาท/ครั้ง';

    Future<void> openDetail() async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TutorDetailPage(
            tutorData: item,
            userProfile: userProfile,
          ),
        ),
      );
      if (result is Map<String, dynamic>) onUserUpdated?.call(result);
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: openDetail,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE9EDF5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25324B).withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF79A7FF), _primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: ColoredBox(
                    color: const Color(0xFFEAF1FF),
                    child: imageUrl.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            color: _primary,
                            size: 36,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person_rounded,
                              color: _primary,
                              size: 36,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['tutc_name']?.toString() ??
                          item['tut_skill']?.toString() ??
                          '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: _primary,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item['mb_full_name']?.toString() ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 14,
                                color: _primaryDark,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                priceText,
                                style: const TextStyle(
                                  color: _primaryDark,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
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
      ),
    );
  }
}

class FacultyGrid extends StatelessWidget {
  const FacultyGrid({super.key});

  static const faculties = [
    (
      icon: Icons.engineering_rounded,
      label: 'ครุศาสตร์อุตสาหกรรม',
      color: Color(0xFFF59E0B),
      softColor: Color(0xFFFFF7E6),
    ),
    (
      icon: Icons.precision_manufacturing_rounded,
      label: 'วิศวกรรมศาสตร์',
      color: Color(0xFF3478F6),
      softColor: Color(0xFFEAF1FF),
    ),
    (
      icon: Icons.business_center_rounded,
      label: 'บริหารธุรกิจและเทคโนโลยีสารสนเทศ',
      color: Color(0xFF10A37F),
      softColor: Color(0xFFE8F8F3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth >= 640
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: faculties.map((faculty) {
              return Container(
                width: cardWidth,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EDF5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: faculty.softColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(faculty.icon, color: faculty.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        faculty.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class TutorBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const TutorBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172033), Color(0xFF293A61)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Color(0xFF91B7FF),
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'พร้อมเริ่มเรียนแล้วหรือยัง?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ค้นหาคอร์สที่เหมาะกับเป้าหมายของคุณ',
                  style: TextStyle(color: Color(0xFFB9C4DA), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onTap,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _primaryDark,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(String keyword)? onSearch;
  final Function(Map<String, dynamic>)? onUserUpdated;

  const HomePage({super.key, this.userData, this.onSearch, this.onUserUpdated});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> dataList = [];
  bool isLoading = false;
  bool hasError = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData(String searchTerm) async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/get_tutor_list.php'),
            headers: apiHeaders(),
            body: jsonEncode({'search_name': searchTerm}),
          )
          .timeout(kApiTimeout);
      final responseJson = jsonDecode(response.body);
      if (!mounted) return;
      setState(() => dataList = responseJson['datalist'] ?? []);
    } catch (error) {
      debugPrint('fetchData error: $error');
      if (mounted) setState(() => hasError = true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildTutorContent() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 42),
        child: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.cloud_off_rounded, color: _muted, size: 38),
              const SizedBox(height: 10),
              const Text(
                'โหลดข้อมูลไม่สำเร็จ',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: () => fetchData(''),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }
    if (dataList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 38),
        child: Center(
          child: Text(
            'ยังไม่มีคอร์สแนะนำในขณะนี้',
            style: TextStyle(color: _muted, fontSize: 14),
          ),
        ),
      );
    }

    final items = dataList.take(6).cast<Map<String, dynamic>>().toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTwoColumns = constraints.maxWidth >= 760;
          final width = useTwoColumns
              ? (constraints.maxWidth - 14) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: items
                .map(
                  (item) => SizedBox(
                    width: width,
                    child: _TutorCard(
                      item: item,
                      userProfile: widget.userData,
                      onUserUpdated: widget.onUserUpdated,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      child: RefreshIndicator(
        color: _primary,
        onRefresh: () => fetchData(''),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    _HeroSearch(
                      controller: _searchController,
                      onSearch: () =>
                          widget.onSearch?.call(_searchController.text.trim()),
                      onClear: () => fetchData(''),
                    ),
                    SectionHeader(
                      title: 'คอร์สแนะนำ',
                      subtitle: 'คัดสรรคอร์สที่น่าสนใจสำหรับคุณ',
                      icon: Icons.local_fire_department_rounded,
                      count: dataList.isEmpty ? null : dataList.length,
                    ),
                    _buildTutorContent(),
                    const SectionHeader(
                      title: 'ค้นหาตามคณะ',
                      subtitle: 'เลือกติวเตอร์จากสาขาที่คุณสนใจ',
                      icon: Icons.account_balance_rounded,
                    ),
                    const FacultyGrid(),
                    TutorBanner(onTap: () => widget.onSearch?.call('')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
