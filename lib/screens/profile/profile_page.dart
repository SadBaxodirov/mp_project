import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/user_test_api.dart';
import '../../core/models/user.dart';
import '../../core/models/user_test.dart';
import '../../features/auth/state/auth_provider.dart';
import '../../router.dart';
import '../../utils/profile_photo_store.dart';
import '../../widgets/main_navigation_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userTestApi = UserTestApi();
  final _photoStore = ProfilePhotoStore.instance;
  final _picker = ImagePicker();

  Uint8List? _photoBytes;
  List<UserTest> _userTests = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'BB';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.login,
            (route) => false,
      );
    }
  }

  Future<void> _loadProfileDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final user = context.read<AuthProvider>().currentUser;
    Uint8List? loadedPhoto;
    List<UserTest> loadedTests = [];

    try {
      if (user?.id != null) {
        loadedPhoto = await _photoStore.loadPhoto(user!.id!);
      }
    } catch (e) {
      debugPrint('Error loading saved photo: $e');
      _error ??= 'Could not load your profile photo.';
    }

    if (user?.id != null) {
      try {
        loadedTests = await _userTestApi.getUserTests(userId: user!.id!);
      } catch (e) {
        debugPrint('Error loading user tests: $e');
        _error ??= 'Could not refresh your latest test stats.';
      }
    }

    if (!mounted) return;
    setState(() {
      _photoBytes = loadedPhoto;
      _userTests = loadedTests;
      _isLoading = false;
    });
  }

  Future<void> _changePhoto() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      _showSnack('Login again to update your photo.');
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    await _photoStore.savePhoto(userId, bytes);

    if (!mounted) return;
    setState(() => _photoBytes = bytes);
    _showSnack('Profile photo saved.');
  }

  Future<void> _openEditInfo() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      _showSnack('Login again to edit your info.');
      return;
    }

    final updatedFields = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditProfileSheet(user: user),
    );

    if (updatedFields == null) return;

    try {
      await context.read<AuthProvider>().updateProfile(
        firstName: updatedFields.firstName,
        lastName: updatedFields.lastName,
        school: updatedFields.school,
        grade: updatedFields.grade,
        phoneNumber: updatedFields.phoneNumber,
      );
      await context.read<AuthProvider>().refreshCurrentUser();
      await _loadProfileDetails();
      _showSnack('Profile updated.');
    } catch (e) {
      _showSnack('Could not update profile.');
      debugPrint('Profile update error: $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  _ProfileStats _buildStats(List<UserTest> tests) {
    if (tests.isEmpty) {
      return const _ProfileStats(
        testsTaken: 0,
        latestDate: null,
        averageTotal: 0,
        averageMath: 0,
        averageEnglish: 0,
      );
    }

    final latest =
    tests.map((t) => t.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
    final totalSum =
    tests.fold<double>(0, (sum, t) => sum + t.mathScore + t.englishScore);
    final mathSum = tests.fold<double>(0, (sum, t) => sum + t.mathScore);
    final englishSum = tests.fold<double>(0, (sum, t) => sum + t.englishScore);
    final count = tests.length.toDouble();

    return _ProfileStats(
      testsTaken: tests.length,
      latestDate: latest,
      averageTotal: totalSum / count,
      averageMath: mathSum / count,
      averageEnglish: englishSum / count,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final name = user?.displayName ?? 'Student';
    final email = user?.email ?? 'No email';
    final stats = _buildStats(_userTests);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileDetails,
          ),
        ],
      ),
      bottomNavigationBar: const MainNavigationBar(currentIndex: 3),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfileDetails,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(
                  name: name,
                  email: email,
                  school: user?.school,
                  grade: user?.grade,
                  initials: _initials(name),
                  photoBytes: _photoBytes,
                  onChangePhoto: _changePhoto,
                  onEditInfo: _openEditInfo,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ErrorChip(message: _error!),
                        ),
                      Row(
                        children: [
                          _ProfileStatCard(
                            label: 'Tests taken',
                            value: stats.testsTaken.toString(),
                            accentColor: const Color(0xFF2557D6),
                          ),
                          const SizedBox(width: 12),
                          _ProfileStatCard(
                            label: 'Average score',
                            value: stats.averageTotal == 0
                                ? '-'
                                : stats.averageTotal.toStringAsFixed(0),
                            accentColor: const Color(0xFF0EA5E9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileStatCard(
                              label: 'Last test date',
                              value: _formatDate(stats.latestDate),
                              accentColor: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ProfileStatCard(
                              label: 'Latest status',
                              value: stats.testsTaken == 0
                                  ? 'No tests yet'
                                  : 'Up to date',
                              accentColor: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ScoreBreakdown(
                        mathAverage: stats.averageMath,
                        englishAverage: stats.averageEnglish,
                      ),
                      const SizedBox(height: 16),
                      _DetailsCard(
                        user: user,
                        onEdit: _openEditInfo,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _changePhoto,
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Change photo'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Log out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
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
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.initials,
    required this.onChangePhoto,
    required this.onEditInfo,
    this.photoBytes,
    this.school,
    this.grade,
  });

  final String name;
  final String email;
  final String initials;
  final Uint8List? photoBytes;
  final String? school;
  final String? grade;
  final VoidCallback onChangePhoto;
  final VoidCallback onEditInfo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 260),
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onChangePhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: const Color(0xFFE5ECFF),
                          backgroundImage: photoBytes != null
                              ? MemoryImage(photoBytes!)
                              : null,
                          child: photoBytes == null
                              ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2557D6),
                            ),
                          )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: onChangePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Color(0xFF2557D6),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (school != null && school!.isNotEmpty)
                    _TagChip(icon: Icons.school, label: school!),
                  if (grade != null && grade!.isNotEmpty)
                    _TagChip(icon: Icons.grade, label: 'Grade $grade'),
                  GestureDetector(
                    onTap: onEditInfo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Edit info',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(color: Color(0xFF475569)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({
    required this.mathAverage,
    required this.englishAverage,
  });

  final double mathAverage;
  final double englishAverage;

  @override
  Widget build(BuildContext context) {
    String format(double value) => value == 0 ? '-' : value.toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score breakdown',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _BreakdownItem(
                    label: 'Reading & Writing',
                    value: format(englishAverage),
                    icon: Icons.menu_book_outlined,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BreakdownItem(
                    label: 'Math',
                    value: format(mathAverage),
                    icon: Icons.calculate_outlined,
                    color: const Color(0xFF10B981),
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

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.user, required this.onEdit});

  final User? user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    String orPlaceholder(String? value) =>
        value == null || value.isEmpty ? 'Not provided' : value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Student details',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Username',
              value: orPlaceholder(user?.username),
            ),
            _DetailRow(
              icon: Icons.school_outlined,
              label: 'School',
              value: orPlaceholder(user?.school),
            ),
            _DetailRow(
              icon: Icons.grade_outlined,
              label: 'Grade',
              value: orPlaceholder(user?.grade),
            ),
            _DetailRow(
              icon: Icons.call_outlined,
              label: 'Phone',
              value: orPlaceholder(user?.phoneNumber),
            ),
            _DetailRow(
              icon: Icons.mail_outline,
              label: 'Email',
              value: orPlaceholder(user?.email),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorChip extends StatelessWidget {
  const _ErrorChip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats {
  const _ProfileStats({
    required this.testsTaken,
    required this.latestDate,
    required this.averageTotal,
    required this.averageMath,
    required this.averageEnglish,
  });

  final int testsTaken;
  final DateTime? latestDate;
  final double averageTotal;
  final double averageMath;
  final double averageEnglish;
}

class _EditResult {
  const _EditResult({
    required this.firstName,
    required this.lastName,
    required this.school,
    required this.grade,
    required this.phoneNumber,
  });

  final String firstName;
  final String lastName;
  final String school;
  final String grade;
  final String phoneNumber;
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});

  final User user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _school;
  late final TextEditingController _grade;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.user.firstName);
    _lastName = TextEditingController(text: widget.user.lastName ?? '');
    _school = TextEditingController(text: widget.user.school ?? '');
    _grade = TextEditingController(text: widget.user.grade ?? '');
    _phone = TextEditingController(text: widget.user.phoneNumber);
    _email = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _school.dispose();
    _grade.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = _EditResult(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      school: _school.text.trim(),
      grade: _grade.text.trim(),
      phoneNumber: _phone.text.trim(),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: viewInsets,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Edit profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _firstName,
                    label: 'First name',
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
                  ),
                  _Field(
                    controller: _lastName,
                    label: 'Last name',
                  ),
                  _Field(
                    controller: _school,
                    label: 'School',
                  ),
                  _Field(
                    controller: _grade,
                    label: 'Grade',
                  ),
                  _Field(
                    controller: _phone,
                    label: 'Phone',
                    keyboardType: TextInputType.phone,
                  ),
                  _Field(
                    controller: _email,
                    label: 'Email (read only)',
                    keyboardType: TextInputType.emailAddress,
                    enabled: false,
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.enabled = true,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        keyboardType: keyboardType,
        enabled: enabled,
        readOnly: readOnly,
      ),
    );
  }
}
