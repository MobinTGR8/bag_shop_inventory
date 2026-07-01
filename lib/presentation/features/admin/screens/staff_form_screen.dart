import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../../../../data/repositories/staff_repository.dart';
import '../providers/admin_staff_provider.dart';

// Permission helpers (shared with staff_management_screen)
const _permissionGroupLabels = <String, String>{
  'inventory.view': 'View inventory',
  'inventory.edit': 'Edit inventory',
  'products.view': 'View products',
  'products.edit': 'Edit products',
  'customers.view': 'View customers',
  'customers.edit': 'Edit customers',
  'sales.view': 'View sales',
  'sales.pos': 'POS / Sell',
  'purchases.view': 'View purchases',
  'purchases.edit': 'Edit purchases',
  'reports.view': 'Reports',
  'staff.manage': 'Manage staff',
};

const _permissionGroups = <String, List<String>>{
  'Inventory': ['inventory.view', 'inventory.edit'],
  'Products': ['products.view', 'products.edit'],
  'Customers': ['customers.view', 'customers.edit'],
  'Sales': ['sales.view', 'sales.pos'],
  'Purchases': ['purchases.view', 'purchases.edit'],
  'Reports': ['reports.view'],
  'Admin': ['staff.manage'],
};

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

class StaffFormScreen extends ConsumerStatefulWidget {
  final String? staffId;

  const StaffFormScreen({super.key, this.staffId});

  bool get isEditing => staffId != null;

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  UserRole _selectedRole = UserRole.staff;
  Set<String> _selectedPermissions = {};
  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.isEditing) {
      setState(() => _isLoading = true);
      _loadStaff();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    final staff = await ref.read(staffRepositoryProvider).getStaff(
          staffId: widget.staffId!,
        );
    if (staff != null && mounted) {
      setState(() {
        _nameController.text = staff.name;
        _emailController.text = staff.email ?? '';
        _phoneController.text = staff.phone ?? '';
        _selectedRole = staff.role;
        _selectedPermissions = Set.from(staff.permissions);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name is required'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isEditing) {
        await ref.read(staffRepositoryProvider).updateStaffRole(
              staffId: widget.staffId!,
              role: _selectedRole,
            );
        await ref.read(staffRepositoryProvider).updateStaffPermissions(
              staffId: widget.staffId!,
              permissions: _selectedPermissions.toList(),
            );

        // Update name/email/phone via a direct update
        await ref.read(staffRepositoryProvider).updateStaffName(
              staffId: widget.staffId!,
              name: name,
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
            );

        ref.invalidate(staffListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff updated'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        }
      } else {
        final companyId = ref.read(companyIdProvider);
        if (companyId == null) {
          throw const AppException('No company found');
        }

        await ref.read(staffRepositoryProvider).createStaff(
              companyId: companyId,
              name: name,
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              role: _selectedRole,
              permissions: _selectedPermissions.toList(),
            );

        ref.invalidate(staffListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff added successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.handle(e)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Staff' : 'Add Staff'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.person_outline, size: 18)),
            Tab(
                text: 'Permissions',
                icon: Icon(Icons.shield_outlined, size: 18)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.isEditing ? 'Save' : 'Add Staff'),
            ),
          ),
        ],
      ),
      body: _isLoading && widget.isEditing
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(scheme),
                _buildPermissionsTab(scheme),
              ],
            ),
    );
  }

  Widget _buildProfileTab(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role selector card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _roleColor(_selectedRole, scheme).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _roleColor(_selectedRole, scheme).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _roleColor(_selectedRole, scheme).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.isEditing
                        ? Icons.badge_outlined
                        : Icons.person_add_alt_1,
                    color: _roleColor(_selectedRole, scheme),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEditing ? 'Edit Staff Member' : 'New Staff Member',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedRole.toDb(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _roleColor(_selectedRole, scheme),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isEditing)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Form fields
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full name *',
              hintText: 'Enter staff name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'staff@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: 'e.g. 017XXXXXXXX',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),

          // Role selector
          DropdownButtonFormField<UserRole>(
            value: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: UserRole.values
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        Icon(
                          _roleIcon(role),
                          size: 18,
                          color: _roleColor(role, scheme),
                        ),
                        const SizedBox(width: 8),
                        Text(role.toDb()),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (role) {
              if (role != null) setState(() => _selectedRole = role);
            },
          ),
          const SizedBox(height: 24),

          if (!widget.isEditing)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.tertiary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.tertiary.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: scheme.tertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Staff will be able to log in after an admin links their account.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withOpacity(0.6),
                            height: 1.3,
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

  Widget _buildPermissionsTab(ColorScheme scheme) {
    final categoryCount = _permissionGroups.entries.map((e) {
      final matched =
          e.value.where((p) => _selectedPermissions.contains(p)).length;
      return '${e.key} ($matched/${e.value.length})';
    }).join('  •  ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 18, color: scheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Permissions: $_selectedPermissions / 11 selected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ),
                if (_selectedPermissions.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selectedPermissions = {}),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear all', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (_selectedPermissions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                categoryCount,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
              ),
            ),
          const SizedBox(height: 8),

          // Permission groups
          for (final group in _permissionGroups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Text(group.key,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          )),
                  const Spacer(),
                  Text(
                    '${group.value.where((p) => _selectedPermissions.contains(p)).length}/${group.value.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.4),
                        ),
                  ),
                ],
              ),
            ),
            for (final perm in group.value)
              CheckboxListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 4, right: 0),
                visualDensity: VisualDensity.compact,
                value: _selectedPermissions.contains(perm),
                title: Text(
                  _permissionGroupLabels[perm] ?? perm,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedPermissions.add(perm);
                    } else {
                      _selectedPermissions.remove(perm);
                    }
                  });
                },
              ),
          ],
          const SizedBox(height: 24),

          // Select by role preset
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outline.withOpacity(0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined,
                        size: 16, color: scheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text(
                      'Quick presets',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PresetChip(
                      label: 'Staff (basic)',
                      onTap: () => setState(() {
                        _selectedPermissions = {
                          'inventory.view',
                          'products.view',
                          'sales.view',
                          'sales.pos',
                        };
                      }),
                    ),
                    _PresetChip(
                      label: 'Manager (full)',
                      onTap: () => setState(() {
                        _selectedPermissions = {
                          'inventory.view',
                          'inventory.edit',
                          'products.view',
                          'products.edit',
                          'customers.view',
                          'customers.edit',
                          'sales.view',
                          'sales.pos',
                          'purchases.view',
                          'purchases.edit',
                          'reports.view',
                          'staff.manage',
                        };
                      }),
                    ),
                    _PresetChip(
                      label: 'Accountant',
                      onTap: () => setState(() {
                        _selectedPermissions = {
                          'purchases.view',
                          'reports.view',
                        };
                      }),
                    ),
                    _PresetChip(
                      label: 'View only',
                      onTap: () => setState(() {
                        _selectedPermissions = {
                          'inventory.view',
                          'products.view',
                          'customers.view',
                          'sales.view',
                          'purchases.view',
                          'reports.view',
                        };
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _roleIcon(UserRole role) {
  switch (role) {
    case UserRole.owner:
      return Icons.verified_outlined;
    case UserRole.manager:
      return Icons.admin_panel_settings_outlined;
    case UserRole.accountant:
      return Icons.calculate_outlined;
    case UserRole.staff:
      return Icons.badge_outlined;
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
