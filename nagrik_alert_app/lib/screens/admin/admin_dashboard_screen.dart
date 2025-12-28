import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../models/incident_model.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<IncidentProvider>();
    await provider.loadIncidents();
    await provider.loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.account_circle, color: AppTheme.secondaryColor),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'profile') {
                // Show profile dialog
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                          child: Text(
                            authProvider.user?.name?.substring(0, 1).toUpperCase() ?? 'A',
                            style: const TextStyle(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Admin Profile'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person, color: AppTheme.secondaryColor),
                          title: const Text('Name'),
                          subtitle: Text(authProvider.user?.name ?? 'Admin'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email, color: AppTheme.secondaryColor),
                          title: const Text('Email'),
                          subtitle: Text(authProvider.user?.email ?? 'N/A'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.admin_panel_settings, color: AppTheme.secondaryColor),
                          title: const Text('Role'),
                          subtitle: Text(authProvider.user?.role?.toUpperCase() ?? 'ADMIN'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              } else if (value == 'logout') {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.verified), text: 'Verified'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _IncidentsTab(status: 'Unverified'),
          _IncidentsTab(status: 'Verified'),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistics;

        if (stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total',
                      value: '${stats['total_incidents'] ?? 0}',
                      icon: Icons.assessment,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Today',
                      value: '${stats['last_24_hours'] ?? 0}',
                      icon: Icons.today,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Verified',
                      value: '${stats['by_status']?['verified'] ?? 0}',
                      icon: Icons.verified,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Pending',
                      value: '${stats['by_status']?['unverified'] ?? 0}',
                      icon: Icons.pending,
                      color: AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Resolved',
                      value: '${stats['by_status']?['resolved'] ?? 0}',
                      icon: Icons.check_circle,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // By Type
              const Text(
                'Incidents by Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildTypeChart(stats['by_type'] ?? {}),
              const SizedBox(height: 24),
              // Critical Incidents
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Critical Incidents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${provider.criticalIncidents.length}',
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (provider.criticalIncidents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 12),
                      const Text('No critical incidents at this time'),
                    ],
                  ),
                )
              else
                ...provider.criticalIncidents.take(3).map(
                      (incident) => _CriticalIncidentCard(incident: incident),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeChart(Map<String, dynamic> typeData) {
    final types = ['Fire', 'Accident', 'Medical', 'Infrastructure'];
    final colors = [
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.blue,
    ];
    final emojis = ['🔥', '🚗', '🏥', '🏗️'];

    int total = 0;
    for (var type in types) {
      total += (typeData[type] ?? 0) as int;
    }
    if (total == 0) total = 1;

    return Column(
      children: List.generate(types.length, (index) {
        final count = (typeData[types[index]] ?? 0) as int;
        final percentage = (count / total * 100).toStringAsFixed(0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emojis[index], style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(types[index]),
                  const Spacer(),
                  Text(
                    '$count ($percentage%)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: count / total,
                backgroundColor: colors[index].withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(colors[index]),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _IncidentsTab extends StatelessWidget {
  final String status;

  const _IncidentsTab({required this.status});

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentProvider>(
      builder: (context, provider, child) {
        final incidents = status == 'Unverified'
            ? provider.unverifiedIncidents
            : provider.verifiedIncidents;

        if (incidents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'Unverified' ? Icons.pending_outlined : Icons.verified_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status.toLowerCase()} incidents',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadIncidents();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              return _AdminIncidentCard(incident: incidents[index]);
            },
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CriticalIncidentCard extends StatelessWidget {
  final IncidentModel incident;

  const _CriticalIncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.red.shade50,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(incident.typeEmoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(incident.type),
        subtitle: Text(
          incident.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Sev ${incident.severity}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminIncidentCard extends StatelessWidget {
  final IncidentModel incident;

  const _AdminIncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(incident.typeEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.type,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${incident.id.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(incident.severityColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sev ${incident.severity}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(incident.severityColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              incident.description,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${incident.latitude.toStringAsFixed(4)}, ${incident.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(context, 'Verified'),
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Verify'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(context, 'Resolved'),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Resolve'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _updateStatus(context, 'Rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    final authProvider = context.read<AuthProvider>();
    final provider = context.read<IncidentProvider>();

    final success = await provider.updateIncidentStatus(
      incidentId: incident.id,
      newStatus: newStatus,
      adminId: authProvider.user?.id ?? 'admin',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status updated to $newStatus'
                : 'Failed to update status',
          ),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }
}
