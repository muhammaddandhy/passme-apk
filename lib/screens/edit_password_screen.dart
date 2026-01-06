import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_model.dart';
import '../services/database_helper.dart';
import '../services/encryption_service.dart';
import '../services/clipboard_service.dart';
import '../utils/icon_helper.dart';
import '../utils/password_strength_helper.dart';
import '../utils/category_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import 'password_generator_screen.dart';

class EditPasswordScreen extends StatefulWidget {
  final PasswordModel password;

  const EditPasswordScreen({
    super.key,
    required this.password,
  });

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showCurrentPassword = false;
  String? _decryptedPassword;
  PasswordStrength _strength = PasswordStrength.weak;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.password.title);
    _usernameController = TextEditingController(text: widget.password.username);
    _passwordController = TextEditingController();
    _urlController = TextEditingController(text: widget.password.url);
    _notesController = TextEditingController(text: widget.password.notes);
    _selectedCategory = widget.password.category;
    
    _decryptedPassword = EncryptionService.decrypt(widget.password.password);
    if (_decryptedPassword != null) {
      _strength = PasswordStrengthHelper.checkStrength(_decryptedPassword!);
    }
    
    _passwordController.addListener(_updateStrength);
  }

  void _updateStrength() {
    if (_passwordController.text.isNotEmpty) {
      setState(() {
        _strength = PasswordStrengthHelper.checkStrength(_passwordController.text);
      });
    } else if (_decryptedPassword != null) {
      setState(() {
        _strength = PasswordStrengthHelper.checkStrength(_decryptedPassword!);
      });
    }
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String encryptedPassword = widget.password.password;
        String? newHistory = widget.password.passwordHistory;

        if (_passwordController.text.isNotEmpty && _passwordController.text != _decryptedPassword) {
          // Password is changing
          encryptedPassword = EncryptionService.encrypt(_passwordController.text);
          
          // Add old password to history
          List<dynamic> historyList = [];
          if (widget.password.passwordHistory != null) {
            try {
              historyList = jsonDecode(widget.password.passwordHistory!);
            } catch (e) {
              historyList = [];
            }
          }
          
          // Add current (soon to be old) password to the start of the list
          historyList.insert(0, {
            'password': widget.password.password,
            'date': DateTime.now().toIso8601String(),
          });
          
          // Keep only last 10 versions
          if (historyList.length > 10) {
            historyList = historyList.sublist(0, 10);
          }
          
          newHistory = jsonEncode(historyList);
        }

        final iconType = IconHelper.getIconType(
          _titleController.text,
          _usernameController.text,
        );

        final updatedPassword = PasswordModel(
          id: widget.password.id,
          title: _titleController.text,
          username: _usernameController.text,
          password: encryptedPassword,
          url: _urlController.text.isEmpty ? null : _urlController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: widget.password.createdAt,
          iconType: iconType,
          category: _selectedCategory,
          passwordHistory: newHistory,
        );

        await _dbHelper.updatePassword(updatedPassword);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password berhasil diupdate'),
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

  void _copyFromHistory(String encryptedOldPass) {
    final decrypted = EncryptionService.decrypt(encryptedOldPass);
    if (decrypted != null) {
      ClipboardService.copyAndAutoClear(decrypted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password lama disalin'),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deletePassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Password?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deletePassword(widget.password.id!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _copyPassword() {
    if (_decryptedPassword != null) {
      ClipboardService.copyAndAutoClear(_decryptedPassword!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password disalin (berlaku 30 detik)'),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Password'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _deletePassword,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CategoryHelper.getColor(_selectedCategory).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CategoryHelper.getIcon(_selectedCategory),
                          color: CategoryHelper.getColor(_selectedCategory),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.password.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Kategori: $_selectedCategory',
                              style: TextStyle(
                                fontSize: 13,
                                color: CategoryHelper.getColor(_selectedCategory),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // View Original Password Section
                const Text(
                  'Password Saat Ini',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _showCurrentPassword ? (_decryptedPassword ?? 'Error') : '••••••••••••',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: _showCurrentPassword ? 'monospace' : null,
                            letterSpacing: _showCurrentPassword ? 0 : 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showCurrentPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF0F172A), size: 20),
                        onPressed: _copyPassword,
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
                  label: 'Judul / Nama Layanan',
                  hint: 'Contoh: Google, Facebook',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                CustomInput(
                  controller: _usernameController,
                  label: 'Username / Email',
                  hint: 'Masukkan username',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category Selection
                const Text(
                  'Kategori',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: CategoryHelper.categories.length,
                    itemBuilder: (context, index) {
                      final cat = CategoryHelper.categories[index];
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? CategoryHelper.getColor(cat).withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? CategoryHelper.getColor(cat) : Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CategoryHelper.getIcon(cat),
                                color: isSelected ? CategoryHelper.getColor(cat) : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? CategoryHelper.getColor(cat) : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Password Input with Generator
                CustomInput(
                  controller: _passwordController,
                  label: 'Password Baru (Kosongkan jika tidak ganti)',
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.casino_outlined, color: Color(0xFF0F172A)),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PasswordGeneratorScreen(),
                            ),
                          );
                          if (result != null && result is String) {
                            setState(() {
                              _passwordController.text = result;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ],
                  ),
                ),
                
                // Strength Indicator
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kekuatan Password: ${PasswordStrengthHelper.getLabel(_strength)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: PasswordStrengthHelper.getColor(_strength),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: PasswordStrengthHelper.getPercent(_strength),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        PasswordStrengthHelper.getColor(_strength),
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                CustomInput(
                  controller: _urlController,
                  label: 'Website URL (Opsional)',
                  hint: 'https://example.com',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 20),

                CustomInput(
                  controller: _notesController,
                  label: 'Catatan (Opsional)',
                  hint: 'Tambahkan catatan...',
                  maxLines: 3,
                ),
                const SizedBox(height: 40),

                CustomButton(
                  text: 'Simpan Perubahan',
                  onPressed: _updatePassword,
                  isLoading: _isLoading,
                ),
                
                // History Section
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 24),
                const Text(
                  'Riwayat Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Daftar kata sandi lama yang pernah digunakan untuk akun ini.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (widget.password.passwordHistory == null || widget.password.passwordHistory!.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, color: Colors.grey.shade300, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada riwayat perubahan',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                else
                  ... (() {
                    try {
                      final List<dynamic> history = jsonDecode(widget.password.passwordHistory!);
                      if (history.isEmpty) return [const Center(child: Text('Riwayat kosong'))];
                      
                      return history.map((item) {
                        final dateStr = item['date'] as String;
                        final date = DateTime.parse(dateStr);
                        final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.history_rounded, color: Colors.grey),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '••••••••••••',
                                      style: TextStyle(
                                        fontSize: 16,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Diganti pada $formattedDate',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, color: Color(0xFF0057D9), size: 20),
                                onPressed: () => _copyFromHistory(item['password']),
                                tooltip: 'Salin password lama',
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    } catch (e) {
                      return [Text('Error loading history: $e')];
                    }
                  })(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
