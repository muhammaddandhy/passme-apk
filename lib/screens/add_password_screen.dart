import 'package:flutter/material.dart';
import '../models/password_model.dart';
import '../services/database_helper.dart';
import '../services/encryption_service.dart';
import '../services/premium_service.dart';
import '../utils/category_helper.dart';
import '../utils/icon_helper.dart';
import '../utils/password_strength_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import 'premium_screen.dart';
import 'password_generator_screen.dart';

class AddPasswordScreen extends StatefulWidget {
  const AddPasswordScreen({super.key});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  PasswordStrength _strength = PasswordStrength.weak;
  String _selectedCategory = 'Lainnya';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateStrength);
  }

  void _updateStrength() {
    setState(() {
      _strength = PasswordStrengthHelper.checkStrength(_passwordController.text);
    });
  }

  Future<void> _savePassword() async {
    if (_formKey.currentState!.validate()) {
      // Cek apakah user premium
      final isPremium = await PremiumService.isPremiumUser();

      // Jika bukan premium, cek jumlah password
      if (!isPremium) {
        final allPasswords = await _dbHelper.getAllPasswords();
        const maxFreePasswords = 15; // User wanted 15

        if (allPasswords.length >= maxFreePasswords) {
          // Tampilkan dialog upgrade
          _showUpgradeDialog();
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final encryptedPassword = EncryptionService.encrypt(
          _passwordController.text,
        );

        // Auto-detect icon type from title
        final iconType = IconHelper.getIconType(
          _titleController.text,
          _usernameController.text,
        );

        final password = PasswordModel(
          title: _titleController.text,
          username: _usernameController.text,
          password: encryptedPassword,
          url: _urlController.text.isEmpty ? null : _urlController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: DateTime.now().toIso8601String(),
          iconType: iconType,
          category: _selectedCategory,
        );

        await _dbHelper.insertPassword(password);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password berhasil ditambahkan'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF0057D9).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 32,
                  color: Color(0xFF0057D9),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upgrade ke Premium',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda telah mencapai batas maksimal 20 password untuk akun Free.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upgrade ke Premium untuk menyimpan password tanpa batas!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0057D9),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PremiumScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0057D9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Upgrade Sekarang'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

    // List layanan populer
  final List<Map<String, dynamic>> _popularServices = [
    {'name': 'Google / Gmail', 'icon': Icons.mail_rounded},
    {'name': 'Instagram', 'icon': Icons.camera_alt_rounded},
    {'name': 'Twitter', 'icon': Icons.flutter_dash_rounded},
    {'name': 'TikTok', 'icon': Icons.music_note_rounded},
    {'name': 'Facebook', 'icon': Icons.facebook_rounded},
    {'name': 'Netflix', 'icon': Icons.movie_rounded},
    {'name': 'Spotify', 'icon': Icons.music_video_rounded},
    {'name': 'Mobile Banking', 'icon': Icons.account_balance_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Simpan Data Baru'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Minimalist Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.add_moderator_rounded, color: Color(0xFF3B82F6), size: 32),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Brankas Baru',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Data mengenkripsi secara otomatis',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Pilih Layanan Populer
                const Text(
                  'Layanan Populer',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: _popularServices.length,
                  itemBuilder: (context, index) {
                    final service = _popularServices[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _titleController.text = service['name'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(service['icon'] as IconData, size: 16, color: const Color(0xFF3B82F6)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                service['name'] as String,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                CustomInput(
                  controller: _titleController,
                  label: 'Nama Layanan',
                  hint: 'Contoh: Instagram, Bank BCA, dll',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Judul wajib diisi';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                CustomInput(
                  controller: _usernameController,
                  label: 'Username atau Email',
                  hint: 'Masukkan identitas login',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Username wajib diisi';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                CustomInput(
                  controller: _passwordController,
                  label: 'Kata Sandi',
                  hint: 'Masukkan kata sandi',
                  obscureText: _obscurePassword,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF3B82F6)),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PasswordGeneratorScreen()),
                          );
                          if (result != null) _passwordController.text = result;
                        },
                      ),
                      IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Sandi tidak boleh kosong';
                    return null;
                  },
                ),
                
                const SizedBox(height: 12),
                _buildStrengthLine(),
                
                const SizedBox(height: 32),
                
                const Text(
                  'Kategori',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: CategoryHelper.categories.length,
                    itemBuilder: (context, index) {
                      final cat = CategoryHelper.categories[index];
                      final isSelected = _selectedCategory == cat;
                      final color = CategoryHelper.getColor(cat);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade200),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CategoryHelper.getIcon(cat),
                                color: isSelected ? Colors.white : color,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black54,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                CustomInput(
                  controller: _notesController,
                  label: 'Catatan (Opsional)',
                  hint: 'Informasi tambahan...',
                  maxLines: 3,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan Ke Brankas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthLine() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: PasswordStrengthHelper.getPercent(_strength),
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(PasswordStrengthHelper.getColor(_strength)),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Keamanan: ${PasswordStrengthHelper.getLabel(_strength)}',
              style: TextStyle(fontSize: 11, color: PasswordStrengthHelper.getColor(_strength), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
