import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:myfschools/models/event_model.dart';
import 'package:myfschools/services/event_service.dart';
import 'package:myfschools/untils/icon_color_util.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;

  static const _blue = Color(0xFF1565C0);
  static const _blueLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1C1C1E);
  static const _hint = Color(0xFF8E8E93);
  static const _bg = Color(0xFFF0F4FF);
  static const _orange = Color(0xFFF26B21);
  static const _green = Color(0xFF2E7D32);

  int _selectedFilter = 0;
  final List<String> _filters = ['Tất cả', 'Sắp tới', 'Đang diễn ra', 'Đã kết thúc'];

  final EventService _eventService = EventService();
  List<EventModel> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  Future<void> _fetchEvents() async {
    try {
      final events = await _eventService.getAllEvents();
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching events: $e');
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  List<EventModel> get _filteredEvents {
    if (_selectedFilter == 0) return _allEvents;
    final status = _filters[_selectedFilter];
    return _allEvents.where((e) => e.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final events = _filteredEvents;
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blue.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _orange.withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                const SizedBox(height: 8),
                _buildFilterRow(),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : events.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _fetchEvents,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: events.length,
                                itemBuilder: (_, i) => _buildEventCard(events[i], i),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: _text),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sự kiện',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _text, letterSpacing: 0.2),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_note_rounded, size: 14, color: _blue),
                const SizedBox(width: 5),
                Text(
                  '${_allEvents.length} sự kiện',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final sel = _selectedFilter == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedFilter = i);
                _entryCtrl.forward(from: 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? _blue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? _blue : const Color(0xFFE0E0E0)),
                  boxShadow: sel
                      ? [BoxShadow(color: _blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : _hint,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: _blueLight, shape: BoxShape.circle),
            child: const Icon(Icons.event_busy_rounded, size: 40, color: _blue),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không có sự kiện nào',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text),
          ),
          const SizedBox(height: 6),
          Text(
            'Không tìm thấy sự kiện "${_filters[_selectedFilter]}"',
            style: const TextStyle(fontSize: 13, color: _hint),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event, int index) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, __) {
        final delay = (index * 0.06).clamp(0.0, 0.5);
        final t = Curves.easeOutCubic.transform(
          ((_entryCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: _eventCardContent(event),
          ),
        );
      },
    );
  }

  Widget _eventCardContent(EventModel event) {
    final eventColor = IconColorUtil.parseColor(event.color);
    final eventIcon = IconColorUtil.parseIcon(event.icon);
    Color statusColor;
    IconData statusIcon;

    switch (event.status) {
      case 'Đang diễn ra':
        statusColor = _green;
        statusIcon = Icons.play_circle_rounded;
        break;
      case 'Đã kết thúc':
        statusColor = _hint;
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = _blue;
        statusIcon = Icons.upcoming_rounded;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showEventDetail(event, statusColor, statusIcon);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: eventColor.withOpacity(0.12), width: 1.5),
          boxShadow: [
            BoxShadow(color: eventColor.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [eventColor, eventColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(eventIcon, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            event.category,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _infoItem(Icons.calendar_today_rounded, event.date, eventColor),
                      const SizedBox(width: 16),
                      _infoItem(Icons.access_time_rounded, event.time, eventColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: _hint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(fontSize: 12, color: _hint, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 11, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              event.status,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
                            ),
                          ],
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

  Widget _infoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _text)),
      ],
    );
  }

  void _showEventDetail(EventModel event, Color statusColor, IconData statusIcon) {
    final eventColor = IconColorUtil.parseColor(event.color);
    final eventIcon = IconColorUtil.parseIcon(event.icon);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(eventIcon, size: 24, color: eventColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _text, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: eventColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              event.category,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: eventColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 11, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  event.status,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.calendar_today_rounded, 'Ngày', event.date, eventColor),
            const SizedBox(height: 12),
            _detailRow(Icons.access_time_rounded, 'Thời gian', event.time, eventColor),
            const SizedBox(height: 12),
            _detailRow(Icons.location_on_outlined, 'Địa điểm', event.location, eventColor),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mô tả',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _hint),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 13.5, color: _text, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: eventColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Đóng',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: _hint, fontWeight: FontWeight.w500)),
            const SizedBox(height: 1),
            Text(
              value,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)),
            ),
          ],
        ),
      ],
    );
  }
}
