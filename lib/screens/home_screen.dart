import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/password_model.dart';
import '../services/database_helper.dart';
import '../services/premium_service.dart';
import '../services/auth_service.dart';
import '../utils/icon_helper.dart';
import '../utils/category_helper.dart';
import '../utils/password_strength_helper.dart';
import '../services/encryption_service.dart';
import 'add_password_screen.dart';
import 'edit_password_screen.dart';
import 'premium_screen.dart';
import 'security_audit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();
  List<PasswordModel> _passwords = [];
  List<PasswordModel> _filteredPasswords = [];
  bool _isLoading = true;
  bool _isPremium = false;
  String _selectedFilter = 'Semua';
  
  final List<String> _displayCategories = ['Semua', ...CategoryHelper.categories];

  // Deep Premium Colors
  static const Color primaryBlue = Color(0xFF0F172A); // Slate 900
  static const Color accentBlue = Color(0xFF3B82F6);  // Blue 500
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color bgGrey = Color(0xFFF8FAFC);      // Slate 50

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPasswords();
    _checkPremiumStatus();
    _searchController.addListener(_filterPasswords);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _lockApp();
    }
  }

  void _lockApp() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _filterPasswords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPasswords = _passwords.where((password) {
        final matchesQuery = password.title.toLowerCase().contains(query) ||
            password.username.toLowerCase().contains(query);
        final matchesCategory = _selectedFilter == 'Semua' || password.category == _selectedFilter;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumService.isPremiumUser();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
      });
    }
  }

  Future<void> _loadPasswords() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final passwords = await _dbHelper.getAllPasswords();
      if (mounted) {
        setState(() {
          _passwords = passwords;
          _filteredPasswords = passwords;
          _isLoading = false;
        });
        _filterPasswords();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade400),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade400),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  int _getWeakCount() {
    return _passwords.where((p) {
      final decrypted = EncryptionService.decrypt(p.password);
      if (decrypted == null) return false;
      return PasswordStrengthHelper.checkStrength(decrypted) == PasswordStrength.weak;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: bgGrey,
        resizeToAvoidBottomInset: true,
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDynamicHeader(),
                _buildSearchSection(),
                _buildCategorySection(),
                if (!_isPremium && _passwords.length >= 15) _buildPremiumBanner(),
              ],
            ),
          ),
          _isLoading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : _filteredPasswords.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildModernPasswordCard(_filteredPasswords[index]),
                          childCount: _filteredPasswords.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
        ),
        floatingActionButton: _buildPremiumFab(),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      elevation: 0,
      backgroundColor: bgGrey,
      centerTitle: false,
      title: const Text(
        'PASSME',
        style: TextStyle(
          color: primaryBlue,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shield_moon_outlined, color: primaryBlue),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecurityAuditScreen()),
          ).then((_) => _loadPasswords()),
        ),
        _buildUserMenu(),
      ],
    );
  }

  Widget _buildUserMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: accentBlue.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.person_outline_rounded, color: accentBlue, size: 20),
      ),
      onSelected: (value) {
        if (value == 'premium') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()))
              .then((_) => _checkPremiumStatus());
        } else if (value == 'logout') {
          _handleLogout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'premium',
          child: Row(
            children: [
              Icon(_isPremium ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _isPremium ? Colors.amber : Colors.grey),
              const SizedBox(width: 12),
              Text(_isPremium ? 'Status Premium' : 'Berlangganan'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              const SizedBox(width: 12),
              Text('Keluar Akun'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildStatCard('Semua', _passwords.length.toString(), accentBlue),
          const SizedBox(width: 12),
          _buildStatCard('Lemah', _getWeakCount().toString(), Colors.orangeAccent),
          const SizedBox(width: 12),
          _buildStatCard('Sangat Kuat', _passwords.where((p) {
            final dec = EncryptionService.decrypt(p.password);
            return dec != null && PasswordStrengthHelper.checkStrength(dec) == PasswordStrength.strong;
          }).length.toString(), Colors.teal.shade700),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Cari kata sandi atau email...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
            suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onEditingComplete: () => FocusScope.of(context).unfocus(),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Kategori',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue),
            ),
          ),
          SizedBox(
            height: 45,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _displayCategories.length,
              itemBuilder: (context, index) {
                final cat = _displayCategories[index];
                final isSelected = _selectedFilter == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = cat;
                      _filterPasswords();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue : surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? primaryBlue : Colors.grey.shade200),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPasswordCard(PasswordModel password) {
    final categoryColor = CategoryHelper.getColor(password.category);
    final serviceColor = IconHelper.getIconColor(password.iconType);
    final serviceIcon = IconHelper.getIconData(password.iconType);
    
    // Determine which color and icon to show (prioritize brand-specific if not 'default')
    final displayColor = password.iconType == 'default' ? categoryColor : serviceColor;
    final displayIcon = password.iconType == 'default' ? CategoryHelper.getIcon(password.category) : serviceIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: displayColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(displayIcon, color: displayColor, size: 26),
        ),
        title: Text(
          password.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(password.username, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTinyBadge(password.category, categoryColor),
                const SizedBox(width: 8),
                Text(
                  _formatDate(password.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditPasswordScreen(password: password)),
        ).then((_) => _loadPasswords()),
      ),
    );
  }

  Widget _buildTinyBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_fix_normal_rounded, size: 64, color: accentBlue.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Brankas Masih Kosong',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: primaryBlue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Mulai amankan akun Anda dengan menambahkan kata sandi pertama.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: const NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
          opacity: 0.05,
          fit: BoxFit.cover,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Versi Gratis Terbatas',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${_passwords.length}/15 slot digunakan',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen())),
            style: TextButton.styleFrom(
              backgroundColor: surfaceWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Upgrade', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFab() {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryBlue,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 3),
        boxShadow: [
          BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPasswordScreen()));
            _loadPasswords();
          },
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}
