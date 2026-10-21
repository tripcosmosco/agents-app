class UserModel {
  final int id;
  final String name;
  final String email;
  final String username;
  final String role; // 'administrator' | 'tc_sales_manager' | 'tc_sales_agent' | 'tcfp_manager' | 'tc_dispatcher'
  final String roleLabel;
  final String avatarUrl;
  final List<String> permissions;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    required this.roleLabel,
    required this.avatarUrl,
    required this.permissions,
  });

  bool get isAdmin => role == 'administrator' || role == 'editor';
  bool get isManager => isAdmin || role == 'tc_sales_manager';
  bool get isFinance => isAdmin || role == 'tcfp_manager' || role == 'tcfp_accountant';
  bool get isDispatcher => isAdmin || role == 'tc_dispatcher';
  bool get isSalesAgent => isAdmin || isManager || role == 'tc_sales_agent';

  bool hasPermission(String perm) => permissions.contains('all') || permissions.contains(perm);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Agent',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString().toLowerCase() ?? 'tc_sales_agent',
      roleLabel: json['role_label']?.toString() ?? 'Sales Representative',
      avatarUrl: json['avatar_url']?.toString() ?? '',
      permissions: (json['permissions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['leads_view', 'dialer', 'whatsapp'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'role': role,
        'role_label': roleLabel,
        'avatar_url': avatarUrl,
        'permissions': permissions,
      };
}
