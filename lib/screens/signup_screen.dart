import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

import 'home_screen.dart';
//import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // متغيرات لتتبع أخطاء التحقق
  String? _nameError;
  String? _dobError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // متغيرات لتتبع شروط كلمة المرور
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  // دالة للتحقق من الحقول غير الفارغة
  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return "⚠️ Please enter your $fieldName";
    }
    return null;
  }

  // تحقق من الاسم
  void _validateName() {
    setState(() {
      _nameError = _validateNotEmpty(_nameController.text, "full name");
    });
  }

  // تحقق من تاريخ الميلاد
  void _validateDob() {
    setState(() {
      _dobError = _validateNotEmpty(_dobController.text, "date of birth");
    });
  }

  // تحقق من البريد الإلكتروني
  void _validateEmail() {
    setState(() {
      final value = _emailController.text;
      _emailError = _validateNotEmpty(value, "email");

      if (_emailError == null &&
          !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
        _emailError = "⚠️ Enter a valid email address";
      } else if (_emailError == null &&
          !EmailValidator.isLikelyRealEmail(value)) {
        _emailError =
            "⚠️ Please use a real email address for password recovery";
      } else {
        _emailError = null;
      }
    });
  }

  // تحقق من كلمة المرور مع الشروط
  void _validatePassword() {
    setState(() {
      final value = _passwordController.text;
      _passwordError = _validateNotEmpty(value, "password");

      // تحديث شروط كلمة المرور
      _hasMinLength = value.length >= 8;
      _hasUpperCase = value.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      // إظهار الشرط الناقص فقط
      if (_passwordError != null) return;

      if (!_hasMinLength) {
        _passwordError = "⚠️ Password must be at least 8 characters";
      } else if (!_hasUpperCase) {
        _passwordError = "⚠️ Include at least one uppercase letter";
      } else if (!_hasLowerCase) {
        _passwordError = "⚠️ Include at least one lowercase letter";
      } else if (!_hasNumber) {
        _passwordError = "⚠️ Include at least one number";
      } else if (!_hasSpecialChar) {
        _passwordError = "⚠️ Include at least one special character";
      } else {
        _passwordError = null; // كلمة المرور مقبولة
      }
    });

    // عند تغيير كلمة المرور، تحقق أيضًا من تأكيد كلمة المرور
    if (_confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }
  }

  // تحقق من تأكيد كلمة المرور
  void _validateConfirmPassword() {
    setState(() {
      final value = _confirmPasswordController.text;
      _confirmPasswordError = _validateNotEmpty(value, "password confirmation");

      if (_confirmPasswordError == null && value != _passwordController.text) {
        _confirmPasswordError = "⚠️ Passwords do not match";
      }
    });
  }

  // تحقق من كل الحقول مرة واحدة
  bool _validateAllFields() {
    _validateName();
    _validateDob();
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();

    return _nameError == null &&
        _dobError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  Future<void> _signUp() async {
    // إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();

    // التحقق من جميع الحقول
    if (!_validateAllFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please fix the errors in the form"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // إنشاء الحساب
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // إرسال التحقق من البريد الإلكتروني
      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "✅ Account created successfully! Please check your email for verification.",
            ),
            backgroundColor: Colors.green,
          ),
        );

        // الانتقال إلى شاشة الـ Home بعد التسجيل الناجح
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Sign up failed";

      if (e.code == 'weak-password') {
        setState(() {
          _passwordError = "⚠️ The password is too weak";
        });
        errorMessage = "The password provided is too weak";
      } else if (e.code == 'email-already-in-use') {
        setState(() {
          _emailError = "⚠️ This email is already registered";
        });
        errorMessage = "An account already exists for that email";
      } else if (e.code == 'invalid-email') {
        setState(() {
          _emailError = "⚠️ Invalid email address";
        });
        errorMessage = "Invalid email address";
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = "Email/password accounts are not enabled";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ $errorMessage"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ An unexpected error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Location permission is required to get your address",
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Location permissions are permanently denied. Please enable them in app settings",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _loading = true);

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _addressController.text =
              "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}"
                  .replaceAll(RegExp(r', ,'), ',')
                  .replaceAll(RegExp(r',+'), ',')
                  .trim();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to get location: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        _validateDob(); // التحقق بعد اختيار التاريخ
      });
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Column(
          children: [
            // الجزء العلوي (الصورة)
            Container(
              height: size.height * 0.25,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/tabib_background.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // الجزء الأبيض
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: const Icon(Icons.person),
                          border: const OutlineInputBorder(),
                          errorText: _nameError,
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (value) => _validateName(),
                        onEditingComplete: _validateName,
                      ),
                      const SizedBox(height: 15),

                      // Date of Birth
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Date of Birth",
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                          errorText: _dobError,
                        ),
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 15),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                          errorText: _emailError,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) => _validateEmail(),
                        onEditingComplete: _validateEmail,
                      ),
                      const SizedBox(height: 15),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                          errorText: _passwordError,
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (value) => _validatePassword(),
                        onEditingComplete: _validatePassword,
                      ),

                      // Password requirements checklist
                      if (_passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildPasswordRequirements(),
                        const SizedBox(height: 5),
                      ],
                      const SizedBox(height: 15),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                          errorText: _confirmPasswordError,
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: (value) => _validateConfirmPassword(),
                        onEditingComplete: () {
                          _validateConfirmPassword();
                          _signUp();
                        },
                      ),
                      const SizedBox(height: 15),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Address (Optional)",
                          prefixIcon: const Icon(Icons.home),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.location_on),
                            onPressed: _getCurrentLocation,
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // Sign Up button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _loading ? null : _signUp,
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Back to Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          GestureDetector(
                            onTap: _navigateToLogin,
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء قائمة متطلبات كلمة المرور
  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Password must contain:",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          _buildRequirementItem("At least 8 characters", _hasMinLength),
          _buildRequirementItem("One uppercase letter (A-Z)", _hasUpperCase),
          _buildRequirementItem("One lowercase letter (a-z)", _hasLowerCase),
          _buildRequirementItem("One number (0-9)", _hasNumber),
          _buildRequirementItem(
            "One special character (!@#...)",
            _hasSpecialChar,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isMet ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.green : Colors.grey,
            decoration: isMet ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

// كلاس التحقق من صحة الإيميل
class EmailValidator {
  // تحقق من الإيميلات الوهمية
  static bool isLikelyRealEmail(String email) {
    final fakeDomains = [
      'example.com',
      'test.com',
      'fake.com',
      'temp.com',
      'mailinator.com',
      'guerrillamail.com',
      '10minutemail.com',
      'tempmail.com',
      'trashmail.com',
      'yopmail.com',
    ];

    final domain = email.split('@').last.toLowerCase();
    return !fakeDomains.contains(domain);
  }
}
