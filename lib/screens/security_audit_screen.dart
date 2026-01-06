import 'package:flutter/material.dart';
import '../models/password_model.dart';
import '../services/database_helper.dart';
import '../utils/password_strength_helper.dart';
import '../services/encryption_service.dart';
import '../utils/icon_helper.dart';
import 'edit_password_screen.dart';

class SecurityAuditScreen extends StatefulWidget {
  const SecurityAuditScreen({super.key});

  @override
  State<SecurityAuditScreen> createState() => _SecurityAuditScreenState();
}

class _SecurityAuditScreenState extends State<SecurityAuditScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<PasswordModel> _weakPasswords = [];
  List<PasswordModel> _reusedPasswords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performAudit();
  }

  Future<void> _performAudit() async {
    setState(() => _isLoading = true);
    
    final allPasswords = await _dbHelper.getAllPasswords();
    final List<PasswordModel> weak = [];
    final Map<String, List<PasswordModel>> groups = {};

    for (var pwd in allPasswords) {
      // Check strength
      final decrypted = EncryptionService.decrypt(pwd.password);
      if (decrypted != null) {
        final strength = PasswordStrengthHelper.checkStrength(decrypted);
        if (strength == PasswordStrength.weak || strength == PasswordStrength.medium) {
          weak.add(pwd);
        }
        
        // Track for reuse check
        if (!groups.containsKey(pwd.password)) {
          groups[pwd.password] = [];
        }
        groups[pwd.password]!.add(pwd);
      }
    }

    final List<PasswordModel> reused = [];
    groups.forEach((key, list) {
      if (list.length > 1) {
        reused.addAll(list);
      }
    });

    if (mounted) {
      setState(() {
        _weakPasswords = weak;
        _reusedPasswords = reused;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Keamanan'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 24),
                
                if (_reusedPasswords.isNotEmpty) ...[
                  _buildSectionTitle('Password Digunakan Ulang', Icons.repeat_rounded, Colors.orange),
                  const SizedBox(height: 12),
                  ..._reusedPasswords.map((p) => _buildAuditItem(p, 'Password ini digunakan di akun lain')),
                  const SizedBox(height: 24),
                ],
                
                if (_weakPasswords.isNotEmpty) ...[
                  _buildSectionTitle('Password Lemah', Icons.warning_amber_rounded, Colors.red),
                  const SizedBox(height: 12),
                  ..._weakPasswords.map((p) => _buildAuditItem(p, 'Tingkatkan keamanan password Anda')),
                ],
                
                if (_weakPasswords.isEmpty && _reusedPasswords.isEmpty)
                  _buildPerfectScore(),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryCard() {
    final totalIssues = _weakPasswords.length + _reusedPasswords.length;
    final isSecure = totalIssues == 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSecure 
            ? [Colors.green.shade400, Colors.green.shade600]
            : [Colors.orange.shade400, Colors.red.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            isSecure ? Icons.verified_user_rounded : Icons.shield_outlined,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isSecure ? 'Semua Aman!' : '$totalIssues Masalah Keamanan',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSecure 
              ? 'Password Anda sudah kuat dan unik.' 
              : 'Beberapa password Anda perlu diperbarui.',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAuditItem(PasswordModel password, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditPasswordScreen(password: password)),
          );
          _performAudit();
        },
        leading: CircleAvatar(
          backgroundColor: IconHelper.getIconColor(password.iconType).withOpacity(0.1),
          child: Icon(IconHelper.getIconData(password.iconType), color: IconHelper.getIconColor(password.iconType)),
        ),
        title: Text(password.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Widget _buildPerfectScore() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.check_circle_outline_rounded, size: 100, color: Colors.green.shade200),
          const SizedBox(height: 20),
          const Text(
            'Luar Biasa!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text('Semua password Anda aman.'),
        ],
      ),
    );
  }
}
