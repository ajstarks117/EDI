import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../shared/widgets/custom_widgets.dart';
import '../../../../core/services/hive_service.dart';
import '../../domain/models/emergency_contact.dart';
import '../../domain/models/tourist_profile.dart';
import '../providers/auth_state_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String? phoneNumber;

  const ProfileSetupScreen({
    super.key,
    this.phoneNumber,
  });

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;
  bool _isLoadingDraft = true;

  // Step 1: Personal Info
  final _nameController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'Indian');
  final _regionController = TextEditingController(text: 'IN');
  final _languagesController = TextEditingController(text: 'English, Hindi');
  String? _profilePhotoUrl;

  // Step 2: Identification & Medical
  String? _idType = 'Aadhaar';
  final _idNumberController = TextEditingController();
  String? _bloodGroup = 'O+';
  final _medicalController = TextEditingController();

  // Step 3: Emergency Contacts
  final List<TextEditingController> _contactNames = [];
  final List<TextEditingController> _contactPhones = [];
  final List<TextEditingController> _contactRelations = [];

  final List<String> _idTypes = ['Aadhaar', 'Passport', 'Driving License', 'Voter ID'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationalityController.dispose();
    _regionController.dispose();
    _languagesController.dispose();
    _idNumberController.dispose();
    _medicalController.dispose();
    _disposeContactControllers();
    super.dispose();
  }

  void _disposeContactControllers() {
    for (var controller in _contactNames) {
      controller.dispose();
    }
    for (var controller in _contactPhones) {
      controller.dispose();
    }
    for (var controller in _contactRelations) {
      controller.dispose();
    }
    _contactNames.clear();
    _contactPhones.clear();
    _contactRelations.clear();
  }

  void _addContactController({String name = '', String phone = '', String relation = ''}) {
    _contactNames.add(TextEditingController(text: name));
    _contactPhones.add(TextEditingController(text: phone));
    _contactRelations.add(TextEditingController(text: relation));
  }

  Future<void> _loadDraft() async {
    try {
      final box = HiveService.profileBox;
      final draft = box.get('profile_draft');
      if (draft != null) {
        _nameController.text = draft.fullName;
        _nationalityController.text = draft.nationality;
        _regionController.text = draft.regionCode;
        _languagesController.text = draft.languages.join(', ');
        _profilePhotoUrl = draft.profilePhotoUrl.isNotEmpty ? draft.profilePhotoUrl : null;
        _idType = _idTypes.contains(draft.idType) ? draft.idType : _idType;
        _idNumberController.text = draft.idNumber;
        _bloodGroup = _bloodGroups.contains(draft.bloodGroup) ? draft.bloodGroup : _bloodGroup;
        _medicalController.text = draft.medicalConditions;

        _disposeContactControllers();
        for (var contact in draft.emergencyContacts) {
          _addContactController(
            name: contact.name,
            phone: contact.phone,
            relation: contact.relation,
          );
        }
      }
    } catch (_) {
      // Ignore error loading draft
    }

    // Ensure we have at least 2 contact controllers
    while (_contactNames.length < 2) {
      _addContactController();
    }

    if (mounted) {
      setState(() {
        _isLoadingDraft = false;
      });
    }
  }

  Future<void> _saveDraft() async {
    try {
      final draft = TouristProfile(
        id: 'draft_user',
        phoneNumber: widget.phoneNumber ?? '',
        fullName: _nameController.text.trim(),
        nationality: _nationalityController.text.trim(),
        idType: _idType ?? '',
        idNumber: _idNumberController.text.trim(),
        profilePhotoUrl: _profilePhotoUrl ?? '',
        bloodGroup: _bloodGroup ?? '',
        medicalConditions: _medicalController.text.trim(),
        emergencyContacts: List.generate(_contactNames.length, (i) {
          return EmergencyContact(
            name: _contactNames[i].text.trim(),
            phone: _contactPhones[i].text.trim(),
            relation: _contactRelations[i].text.trim(),
          );
        }),
        languages: _languagesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        regionCode: _regionController.text.trim(),
        isActive: true,
      );
      final box = HiveService.profileBox;
      await box.put('profile_draft', draft);
    } catch (_) {
      // Ignore save draft failures
    }
  }

  bool _validateStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showError('Full Name is required');
        return false;
      }
      if (_nationalityController.text.trim().isEmpty) {
        _showError('Nationality is required');
        return false;
      }
      return true;
    } else if (_currentStep == 1) {
      if (_idType == null || _idType!.isEmpty) {
        _showError('ID Type is required');
        return false;
      }
      if (_idNumberController.text.trim().isEmpty) {
        _showError('ID Number is required');
        return false;
      }
      return true;
    } else if (_currentStep == 2) {
      if (_contactNames.length < 2) {
        _showError('Minimum of 2 emergency contacts required');
        return false;
      }
      for (int i = 0; i < _contactNames.length; i++) {
        final name = _contactNames[i].text.trim();
        final phone = _contactPhones[i].text.trim();
        final relation = _contactRelations[i].text.trim();

        if (name.isEmpty || phone.isEmpty || relation.isEmpty) {
          _showError('Please fill in all details for Emergency Contact #${i + 1}');
          return false;
        }
        if (!RegExp(r'^\+?\d{8,15}$').hasMatch(phone)) {
          _showError('Invalid phone number for Emergency Contact #${i + 1}');
          return false;
        }
      }
      return true;
    }
    return false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.alertRed,
      ),
    );
  }

  void _nextStep() async {
    if (_validateStep()) {
      await _saveDraft();
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        _submitProfile();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitProfile() async {
    final profile = TouristProfile(
      id: UniqueKey().toString(), // We can generate a unique id for backend
      phoneNumber: widget.phoneNumber ?? '',
      fullName: _nameController.text.trim(),
      nationality: _nationalityController.text.trim(),
      idType: _idType ?? '',
      idNumber: _idNumberController.text.trim(),
      profilePhotoUrl: _profilePhotoUrl ?? '',
      bloodGroup: _bloodGroup ?? '',
      medicalConditions: _medicalController.text.trim(),
      emergencyContacts: List.generate(_contactNames.length, (i) {
        return EmergencyContact(
          name: _contactNames[i].text.trim(),
          phone: _contactPhones[i].text.trim(),
          relation: _contactRelations[i].text.trim(),
        );
      }),
      languages: _languagesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      regionCode: _regionController.text.trim(),
      isActive: true,
    );

    final success = await ref.read(authNotifierProvider.notifier).submitProfile(profile);
    if (success) {
      // Clear draft after successful registration
      try {
        await HiveService.profileBox.delete('profile_draft');
      } catch (_) {}
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration completed successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        context.go('/blockchain-loading');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    if (_isLoadingDraft) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LoadingOverlay(
      isLoading: authState.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          title: const Text('Setup Safety Profile'),
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Bar at Top
              Padding(
                padding: const EdgeInsets.all(UiConstants.spaceMD),
                child: Column(
                  children: [
                    ProfileStepProgress(currentStep: _currentStep, totalSteps: _totalSteps),
                    const SizedBox(height: UiConstants.spaceSM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${_currentStep + 1} of $_totalSteps',
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getStepTitle(),
                          style: AppTextStyles.caption.copyWith(color: AppColors.safetyTeal, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Dynamic Form Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: UiConstants.spaceMD),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStepContent(),
                  ),
                ),
              ),
              
              // Bottom Buttons
              Padding(
                padding: const EdgeInsets.all(UiConstants.spaceMD),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primaryNavy),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: AppTextStyles.buttonText.copyWith(color: AppColors.primaryNavy),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: UiConstants.spaceSM),
                    Expanded(
                      flex: 2,
                      child: LoadingButton(
                        onPressed: _nextStep,
                        text: _currentStep == _totalSteps - 1 ? 'Complete Setup' : 'Next Step',
                        isLoading: authState.isLoading,
                        backgroundColor: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Personal Info';
      case 1:
        return 'ID & Medical';
      case 2:
        return 'Emergency Contacts';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepPersonalInfo();
      case 1:
        return _buildStepIdMedical();
      case 2:
        return _buildStepEmergencyContacts();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepPersonalInfo() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
        side: BorderSide(color: Colors.grey.shade200, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.spaceMD),
        child: Column(
          key: const ValueKey('step_personal'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile photo placeholder
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _profilePhotoUrl = 'https://api.dicebear.com/7.x/adventurer/svg?seed=${_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'traveltrek'}';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock profile photo updated.')),
                  );
                },
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: _profilePhotoUrl != null ? NetworkImage(_profilePhotoUrl!) : null,
                      child: _profilePhotoUrl == null
                          ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.safetyTeal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: UiConstants.spaceLG),
            AppTextField(
              controller: _nameController,
              labelText: 'Full Name',
              hintText: 'John Doe',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: UiConstants.spaceMD),
            AppTextField(
              controller: _nationalityController,
              labelText: 'Nationality',
              hintText: 'Indian',
              prefixIcon: Icons.flag_outlined,
            ),
            const SizedBox(height: UiConstants.spaceMD),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _regionController,
                    labelText: 'Region Code',
                    hintText: 'IN',
                    prefixIcon: Icons.pin_drop_outlined,
                  ),
                ),
                const SizedBox(width: UiConstants.spaceSM),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: _languagesController,
                    labelText: 'Languages (comma separated)',
                    hintText: 'English, Hindi',
                    prefixIcon: Icons.translate_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIdMedical() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
        side: BorderSide(color: Colors.grey.shade200, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.spaceMD),
        child: Column(
          key: const ValueKey('step_medical'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identity Verification',
              style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: UiConstants.spaceSM),
            // ID Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _idType,
              decoration: InputDecoration(
                labelText: 'ID Type',
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.safetyTeal),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: UiConstants.spaceMD, vertical: UiConstants.spaceMD),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                  borderSide: const BorderSide(color: AppColors.safetyTeal, width: 1.5),
                ),
              ),
              items: _idTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _idType = val;
                });
              },
            ),
            const SizedBox(height: UiConstants.spaceMD),
            AppTextField(
              controller: _idNumberController,
              labelText: 'ID Number',
              hintText: 'Enter document number',
              prefixIcon: Icons.password_outlined,
            ),
            const SizedBox(height: UiConstants.spaceLG),
            Text(
              'Medical Profile (Critical for Incident Response)',
              style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: UiConstants.spaceSM),
            // Blood Group Dropdown
            DropdownButtonFormField<String>(
              initialValue: _bloodGroup,
              decoration: InputDecoration(
                labelText: 'Blood Group',
                prefixIcon: const Icon(Icons.biotech_outlined, color: AppColors.safetyTeal),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: UiConstants.spaceMD, vertical: UiConstants.spaceMD),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                  borderSide: const BorderSide(color: AppColors.safetyTeal, width: 1.5),
                ),
              ),
              items: _bloodGroups.map((group) {
                return DropdownMenuItem<String>(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _bloodGroup = val;
                });
              },
            ),
            const SizedBox(height: UiConstants.spaceMD),
            AppTextField(
              controller: _medicalController,
              labelText: 'Known Allergies / Medical Conditions',
              hintText: 'e.g. Asthma, Penicillin allergy (optional)',
              prefixIcon: Icons.healing_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepEmergencyContacts() {
    return Column(
      key: const ValueKey('step_contacts'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Emergency Contacts',
          style: AppTextStyles.sectionHeader.copyWith(color: AppColors.primaryNavy),
        ),
        Text(
          'Provide details of at least 2 primary contacts. In case of safety geofence breach or SOS trigger, they will be notified immediately.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: UiConstants.spaceMD),
        
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _contactNames.length,
          separatorBuilder: (_, __) => const SizedBox(height: UiConstants.spaceSM),
          itemBuilder: (context, index) {
            return EmergencyContactInputCard(
              index: index,
              nameController: _contactNames[index],
              phoneController: _contactPhones[index],
              relationController: _contactRelations[index],
              onRemove: _contactNames.length > 2
                  ? () {
                      setState(() {
                        _contactNames[index].dispose();
                        _contactPhones[index].dispose();
                        _contactRelations[index].dispose();
                        _contactNames.removeAt(index);
                        _contactPhones.removeAt(index);
                        _contactRelations.removeAt(index);
                      });
                    }
                  : null,
            );
          },
        ),
        
        const SizedBox(height: UiConstants.spaceMD),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _addContactController();
            });
          },
          icon: const Icon(Icons.add, color: AppColors.safetyTeal),
          label: Text('Add Another Contact', style: AppTextStyles.buttonText.copyWith(color: AppColors.safetyTeal)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.safetyTeal),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiConstants.radiusSM)),
          ),
        ),
        const SizedBox(height: UiConstants.spaceLG),
      ],
    );
  }
}
