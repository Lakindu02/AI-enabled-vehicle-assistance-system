import 'package:flutter/material.dart';
import 'package:guardian_link/models/user_model.dart';
import '../../models/guardian_model.dart';
import '../../services/database_service.dart';

class GuardianRegistrationScreen extends StatefulWidget {
  final UserModel userModel;

  const GuardianRegistrationScreen({super.key, required this.userModel});

  @override
  State<GuardianRegistrationScreen> createState() =>
      _GuardianRegistrationScreenState();
}

class _GuardianRegistrationScreenState
    extends State<GuardianRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;

  bool _isLoading = true;
  GuardianModel? _existingGuardian;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _ageController = TextEditingController();
    _emailController = TextEditingController();
    _loadGuardian();
  }

  Future<void> _loadGuardian() async {
    try {
      final guardians = await _databaseService.getUserGuardians(
        widget.userModel.id,
      );
      if (guardians.isNotEmpty) {
        _existingGuardian = guardians[0]; // Get first guardian
        _nameController.text = _existingGuardian!.name;
        _addressController.text = _existingGuardian!.address;
        _phoneNumberController.text = _existingGuardian!.phoneNumber;
        _ageController.text = _existingGuardian!.age.toString();
        _emailController.text = _existingGuardian!.email ?? '';
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading guardian: $e')));
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveGuardian() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      int age = int.parse(_ageController.text.trim());
      String? email = _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim();

      if (_existingGuardian != null) {
        // Update existing guardian
        await _databaseService.updateGuardian(
          guardianId: _existingGuardian!.id,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          age: age,
          email: email,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guardian updated successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new guardian
        await _databaseService.createGuardian(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          age: age,
          userId: widget.userModel.id,
          email: email,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guardian registered successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = _existingGuardian != null
        ? 'Update Guardian'
        : 'Register Guardian';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Show info banner if updating
                    if (_existingGuardian != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 50),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You can update your existing guardian information',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Guardian Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter guardian name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Phone Number Field
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Age Field
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter age';
                        }
                        try {
                          int.parse(value);
                        } catch (e) {
                          return 'Please enter a valid age';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Email Field (Optional)
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    // Save/Register Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveGuardian,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _existingGuardian != null
                                  ? 'Update Guardian'
                                  : 'Register Guardian',
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
