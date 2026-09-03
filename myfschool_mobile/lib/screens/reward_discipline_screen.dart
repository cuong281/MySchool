import 'package:flutter/material.dart';
import 'package:myfschools/models/reward_discipline_model.dart';
import 'package:myfschools/services/reward_discipline_service.dart';
import 'package:myfschools/services/user_session.dart';
import 'package:myfschools/models/school_class_model.dart';
import 'package:myfschools/services/school_class_api.dart';

class RewardDisciplineScreen extends StatefulWidget {
  const RewardDisciplineScreen({super.key});

  @override
  State<RewardDisciplineScreen> createState() => _RewardDisciplineScreenState();
}

class _RewardDisciplineScreenState extends State<RewardDisciplineScreen> {
  final RewardDisciplineService _service = RewardDisciplineService();
  List<RewardDisciplineModel> _allData = [];
  List<RewardDisciplineModel> _filteredData = [];
  List<SchoolClassModel> _classes = [];
  
  bool _isLoading = true;
  int? _selectedClassId;
  String _selectedType = 'Tất cả'; // Tất cả, Khen thưởng, Kỷ luật

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = UserSession.instance.currentUser;
    if (user?.role == 'Admin') {
      final classes = await SchoolClassApi.instance.getAllClasses();
      setState(() => _classes = classes);
    }
    await _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final user = UserSession.instance.currentUser;
      List<RewardDisciplineModel> data;
      
      if (user?.role == 'Admin') {
        if (_selectedClassId != null) {
          data = await _service.getByClassId(_selectedClassId!);
        } else {
          data = await _service.getAllRewards();
        }
      } else {
        data = await _service.getByUserId(user?.id ?? 0);
      }
      
      _allData = data;
      _applyFilters();
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredData = _allData.where((item) {
        if (_selectedType == 'Tất cả') return true;
        final typeStr = item.type.toLowerCase();
        if (_selectedType == 'Khen thưởng') {
          return typeStr.contains('reward') || typeStr.contains('khen');
        } else {
          return typeStr.contains('discipline') || typeStr.contains('kỷ luật') || typeStr.contains('kỉ luật');
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = UserSession.instance.currentUser?.role == 'Admin';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Khen thưởng & Kỷ luật', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(isAdmin),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : _filteredData.isEmpty 
                    ? _buildEmptyState() 
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _filteredData.length,
                          itemBuilder: (context, index) => _buildItemCard(_filteredData[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdownFilter<String>(
                  value: _selectedType,
                  items: ['Tất cả', 'Khen thưởng', 'Kỷ luật'],
                  onChanged: (v) {
                    if (v != null) {
                      _selectedType = v;
                      _applyFilters();
                    }
                  },
                  label: 'Loại',
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownFilter<int?>(
                    value: _selectedClassId,
                    items: [null, ..._classes.map((c) => c.id)],
                    itemLabels: {null: 'Tất cả lớp', for (var c in _classes) c.id: c.className},
                    onChanged: (v) {
                      _selectedClassId = v;
                      _fetchData();
                    },
                    label: 'Lớp',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required T value,
    required List<T> items,
    Map<T, String>? itemLabels,
    required ValueChanged<T?> onChanged,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF1565C0)),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabels != null ? itemLabels[item]! : item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildItemCard(RewardDisciplineModel item) {
    final typeStr = item.type.toLowerCase();
    final isReward = typeStr.contains('reward') || typeStr.contains('khen');
    final mainColor = isReward ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: mainColor.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: mainColor.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(isReward ? Icons.military_tech_rounded : Icons.gavel_rounded, color: mainColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  isReward ? 'KHEN THƯỞNG' : 'KỶ LUẬT',
                  style: TextStyle(color: mainColor, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
                const Spacer(),
                Text(
                  item.date,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Đối tượng:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            item.userName ?? 'N/A',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A3C6E)),
                          ),
                          Text(
                            'Lớp: ${item.className ?? "N/A"}',
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey[600], fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    if (item.decisionNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          'SỐ QĐ: ${item.decisionNumber}',
                          style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Nội dung:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  item.content,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Chưa có dữ liệu phù hợp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
