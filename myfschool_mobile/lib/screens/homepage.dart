import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:myfschools/screens/contact_list_screen.dart';
import 'package:myfschools/screens/event_screen.dart';
import 'package:myfschools/screens/grade_screen.dart';
import 'package:myfschools/screens/profilepage.dart';
import 'package:myfschools/screens/reward_discipline_screen.dart';
import 'package:myfschools/screens/send_request_screen.dart';
import 'package:myfschools/screens/timetable_screen.dart';
import 'package:myfschools/services/user_session.dart';
import 'package:myfschools/models/news_model.dart';
import 'package:myfschools/services/news_api.dart';
import 'admin_request_list_screen.dart';
import 'news_detail_screen.dart';
import 'news_list_screen.dart';

const _bgColor = Color(0xFFF4F6FB);
const _textColor = Color(0xFF1E1E1E);
const _subTextColor = Color(0xFF8A94A6);
const _primaryBlue = Color(0xFF2C7BEF);
const _sectionBar = Color(0xFF4B89F5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = UserSession.instance.currentUser;
    final fullName = UserSession.instance.fullName.isNotEmpty
        ? UserSession.instance.fullName
        : (user?.username ?? 'Người dùng');
    final studentCode = user?.studentCode ?? user?.username ?? 'adnn';
    final className = user?.className ?? 'Lớp 9A1';
    final isAdmin = user?.role == 'Admin';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: IndexedStack(
          index: _tabIndex,
          children: [
            // Tab 0: Home
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderCard(
                            fullName: fullName,
                            studentCode: studentCode,
                            className: className,
                          ),
                          const SizedBox(height: 18),
                          _FeatureSection(isAdmin: isAdmin),
                          const SizedBox(height: 18),
                          const _NoticeHeader(),
                          const SizedBox(height: 12),
                          const _NewsAnnouncementCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 1: Messages (Placeholder)
            const Center(child: Text('Màn hình tin nhắn sẽ cập nhật sau')),
            // Tab 2: News
            const NewsListScreen(),
          ],
        ),
        bottomNavigationBar: _BottomNavBar(
          index: _tabIndex,
          onChanged: (i) {
            if (i == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              return;
            }
            setState(() => _tabIndex = i);
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String fullName;
  final String studentCode;
  final String className;

  const _HeaderCard({
    required this.fullName,
    required this.studentCode,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D7AE8), Color(0xFF4BA9F4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D7AE8).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.65),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.95),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MSHS: $studentCode',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      _MiniChip(
                        text: className,
                        background: Colors.white.withOpacity(0.22),
                        textColor: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const _MiniChip(
                        text: 'FPT School',
                        background: Color(0xFFE94A47),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.28),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC531),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color background;
  final Color textColor;

  const _MiniChip({
    required this.text,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BlueSectionBar extends StatelessWidget {
  const _BlueSectionBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3.5,
      height: 18,
      decoration: BoxDecoration(
        color: _sectionBar,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  final bool isAdmin;

  const _FeatureSection({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final items = [
      _FeatureItemData(
        label: isAdmin ? 'Xem đơn' : 'Xem đơn',
        icon: Icons.receipt_long_rounded,
        colors: const [Color(0xFF2DB1F3), Color(0xFF1687D8)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
            isAdmin ? const AdminRequestListScreen() : const SendRequestScreen(),
          ),
        ),
      ),
      _FeatureItemData(
        label: 'Sự kiện',
        icon: Icons.celebration_outlined,
        colors: const [Color(0xFFFFA726), Color(0xFFF28C00)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventScreen()),
        ),
      ),
      _FeatureItemData(
        label: 'Lịch học',
        icon: Icons.calendar_month_outlined,
        colors: const [Color(0xFFE63888), Color(0xFFD81B76)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TimetableScreen()),
        ),
      ),
      _FeatureItemData(
        label: 'Liên Lạc',
        icon: Icons.chat_bubble_outline_rounded,
        colors: const [Color(0xFFEF5350), Color(0xFFD7191C)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContactListScreen()),
        ),
      ),
      _FeatureItemData(
        label: 'KT&KL',
        icon: Icons.emoji_events_outlined,
        colors: const [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RewardDisciplineScreen()),
        ),
      ),
      _FeatureItemData(
        label: 'Bảng điểm',
        icon: Icons.menu_book_outlined,
        colors: const [Color(0xFFFF7043), Color(0xFFD84315)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GradeScreen()),
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _BlueSectionBar(),
              SizedBox(width: 10),
              Text(
                'Chức năng',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (_, index) => _FeatureItem(data: items[index]),
          ),
        ],
      ),
    );
  }
}

class _FeatureItemData {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _FeatureItemData({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });
}

class _FeatureItem extends StatelessWidget {
  final _FeatureItemData data;

  const _FeatureItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        data.onTap();
      },
      child: Column(
        children: [
          Container(
            height: 82,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: data.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.colors.last.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    data.icon,
                    color: Colors.white,
                    size: 33,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeHeader extends StatelessWidget {
  const _NoticeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Tin Tức',
          style: TextStyle(
            color: _textColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        // InkWell(
        //   onTap: () {},
        //   child: const Row(
        //     children: [
        //       Text(
        //         'Xem tất cả',
        //         style: TextStyle(
        //           color: Color(0xFF2A6DEB),
        //           fontSize: 13,
        //           fontWeight: FontWeight.w600,
        //         ),
        //       ),
        //       SizedBox(width: 2),
        //       Icon(
        //         Icons.chevron_right_rounded,
        //         color: Color(0xFF2A6DEB),
        //         size: 18,
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}

class _NewsAnnouncementCard extends StatefulWidget {
  const _NewsAnnouncementCard();

  @override
  State<_NewsAnnouncementCard> createState() => _NewsAnnouncementCardState();
}

class _NewsAnnouncementCardState extends State<_NewsAnnouncementCard> {
  NewsModel? _latestNews;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestNews();
  }

  Future<void> _loadLatestNews() async {
    final newsList = await NewsApi.instance.getAllNews();
    if (mounted) {
      setState(() {
        if (newsList.isNotEmpty) {
          _latestNews = newsList.first;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(child: CircularProgressIndicator(color: _primaryBlue)),
      );
    }

    if (_latestNews == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailScreen(news: _latestNews!)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD32F2F).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFFD32F2F),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'FPT',
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _latestNews!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white.withOpacity(0.8)),
                                    const SizedBox(width: 5),
                                    Text('Nghỉ từ ngày', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text('29/04/2026', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                                Text('-> 03/05/2026', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.school_rounded, size: 12, color: Colors.white.withOpacity(0.8)),
                                    const SizedBox(width: 5),
                                    Text('Trở lại trường', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text('Thứ Hai', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                                const Text('04/05/2026', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCCCC), width: 1),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Color(0xFFD32F2F), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _latestNews!.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
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

class _RedInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _RedInfoBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white.withOpacity(0.85)),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _BottomNavBar({
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Trang chủ'),
      (Icons.mail_outline_rounded, 'Tin nhắn'),
      (Icons.new_label_outlined, 'Tin tức'),
      (Icons.person_outline_rounded, 'Cá nhân'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final (icon, label) = items[i];
              final selected = i == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFDCEBFF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 24,
                          color: selected ? _primaryBlue : const Color(0xFF9E9E9E),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? _primaryBlue : const Color(0xFF9E9E9E),
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}