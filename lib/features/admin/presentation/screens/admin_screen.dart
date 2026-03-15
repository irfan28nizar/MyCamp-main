import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mycamp_app/features/auth/data/repositories/supabase_auth_repository.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: 'Welcome@321');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final SupabaseAuthRepository _authRepository = SupabaseAuthRepository();

  String _selectedRole = 'student';
  String _selectedYear = '1st Year';
  bool _isLoading = false;

  bool get _showYearField => _selectedRole == 'student' || _selectedRole == 'temp';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final role = _selectedRole;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final branch = _branchController.text.trim();
    final year = _showYearField ? _selectedYear : null;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = await _authRepository.createUser(
      email,
      password,
      role: role,
      name: name.isNotEmpty ? name : null,
      phone: phone.isNotEmpty ? phone : null,
      year: year,
      branch: branch.isNotEmpty ? branch : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );
      _emailController.clear();
      _passwordController.text = 'Welcome@321';
      _nameController.clear();
      _phoneController.clear();
      _branchController.clear();
      setState(() {
        _selectedRole = 'student';
        _selectedYear = '1st Year';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Create User'),
      ),
      body: SafeArea(
        
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20,40,20,20),
            child:Align(
              alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info text
                      Text(
                        'User will be required to change this password on first login.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Email
                      const Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter email address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Initial Password
                      const Text(
                        'Initial Password',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: 'Min 6 characters',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Copy password',
                            onPressed: () {
                              if (_passwordController.text.isNotEmpty) {
                                Clipboard.setData(ClipboardData(text: _passwordController.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password copied'), duration: Duration(seconds: 1)),
                                );
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Full Name
                      const Text(
                        'Full Name',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Enter full name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Phone Number
                      const Text(
                        'Phone Number',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Enter phone number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Branch
                      const Text(
                        'Branch',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _branchController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'e.g. Computer Science',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      // Year (only for student/temp)
                      if (_showYearField) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Year',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedYear,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: '1st Year', child: Text('1st Year')),
                            DropdownMenuItem(value: '2nd Year', child: Text('2nd Year')),
                            DropdownMenuItem(value: '3rd Year', child: Text('3rd Year')),
                            DropdownMenuItem(value: '4th Year', child: Text('4th Year')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _selectedYear = value);
                          },
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Role dropdown
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1DA0AA),
                              Color(0xFF39C3CF),
                            ],
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            iconEnabledColor: Colors.white,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            items: const [
                              DropdownMenuItem(
                                value: 'student',
                                child: Text('STUDENT'),
                              ),
                              DropdownMenuItem(
                                value: 'teacher',
                                child: Text('TEACHER'),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('ADMIN'),
                              ),
                              DropdownMenuItem(
                                value: 'temp',
                                child: Text('TEMP USER'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedRole = value);
                              }
                            },
                            selectedItemBuilder: (context) {
                              return ['student', 'teacher', 'admin', 'temp']
                                  .map(
                                    (role) => Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            role.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList();
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Create button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DA0AA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'CREATE USER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
