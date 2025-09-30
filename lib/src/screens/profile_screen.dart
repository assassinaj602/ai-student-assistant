import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

/// Profile screen for user account management
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _schoolController = TextEditingController();
  final _gradeController = TextEditingController();
  final _majorController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  DateTime? _selectedDate;
  String _selectedEducationLevel = 'High School';
  final List<String> _educationLevels = [
    'High School',
    'Undergraduate',
    'Graduate',
    'Postgraduate',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
    _majorController.dispose();
    _studentIdController.dispose();
    _emergencyContactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Load current user data
  void _loadUserData() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';

      // Load additional profile data from Firestore
      try {
        final firebase = ref.read(firebaseServiceProvider);
        final profileData = await firebase.getUserProfile();

        if (profileData != null && mounted) {
          setState(() {
            _dobController.text =
                profileData['dateOfBirth'] != null
                    ? _formatDateFromTimestamp(profileData['dateOfBirth'])
                    : '';
            _selectedDate =
                profileData['dateOfBirth'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                      profileData['dateOfBirth'],
                    )
                    : null;
            _phoneController.text = profileData['phoneNumber'] ?? '';
            _bioController.text = profileData['bio'] ?? '';
            _schoolController.text = profileData['school'] ?? '';
            _gradeController.text = profileData['grade'] ?? '';
            _majorController.text = profileData['major'] ?? '';
            _studentIdController.text = profileData['studentId'] ?? '';
            _emergencyContactController.text =
                profileData['emergencyContact'] ?? '';
            _addressController.text = profileData['address'] ?? '';
            _selectedEducationLevel =
                profileData['educationLevel'] ?? 'High School';
          });
        }
      } catch (e) {
        debugPrint('Error loading profile data: $e');
      }
    }
  }

  String _formatDateFromTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Save profile changes
  Future<void> _saveProfile() async {
    debugPrint('Save profile called - isEditing: $_isEditing');
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update Firebase Auth display name
        await user.updateDisplayName(_displayNameController.text.trim());

        // Update Firestore user profile document with additional fields
        final firebase = ref.read(firebaseServiceProvider);
        await firebase.updateUserProfile({
          'displayName': _displayNameController.text.trim(),
          'dateOfBirth': _selectedDate?.millisecondsSinceEpoch,
          'phoneNumber': _phoneController.text.trim(),
          'bio': _bioController.text.trim(),
          'school': _schoolController.text.trim(),
          'grade': _gradeController.text.trim(),
          'major': _majorController.text.trim(),
          'studentId': _studentIdController.text.trim(),
          'emergencyContact': _emergencyContactController.text.trim(),
          'address': _addressController.text.trim(),
          'educationLevel': _selectedEducationLevel,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        if (mounted) {
          setState(() => _isEditing = false);

          // Force refresh of Firebase Auth state to update dashboard
          await firebase_auth.FirebaseAuth.instance.currentUser?.reload();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Select date of birth
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dobController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  /// Change profile photo by URL
  Future<void> _changeProfilePhoto() async {
    final TextEditingController urlController = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Profile Photo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter a photo URL (from web):'),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Photo URL',
                    hintText: 'https://example.com/photo.jpg',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(context).pop(urlController.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (url != null && url.isNotEmpty) {
      try {
        final user = firebase_auth.FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePhotoURL(url);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating photo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Handle account deletion
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete Account'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authProvider.notifier).deleteAccount();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  /// Reset form to empty values
  void _resetForm() {
    setState(() {
      _dobController.clear();
      _phoneController.clear();
      _bioController.clear();
      _schoolController.clear();
      _gradeController.clear();
      _majorController.clear();
      _studentIdController.clear();
      _emergencyContactController.clear();
      _addressController.clear();
      _selectedDate = null;
      _selectedEducationLevel = 'High School';
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Form reset to empty values')));
  }

  @override
  Widget build(BuildContext context) {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
                debugPrint('Edit mode enabled: $_isEditing');
              },
            )
          else ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
                _loadUserData(); // Reset form data
                debugPrint('Edit mode disabled: $_isEditing');
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey.shade600,
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue.shade600,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Save'),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            key: ValueKey(_isEditing), // Force rebuild when edit state changes
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Edit Mode Indicator
              if (_isEditing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Edit Mode - Tap fields to modify your information',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isEditing) const SizedBox(height: 16),

              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                      child:
                          user?.photoURL == null
                              ? Text(
                                user?.displayName?.isNotEmpty == true
                                    ? user!.displayName![0].toUpperCase()
                                    : user?.email?[0].toUpperCase() ?? 'U',
                                style: const TextStyle(fontSize: 32),
                              )
                              : null,
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextButton.icon(
                        onPressed: _changeProfilePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Change Photo'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Account Information
              Text(
                'Account Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Email (Read-only)
              TextFormField(
                initialValue: user?.email ?? '',
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Display Name
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                  suffixIcon:
                      _isEditing ? const Icon(Icons.edit, size: 16) : null,
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  suffixIcon:
                      _isEditing ? const Icon(Icons.edit, size: 16) : null,
                ),
                enabled: _isEditing,
                readOnly: true,
                onTap: _isEditing ? _selectDate : null,
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., +1 234 567 8900',
                  suffixIcon:
                      _isEditing ? const Icon(Icons.edit, size: 16) : null,
                ),
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isNotEmpty == true) {
                    final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]+$');
                    if (!phoneRegex.hasMatch(value!)) {
                      return 'Please enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: const Icon(Icons.info),
                  border: const OutlineInputBorder(),
                  hintText: 'Tell us about yourself...',
                  suffixIcon:
                      _isEditing ? const Icon(Icons.edit, size: 16) : null,
                ),
                enabled: _isEditing,
                maxLines: 3,
                maxLength: 150,
              ),

              const SizedBox(height: 32),

              // Student Information
              Text(
                'Student Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Education Level
              DropdownButtonFormField<String>(
                value: _selectedEducationLevel,
                decoration: InputDecoration(
                  labelText: 'Education Level',
                  prefixIcon: const Icon(Icons.school),
                  border: const OutlineInputBorder(),
                  enabled: _isEditing,
                ),
                items:
                    _educationLevels.map((String level) {
                      return DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                onChanged:
                    _isEditing
                        ? (String? newValue) {
                          setState(() {
                            _selectedEducationLevel = newValue!;
                          });
                        }
                        : null,
              ),
              const SizedBox(height: 16),

              // School/Institution
              TextFormField(
                controller: _schoolController,
                decoration: const InputDecoration(
                  labelText: 'School/Institution',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                  hintText: 'Your school or university name',
                ),
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),

              // Grade/Year
              TextFormField(
                controller: _gradeController,
                decoration: const InputDecoration(
                  labelText: 'Grade/Year',
                  prefixIcon: Icon(Icons.class_),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 10th Grade, 2nd Year, Senior',
                ),
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),

              // Major/Field of Study
              TextFormField(
                controller: _majorController,
                decoration: const InputDecoration(
                  labelText: 'Major/Field of Study',
                  prefixIcon: Icon(Icons.subject),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Computer Science, Biology',
                ),
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),

              // Student ID
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  hintText: 'Your student identification number',
                ),
                enabled: _isEditing,
              ),

              const SizedBox(height: 32),

              // Contact Information
              Text(
                'Emergency Contact & Address',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Emergency Contact
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact',
                  prefixIcon: Icon(Icons.emergency),
                  border: OutlineInputBorder(),
                  hintText: 'Parent/Guardian contact number',
                ),
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isNotEmpty == true) {
                    final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]+$');
                    if (!phoneRegex.hasMatch(value!)) {
                      return 'Please enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  hintText: 'Your home address',
                ),
                enabled: _isEditing,
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // Account Actions
              Text(
                'Account Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Change Password
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  try {
                    await firebase_auth.FirebaseAuth.instance
                        .sendPasswordResetEmail(email: user?.email ?? '');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset email sent!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),

              const Divider(),

              // Delete Account
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text(
                  'Permanently delete your account and data',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _deleteAccount,
              ),

              const SizedBox(height: 32),

              // Account Stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Statistics',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            'Member Since',
                            _formatDate(user?.metadata.creationTime),
                          ),
                          _buildStatColumn(
                            'Last Login',
                            _formatDate(user?.metadata.lastSignInTime),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}
