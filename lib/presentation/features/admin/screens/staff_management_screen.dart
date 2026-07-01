import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../data/models/staff/staff_member_model.dart';
import '../../../../data/repositories/staff_repository.dart';
import '../providers/admin_staff_provider.dart';

// ---------------------------------------------------------------------------
// Role colour helpers
// ---------------------------------------------------------------------------
Color _roleColor(UserRole role, ColorScheme scheme) {
  switch (role) {
    case UserRole.owner:
      return const Color(0xFF7C3AED);
    case UserRole.manager:
      return const Color(0xFF2563EB);
    case UserRole.accountant:
      return const Color(0xFF059669);
    case UserRole.staff:
      return const Color(0xFFD97706);
  }
}

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  final _searchController = TextEditingController();

  // Filter state
  UserRole? _roleFilter;
  bool? _activeFilter; // null = all, true = active, false = inactive

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------
  String get _query => _searchController.text.trim().toLowerCase();

  List<StaffMemberModel> _filterStaff(List<StaffMemberModel> all) {
    var result = all;
    if (_query.isNotEmpty) {
      result = result.where((s) {
        return s.name.toLowerCase().contains(_query) ||
            (s.email?.toLowerCase().contains(_query) ?? false);
      }).toList();
    }
    if (_roleFilter != null) {
      result = result.where((s) => s.role == _roleFilter).toList();
    }
    if (_activeFilter != null) {
      result = result.where((s) => s.isActive == _activeFilter).toList();
    }
    return result;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _roleFilter = null;
      _activeFilter = null;
    });
  }

  bool get _hasActiveFilters =>
      _query.isNotEmpty || _roleFilter != null || _activeFilter != null;

  // -----------------------------------------------------------------------
  // Staff summary header
  // -----------------------------------------------------------------------
  Map<UserRole, int> _roleBreakdown(List<StaffMemberModel> all) {
    final map = <UserRole, int>{};
    for (final role in UserRole.values) {
      map[role] = all.where((s) => s.role == role).length;
    }
    return map;
  }

  // -----------------------------------------------------------------------
  // Actions
  // -----------------------------------------------------------------------
  Future<void> _deleteStaff(StaffMemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete staff member?'),
        content: Text(
            'This will permanently remove ${member.name} from the company.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(staffRepositoryProvider)
        .deleteStaff(staffId: member.id);
    ref.invalidate(staffListProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.name} deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleActive(StaffMemberModel member) async {
    await ref
        .read(staffRepositoryProvider)
        .setStaffActive(
          staffId: member.id,
          isActive: !member.isActive,
        );
    ref.invalidate(staffListProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            member.isActive ? '${member.name} deactivated' : '${member.name} activated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showStaffMenu(StaffMemberModel member) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final roleColor = _roleColor(member.role, scheme);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: roleColor.withOpacity(0.15),
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            Text(member.role.toDb(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: roleColor,
                                      fontWeight: FontWeight.w600,
                                    )),
                          ],
                        ),
                      ),
                      if (member.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Active',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: const Color(0xFF10B981))),
                        ),
                    ],
                  ),
                ),
                const Divider(),

                // Edit
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit role & permissions'),
                  subtitle: const Text('Open detailed editor'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/admin/staff/${member.id}/edit');
                  },
                ),

                // Toggle active
                ListTile(
                  leading: Icon(
                    member.isActive
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                    color: member.isActive
                        ? scheme.error
                        : const Color(0xFF10B981),
                  ),
                  title: Text(member.isActive ? 'Deactivate' : 'Activate'),
                  subtitle: Text(member.isActive
                      ? 'Revoke access temporarily'
                      : 'Restore access'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _toggleActive(member);
                  },
                ),

                // Delete
                ListTile(
                  leading: Icon(Icons.delete_outline, color: scheme.error),
                  title: Text('Delete',
                      style: TextStyle(color: scheme.error)),
                  subtitle: Text('Permanently remove',
                      style:
                          TextStyle(color: scheme.error.withOpacity(0.6))),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteStaff(member);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/staff/add'),
        icon: const Icon(Icons.person_add_alt_1, size: 20),
        label: const Text('Add Staff'),
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Filter chips
          _buildFilterChips(),

          // Staff list
          Expanded(
            child: staffAsync.when(
              data: (allStaff) => _buildStaffList(allStaff),
              loading: () => const AppBody(child: LoadingIndicator()),
              error: (e, _) => AppBody(
                child: ErrorState(
                  title: 'Failed to load staff',
                  message: e.toString(),
                  onRetry: () => ref.invalidate(staffListProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Search & filters
  // -----------------------------------------------------------------------
  Widget _buildSearchBar() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by name or email…',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _hasActiveFilters
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: _clearFilters,
                )
              : null,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outline.withOpacity(0.4)),
          ),
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          for (final role in UserRole.values) ...[
            _FilterChip(
              label: role.toDb(),
              selected: _roleFilter == role,
              color: _roleColor(role, scheme),
              onSelected: () {
                setState(() =>
                    _roleFilter = _roleFilter == role ? null : role);
              },
            ),
            const SizedBox(width: 6),
          ],
          _FilterChip(
            label: 'Active',
            selected: _activeFilter == true,
            color: const Color(0xFF10B981),
            onSelected: () {
              setState(() =>
                  _activeFilter = _activeFilter == true ? null : true);
            },
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Inactive',
            selected: _activeFilter == false,
            color: scheme.error,
            onSelected: () {
              setState(() =>
                  _activeFilter = _activeFilter == false ? null : false);
            },
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: 6),
            ActionChip(
              label: const Text('Clear'),
              avatar: const Icon(Icons.close, size: 14),
              onPressed: _clearFilters,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Staff list with rich cards
  // -----------------------------------------------------------------------
  Widget _buildStaffList(List<StaffMemberModel> allStaff) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final staff = _filterStaff(allStaff);

    if (allStaff.isEmpty) {
      return AppBody(
        child: EmptyState(
          title: 'No staff yet',
          message: 'Tap the button below to add your first team member.',
          icon: Icons.people_outline,
          action: FilledButton.icon(
            onPressed: () => context.push('/admin/staff/add'),
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Add Staff'),
          ),
        ),
      );
    }

    // Summary header
    final roleCounts = _roleBreakdown(allStaff);
    final activeCount = allStaff.where((s) => s.isActive).length;

    return Column(
      children: [
        // Summary bar
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _SummaryStat(
                label: 'Total',
                value: '${allStaff.length}',
                icon: Icons.people_outline,
                color: scheme.onSurface,
              ),
              const SizedBox(width: 12),
              _SummaryStat(
                label: 'Active',
                value: '$activeCount',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in roleCounts.entries
                          .where((e) => e.value > 0))
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      _roleColor(entry.key, scheme),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.key.toDb().substring(0, 3)}: ${entry.value}',
                                style: tt.labelSmall?.copyWith(
                                  color: scheme.onSurface.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Staff list
        if (staff.isEmpty)
          Expanded(
            child: AppBody(
              child: EmptyState(
                title: 'No matches',
                message: 'Try adjusting your search or filters.',
                icon: Icons.search_off_rounded,
                action: TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  label: const Text('Clear filters'),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(staffListProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: staff.length,
                itemBuilder: (context, index) {
                  final member = staff[index];
                  final roleColor = _roleColor(member.role, scheme);
                  final isActive = member.isActive;

                  return Dismissible(
                    key: ValueKey(member.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFF59E0B).withOpacity(0.15)
                            : const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isActive
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                        color: isActive
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                        size: 28,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      await _toggleActive(member);
                      return false; // Don't remove from list, just toggle
                    },
                    child: StaggeredFadeIn.build(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: scheme.outline.withOpacity(0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () =>
                                  context.push('/admin/staff/${member.id}/edit'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    // Avatar with status dot
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: isActive
                                              ? roleColor.withOpacity(0.12)
                                              : scheme.outline
                                                  .withOpacity(0.08),
                                          child: Text(
                                            member.name.isNotEmpty
                                                ? member.name[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: isActive
                                                  ? roleColor
                                                  : scheme.onSurface
                                                      .withOpacity(0.3),
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        if (isActive)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color:
                                                    const Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: scheme.surface,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),

                                    // Name, role, email
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  member.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: tt.titleSmall
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: isActive
                                                        ? null
                                                        : scheme.onSurface
                                                            .withOpacity(0.5),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              _RoleBadge(
                                                role: member.role,
                                                color: roleColor,
                                              ),
                                            ],
                                          ),
                                          if (member.email != null) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              member.email!,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  tt.bodySmall?.copyWith(
                                                color: scheme.onSurface
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                          ],
                                          if (!isActive) ...[
                                            const SizedBox(height: 3),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: scheme.error
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text('Inactive',
                                                  style: tt.labelSmall
                                                      ?.copyWith(
                                                    fontSize: 10,
                                                    color: scheme.error,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  )),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Menu
                                    IconButton(
                                      icon: Icon(Icons.more_horiz,
                                          color: scheme.onSurface
                                              .withOpacity(0.3),
                                          size: 22),
                                      onPressed: () =>
                                          _showStaffMenu(member),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ===========================================================================
// Small reusable widgets
// ===========================================================================

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  final Color color;
  const _RoleBadge({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toDb(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withOpacity(0.15),
      checkmarkColor: color,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? color : null,
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
