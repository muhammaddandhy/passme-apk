import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../services/database_helper.dart';
import '../services/export_service.dart';
import '../widgets/custom_button.dart';
import '../models/password_model.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = false;
  bool _isPremium = false;
  Map<String, dynamic>? _productInfo;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _loadProductInfo();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumService.isPremiumUser();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
      });
    }
  }

  Future<void> _loadProductInfo() async {
    final productInfo = await PremiumService.getPremiumProductInfo();
    if (mounted) {
      setState(() {
        _productInfo = productInfo;
      });
    }
  }

  Future<void> _upgradeToPremium() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await PremiumService.upgradeToPremium();
      if (mounted) {
        if (success) {
          // Wait a bit for purchase to process
          await Future.delayed(const Duration(milliseconds: 500));
          await _checkPremiumStatus();
          
          setState(() {
            _isLoading = false;
          });
          
          if (_isPremium) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Selamat! Anda sekarang Premium User'),
                backgroundColor: Colors.green.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Berhenti Langganan?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin berhenti langganan Premium? Akses premium akan tetap aktif hingga akhir periode pembayaran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: const Text('Berhenti'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await PremiumService.cancelSubscription();
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkPremiumStatus();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Langganan dibatalkan. Untuk membatalkan sepenuhnya, silakan buka pengaturan langganan di Play Store.',
            ),
            backgroundColor: Colors.orange.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
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

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await PremiumService.restorePurchases();
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkPremiumStatus();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (_isPremium) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pembelian berhasil dipulihkan'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tidak ada pembelian yang ditemukan'),
              backgroundColor: Colors.orange.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
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

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      final passwords = await DatabaseHelper.instance.getAllPasswords();
      if (passwords.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Brankas Anda masih kosong')),
          );
        }
        return;
      }
      await ExportService.exportToCSV(passwords);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('PASSME Premium'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Header Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Slate 900
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, size: 48, color: Colors.amber),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'PASSME PREMIUM',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isPremium 
                          ? 'Akses Premium Aktif' 
                          : 'Keamanan Tingkat Tinggi untuk Hidup Digital Anda',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              const Text(
                'Keunggulan Premium',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 24),
              
              _buildFeatureItem(
                icon: Icons.all_inclusive_rounded,
                title: 'Data Tanpa Batas',
                description: 'Simpan ribuan kata sandi tanpa batasan slot 15 password.',
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.file_download_outlined,
                title: 'Ekspor Data Brankas',
                description: 'Cadangkan data Anda ke file CSV atau PDF dengan mudah.',
                color: Colors.purple,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.enhanced_encryption_rounded,
                title: 'Enkripsi Military-Grade',
                description: 'Perlindungan AES-256 yang lebih tangguh untuk data sensitif.',
                color: Colors.teal,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.history_edu_rounded,
                title: 'Riwayat Lebih Panjang',
                description: 'Simpan hingga 50 riwayat password lama (Free hanya 10).',
                color: Colors.orange,
              ),

              const SizedBox(height: 48),

              if (!_isPremium) ...[
                // Pricing Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _productInfo?['price'] ?? 'Rp 19.000',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const Text('/ bulan', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _upgradeToPremium,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Jadi Premium Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : _restorePurchases,
                        child: const Text('Sudah berlangganan? Pulihkan pembelian', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Active Premium Status
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.teal, size: 48),
                      const SizedBox(height: 16),
                      const Text('Anda adalah Pengguna Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                      const SizedBox(height: 8),
                      const Text('Terima kasih telah mendukung pengembangan PASSME.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _exportData,
                          icon: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.file_download_outlined),
                          label: const Text('Ekspor Data Brankas (CSV)', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading ? null : _cancelSubscription,
                        child: const Text('Berhenti Berlangganan', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

