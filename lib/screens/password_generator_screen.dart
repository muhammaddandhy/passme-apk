import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/password_generator.dart';
import '../widgets/custom_button.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  int _length = 12;
  bool _useLowercase = true;
  bool _useUppercase = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    setState(() {
      _generatedPassword = PasswordGenerator.generate(
        length: _length,
        useLowercase: _useLowercase,
        useUppercase: _useUppercase,
        useNumbers: _useNumbers,
        useSymbols: _useSymbols,
      );
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password disalin!'),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Generator Sandi'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display Area
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _generatedPassword,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionCircle(
                          icon: Icons.copy_rounded,
                          onTap: _copyToClipboard,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(width: 24),
                        _buildActionCircle(
                          icon: Icons.refresh_rounded,
                          onTap: _generatePassword,
                          color: const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              const Text(
                'Pengaturan Keamanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 24),
              
              // Settings Area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20),
                  ],
                ),
                child: Column(
                  children: [
                    // Length Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Panjang Karakter', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          _length.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), fontSize: 18),
                        ),
                      ],
                    ),
                    Slider(
                      value: _length.toDouble(),
                      min: 6,
                      max: 32,
                      divisions: 26,
                      activeColor: const Color(0xFF3B82F6),
                      inactiveColor: Colors.blue.withOpacity(0.1),
                      onChanged: (value) {
                        setState(() => _length = value.toInt());
                        _generatePassword();
                      },
                    ),
                    const Divider(height: 40),
                    _buildFeatureToggle('Huruf Kecil (a-z)', _useLowercase, (val) {
                      setState(() => _useLowercase = val);
                      if (!_useLowercase && !_useUppercase && !_useNumbers && !_useSymbols) setState(() => _useLowercase = true);
                      _generatePassword();
                    }),
                    _buildFeatureToggle('Huruf Besar (A-Z)', _useUppercase, (val) {
                      setState(() => _useUppercase = val);
                      if (!_useLowercase && !_useUppercase && !_useNumbers && !_useSymbols) setState(() => _useUppercase = true);
                      _generatePassword();
                    }),
                    _buildFeatureToggle('Angka (0-9)', _useNumbers, (val) {
                      setState(() => _useNumbers = val);
                      if (!_useLowercase && !_useUppercase && !_useNumbers && !_useSymbols) setState(() => _useNumbers = true);
                      _generatePassword();
                    }),
                    _buildFeatureToggle('Simbol (!@#)', _useSymbols, (val) {
                      setState(() => _useSymbols = val);
                      if (!_useLowercase && !_useUppercase && !_useNumbers && !_useSymbols) setState(() => _useSymbols = true);
                      _generatePassword();
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _generatedPassword),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Gunakan Password Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle({required IconData icon, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFeatureToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            activeColor: const Color(0xFF3B82F6),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Switch(
            value: value,
            activeColor: const Color(0xFF0057D9),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
