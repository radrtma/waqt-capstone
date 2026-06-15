import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = AuthService();
  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Username dan password tidak boleh kosong");
      return;
    }

    if (!_isLoginMode) {
      final confirmPassword = _confirmPasswordController.text.trim();
      if (confirmPassword.isEmpty) {
        setState(() => _errorMessage = "Masukkan kembali password Anda untuk konfirmasi");
        return;
      }
      if (password != confirmPassword) {
        setState(() => _errorMessage = "Konfirmasi password tidak cocok");
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success;
    if (_isLoginMode) {
      success = await _auth.login(username, password);
    } else {
      success = await _auth.register(username, password);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = _isLoginMode 
              ? "Login gagal. Periksa kembali username/password." 
              : "Registrasi gagal. Username mungkin sudah digunakan.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1F6F5B);
    const bgSand = Color(0xFFF5E9DA);

    return Scaffold(
      backgroundColor: bgSand,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Title WAQT
              Text(
                'WAQT',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isLoginMode 
                    ? 'Masuk untuk sinkronisasi ibadah harian' 
                    : 'Daftar akun ibadah baru Anda',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14, 
                  color: const Color(0xFF5A5A5A),
                  fontWeight: FontWeight.w500
                ),
              ),
              const SizedBox(height: 36),
              
              // Error Banner
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade900, 
                      fontSize: 13, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
                
              // Input Fields Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      style: GoogleFonts.inter(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                        prefixIcon: const Icon(Icons.person_outline, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: GoogleFonts.inter(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                        prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    if (!_isLoginMode) ...[
                      const SizedBox(height: 18),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: GoogleFonts.inter(fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Masukan Kembali Password Anda',
                          labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                          prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        )
                      : Text(
                          _isLoginMode ? 'Masuk' : 'Daftar Akun', 
                          style: GoogleFonts.inter(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Toggle Mode Link
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginMode = !_isLoginMode;
                    _errorMessage = null;
                  });
                },
                child: Text(
                  _isLoginMode 
                      ? 'Belum punya akun? Daftar Sekarang' 
                      : 'Sudah punya akun? Masuk di sini',
                  style: GoogleFonts.inter(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
