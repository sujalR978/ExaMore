import 'package:flutter/material.dart';

import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';

class SupportOverviewScreen extends StatefulWidget {
  const SupportOverviewScreen({super.key});

  @override
  State<SupportOverviewScreen> createState() => _SupportOverviewScreenState();
}

class _SupportOverviewScreenState extends State<SupportOverviewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleTicketTap(String ticketTitle) {
    print('Tapped ticket: $ticketTitle');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    // Active Queue Tickets data
    final List<_SupportTicketData> tickets = [
      _SupportTicketData(
        title: 'Exam technical error',
        name: 'Alice Johnson',
        id: '#TK-8492',
        time: '10 mins ago',
        priority: 'High Priority',
        priorityBg: const Color(0xFFFEF2F2),
        priorityText: const Color(0xFFDC2626),
        status: 'Open',
        statusBg: const Color(0xFFE0E7FF),
        statusText: const Color(0xFF3730A3),
        initials: 'AJ',
        avatarBg: const Color(0xFFFEE2E2),
        avatarTextColor: const Color(0xFFDC2626),
        hasLeftBorderAccent: true,
      ),
      _SupportTicketData(
        title: 'Unable to access syllabus PDF',
        name: 'Marcus Reed',
        id: '#TK-8488',
        time: '45 mins ago',
        priority: 'Medium Priority',
        priorityBg: const Color(0xFFFEF3C7),
        priorityText: const Color(0xFFB45309),
        status: 'Pending',
        statusBg: const Color(0xFFE2E8F0),
        statusText: const Color(0xFF475569),
        initials: 'MR',
        avatarBg: const Color(0xFFFEF3C7),
        avatarTextColor: const Color(0xFFB45309),
        hasLeftBorderAccent: false,
      ),
      _SupportTicketData(
        title: 'Question regarding module 3 quiz',
        name: 'Sarah Lin',
        id: '#TK-8475',
        time: '2 hours ago',
        priority: 'Low Priority',
        priorityBg: const Color(0xFFE0E7FF),
        priorityText: const Color(0xFF1D4ED8),
        status: 'Open',
        statusBg: const Color(0xFFE0E7FF),
        statusText: const Color(0xFF3730A3),
        initials: 'SL',
        avatarBg: const Color(0xFFDBEAFE),
        avatarTextColor: const Color(0xFF1D4ED8),
        hasLeftBorderAccent: false,
      ),
    ];

    // Filter tickets by search query
    final filteredTickets = tickets.where((ticket) {
      return ticket.title.toLowerCase().contains(_searchQuery) ||
          ticket.name.toLowerCase().contains(_searchQuery) ||
          ticket.id.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      key: _scaffoldKey,
     drawer: AdminMenuDrawer(),
      // Capsule-shaped Top Bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.menu, color: textColor),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  title: Text(
                    'Support Center',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: const NetworkImage(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Support Overview',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Monitor real-time system health and manage escalated student requests.',
              style: TextStyle(color: subtitleColor, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Top Metric Cards (Vertical Stack matching screenshot)
            _buildMetricCard(
              icon: Icons.error_outline,
              iconBg: const Color(0xFFFEE2E2),
              iconColor: const Color(0xFFDC2626),
              value: '14',
              label: 'Open Tickets',
              badgeText: '+2 today',
              badgeColor: const Color(0xFFDC2626),
              badgeBg: const Color(0xFFFEF2F2),
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),

            _buildMetricCard(
              icon: Icons.access_time_filled_outlined,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              value: '5',
              label: 'Pending Review',
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),

            _buildMetricCard(
              icon: Icons.timer_outlined,
              iconBg: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF1D4ED8),
              value: '15m',
              label: 'Avg Response Time',
              badgeText: '-2m',
              badgeColor: const Color(0xFF059669),
              badgeBg: const Color(0xFFD1FAE5),
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 28),

            // Active Queue Section Container Box
            Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header & Search Bar
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Queue',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor),
                              ),
                              child: Icon(
                                Icons.filter_list,
                                size: 18,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Requires immediate attention',
                          style: TextStyle(color: subtitleColor, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search tickets...",
                            hintStyle: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: subtitleColor,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: subtitleColor,
                                      size: 18,
                                    ),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            filled: true,
                            fillColor: isDarkMode
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF7C3AED),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ticket List Items
                  if (filteredTickets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: Center(
                        child: Text(
                          'No tickets found matching "$_searchQuery"',
                          style: TextStyle(color: subtitleColor, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTickets.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: borderColor),
                      itemBuilder: (context, index) {
                        final ticket = filteredTickets[index];
                        return _buildTicketItem(
                          ticket: ticket,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          borderColor: borderColor,
                          isDarkMode: isDarkMode,
                          onTap: () => _handleTicketTap(ticket.title),
                        );
                      },
                    ),

                  // Footer Pagination
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing 1–3 of 19 tickets',
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.chevron_left,
                              size: 18,
                              color: subtitleColor,
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: textColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBg,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    badgeText.startsWith('+')
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 14,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTicketItem({
    required _SupportTicketData ticket,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: ticket.hasLeftBorderAccent
              ? const Border(
                  left: BorderSide(color: Color(0xFFDC2626), width: 4),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: ticket.avatarBg,
                  child: Text(
                    ticket.initials,
                    style: TextStyle(
                      color: ticket.avatarTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            ticket.name,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ticket.id,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: subtitleColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            ticket.time,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ticket.priorityBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.priority,
                    style: TextStyle(
                      color: ticket.priorityText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ticket.statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.status,
                    style: TextStyle(
                      color: ticket.statusText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTicketData {
  final String title;
  final String name;
  final String id;
  final String time;
  final String priority;
  final Color priorityBg;
  final Color priorityText;
  final String status;
  final Color statusBg;
  final Color statusText;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final bool hasLeftBorderAccent;

  _SupportTicketData({
    required this.title,
    required this.name,
    required this.id,
    required this.time,
    required this.priority,
    required this.priorityBg,
    required this.priorityText,
    required this.status,
    required this.statusBg,
    required this.statusText,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.hasLeftBorderAccent,
  });
}
