import 'package:flutter/material.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import 'package:hyperpulsex/data/database_helper.dart';
import 'package:hyperpulsex/data/models/user_model.dart';
import 'package:hyperpulsex/logic/session_service.dart';
import '../dashboard/home_screen.dart';
import 'package:hyperpulsex/logic/sync_service.dart';

class QuestionnaireScreen extends StatefulWidget {
  final String username;
  final String email;
  final String? initialPassword; // If coming from Register
  final User? existingUser;
  final Map<String, dynamic>? initialAnswers; // For editing
  final bool isEditMode;

  const QuestionnaireScreen({
    super.key, 
    required this.username, 
    required this.email,
    this.initialPassword, 
    this.existingUser, 
    this.initialAnswers,
    this.isEditMode = false,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false; 

  // Answers Store
  final Map<String, dynamic> _answers = {};
  
  // Controllers for text inputs (Section 1)
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  
  // Controllers for text inputs (Open-ended)
  final _injuryTypeCtrl = TextEditingController();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialAnswers != null) {
      _answers.addAll(widget.initialAnswers!);
      _injuryTypeCtrl.text = _answers['q7'] ?? '';
    }
    if (widget.existingUser != null) {
      _ageCtrl.text = widget.existingUser!.age.toString();
      _heightCtrl.text = widget.existingUser!.heightCm.toString();
      _weightCtrl.text = widget.existingUser!.weightKg.toString();
      _targetWeightCtrl.text = widget.existingUser!.targetWeightKg?.toString() ?? '';
    }

    // Pre-initialize defaults to pass validation even if untouched
    _answers['q33'] ??= 5.0; // Motivation
    _answers['q16'] ??= ["Strength"]; // Secondary goals default
    _answers['q32'] ??= ["None"]; // Equipment default
  }

  bool _isSectionValid() {
    switch (_currentPage) {
      case 0:
        return _ageCtrl.text.isNotEmpty &&
               _answers['q2'] != null &&
               _heightCtrl.text.isNotEmpty &&
               _weightCtrl.text.isNotEmpty &&
               _targetWeightCtrl.text.isNotEmpty;
      case 1:
        // Logic: Auto-fill Pregnancy for Males to pass validation
        if (_answers['q2'] == 'Male') {
           _answers['q10'] = "Not Applicable";
        }

        bool base = _answers['q6'] != null && _answers['q8'] != null && _answers['q9'] != null &&
                    _answers['q10'] != null && _answers['q11'] != null && _answers['q12'] != null &&
                    _answers['q13'] != null && _answers['q14'] != null;
        if (_answers['q6'] == 'Yes' && _injuryTypeCtrl.text.isEmpty) return false;
        return base;
      case 2:
        return _answers['q15'] != null && _answers['q16'] != null &&
               _answers['q17'] != null && _answers['q18'] != null && _answers['q19'] != null;
      case 3:
        return _answers['q20'] != null && _answers['q21'] != null && _answers['q22'] != null &&
               _answers['q23'] != null && _answers['q24'] != null && _answers['q25'] != null &&
               _answers['q26'] != null && _answers['q27'] != null;
      case 4:
        return _answers['q28'] != null && _answers['q29'] != null && _answers['q30'] != null &&
               _answers['q31'] != null && _answers['q32'] != null && _answers['q33'] != null &&
               _answers['q34'] != null && _answers['q35'] != null;
      default:
        return true;
    }
  }

  void _nextPage() {
    if (!_isSectionValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please answer all questions in this section to proceed.")),
      );
      return;
    }

    // LOGIC: Cross-Question Validation
    if (_currentPage == 2) { // Leaving "Fitness Goals" Section
        final currentWeight = double.tryParse(_weightCtrl.text) ?? 0;
        final targetWeight = double.tryParse(_targetWeightCtrl.text);
        final goal = _answers['q15']; // Primary Goal

        if (targetWeight != null && targetWeight > 0) {
            if (goal == "Weight Loss" && targetWeight >= currentWeight) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logic Error: For Weight Loss, Target Weight must be LESS than Current Weight."), backgroundColor: Colors.red),
                );
                return;
            }
            if (goal == "Muscle Gain" && targetWeight < currentWeight) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logic Warning: Usually Muscle Gain involves maintaining or increasing weight. Proceeding..."), backgroundColor: Colors.orange),
                );
                // We allow it (dirty bulk/cut), but warn.
            }
        }
    }

    if (_currentPage < 4) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);

    try {
      // Construct User object
      final user = User(
        id: widget.existingUser?.id,
        username: widget.username ?? widget.existingUser?.username ?? "User",
        email: widget.email,
        password: widget.initialPassword ?? widget.existingUser?.password,
        age: int.tryParse(_ageCtrl.text) ?? 0,
        gender: _answers['q2'] ?? 'Other',
        heightCm: double.tryParse(_heightCtrl.text) ?? 0,
        weightKg: double.tryParse(_weightCtrl.text) ?? 0,
        targetWeightKg: double.tryParse(_targetWeightCtrl.text),
        createdAt: widget.existingUser?.createdAt ?? DateTime.now(),
      );

      // Save/Update User
      int userId;
      if (widget.existingUser != null) {
        await DatabaseHelper.instance.updateUser(user);
        userId = widget.existingUser!.id!;
      } else {
        userId = await DatabaseHelper.instance.createUser(user);
      }

      // Save/Update Full Answers
      await DatabaseHelper.instance.saveFitnessProfile(userId, _answers);

      // Save Session for new users (Do this BEFORE cloud sync so they can enter the app immediately if it fails)
      if (widget.existingUser == null) {
        await SessionService.saveSession(userId, user.username);
      }

      // Sync to Cloud (MongoDB) - We don't 'await' this intensely, just try it.
      SyncService.syncUser(user, _answers).then((syncedUser) {
        if (syncedUser != null) {
           DatabaseHelper.instance.updateUser(syncedUser);
        }
      }).catchError((_) => null);

      if (mounted) {
        if (widget.existingUser != null) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    } catch (e) {
      debugPrint("Submission Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission failed: $e"), duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild pages to ensure controllers are bound
    final sections = [
      _buildSection1(),
      _buildSection2(),
      _buildSection3(),
      _buildSection4(),
      _buildSection5(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Step ${_currentPage + 1} of 5"),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / 5,
            backgroundColor: AppTheme.surfaceGrey,
            color: AppTheme.neonCyan,
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) => setState(() => _currentPage = p),
              children: sections,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: const Text("Back", style: TextStyle(color: Colors.white)),
                  )
                else
                  const SizedBox(),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _nextPage,
                  child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_currentPage == 4 ? "Finish" : "Next"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- SECTION 1: Personal Information ---
  Widget _buildSection1() {
    return _buildPageLayout("Personal Information", [
      _buildTextField("1. What is your age?", _ageCtrl, TextInputType.number),
      _buildDropdown("2. What is your gender?", ["Male", "Female", "Other", "Prefer not to say"], "q2"),
      _buildTextField("3. What is your height (in cm)?", _heightCtrl, TextInputType.number),
      _buildTextField("4. What is your current weight (in kg)?", _weightCtrl, TextInputType.number),
      _buildTextField("5. What is your target weight (in kg)? (Optional)", _targetWeightCtrl, TextInputType.number),
    ]);
  }

  // --- SECTION 2: Body Conditions & Health ---
  Widget _buildSection2() {
    return _buildPageLayout("Body Conditions & Health", [
      _buildRadio("6. Do you have any existing injuries?", ["Yes", "No"], "q6"),
      if (_answers["q6"] == "Yes") 
        _buildTextField("7. If yes, please specify the injury type", _injuryTypeCtrl, TextInputType.text),
      _buildRadio("8. Do you have joint problems?", ["Yes", "No"], "q8"),
      _buildRadio("9. Do you have any chronic health conditions?", ["Yes", "No"], "q9"),
      
      // Conditional Question: Pregnancy
      if (_answers['q2'] != 'Male')
        _buildRadio("10. Are you pregnant or postpartum?", ["Yes", "No", "Not Applicable"], "q10"),
        
      _buildRadio("11. Do you experience shortness of breath during physical activity?", ["Yes", "No"], "q11"),
      _buildRadio("12. Do you have balance or mobility issues?", ["Yes", "No"], "q12"),
      _buildDropdown("13. How would you rate your current flexibility?", ["Poor", "Average", "Good", "Excellent"], "q13"),
      _buildRadio("14. Are you taking any medications that affect exercise?", ["Yes", "No"], "q14"),
    ]);
  }

  // --- SECTION 3: Fitness Goals ---
  Widget _buildSection3() {
    return _buildPageLayout("Fitness Goals", [
      _buildDropdown("15. What is your primary fitness goal?", ["Weight Loss", "Muscle Gain", "Endurance", "Flexibility", "General Health"], "q15"),
      _buildMultiSelect("16. Any secondary goals?", ["Tone Up", "Stress Relief", "Posture Correction", "Strength"], "q16"),
      _buildDropdown("17. What is your target timeframe for achieving your goal?", ["1 Month", "3 Months", "6 Months", "1 Year"], "q17"),
      _buildDropdown("18. What workout intensity do you prefer?", ["Low", "Medium", "High"], "q18"),
      _buildDropdown("19. What is your current eating pattern?", ["Omnivore", "Vegetarian", "Vegan", "Keto", "Intermittent Fasting"], "q19"),
    ]);
  }

  // --- SECTION 4: Current Fitness Level ---
  Widget _buildSection4() {
    return _buildPageLayout("Current Fitness Level", [
      _buildDropdown("20. How often do you currently exercise?", ["Never", "1-2 days/week", "3-4 days/week", "5+ days/week"], "q20"),
      _buildDropdown("21. What is your exercise history?", ["Beginner", "Intermediate", "Advanced", "Athlete"], "q21"),
      _buildRadio("22. Can you do 10 push-ups with proper form?", ["Yes", "No"], "q22"),
      _buildRadio("23. Can you do 20 squats without stopping?", ["Yes", "No"], "q23"),
      _buildRadio("24. Can you hold a plank for 30 seconds?", ["Yes", "No"], "q24"),
      _buildRadio("25. Can you jog/run continuously for 10 minutes?", ["Yes", "No"], "q25"),
      _buildDropdown("26. How quickly do you get tired during physical activity?", ["Very Quickly", "Moderately", "Slowly"], "q26"),
      _buildDropdown("27. How long does it take you to recover after exercise?", ["Few minutes", "An hour", "Next day"], "q27"),
    ]);
  }

  // --- SECTION 5: Lifestyle & Commitment ---
  Widget _buildSection5() {
    return _buildPageLayout("Lifestyle & Commitment", [
      _buildDropdown("28. How many days per week can you realistically exercise?", ["1", "2", "3", "4", "5", "6", "7"], "q28"),
      _buildDropdown("29. How much time can you dedicate per workout session?", ["15 min", "30 min", "45 min", "1 hr", "1.5 hr+"], "q29"),
      _buildDropdown("30. When do you prefer to work out?", ["Morning", "Afternoon", "Evening", "Night"], "q30"),
      _buildDropdown("31. Where will you primarily work out?", ["Gym", "Home", "Outdoors"], "q31"),
      _buildMultiSelect("32. Do you have any exercise equipment?", ["None", "Dumbbells", "Resistance Bands", "Yoga Mat", "Treadmill"], "q32"),
      _buildSlider("33. How would you rate your current motivation level (1-10)?", "q33"),
      _buildDropdown("34. What are your biggest obstacles to exercising?", ["Time", "Motivation", "Knowledge", "Injury", "None"], "q34"),
      _buildRadio("35. Have you tried exercise programs before?", ["Yes", "No"], "q35"),
    ]);
  }

  // --- WIDGET HELPERS ---

  Widget _buildPageLayout(String title, List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
        const SizedBox(height: 20),
        ...children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 20), child: c)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label *", style: const TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: const InputDecoration(filled: true),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label *", style: const TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _answers[key],
          dropdownColor: AppTheme.surfaceGrey,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (val) => setState(() => _answers[key] = val),
          decoration: const InputDecoration(filled: true),
        ),
      ],
    );
  }

  Widget _buildRadio(String label, List<String> options, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label *", style: const TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          children: options.map((o) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: o,
                groupValue: _answers[key],
                activeColor: AppTheme.neonCyan,
                onChanged: (val) => setState(() => _answers[key] = val),
              ),
              Text(o),
            ],
          )).toList(),
        ),
      ],
    );
  }
  
  Widget _buildMultiSelect(String label, List<String> options, String key) {
    // Simplified as a Wrap of FilterChips for UI
    List<String> selected = [];
    if (_answers[key] != null) {
      selected = List<String>.from(_answers[key]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label *", style: const TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((o) {
            final isSelected = selected.contains(o);
            return FilterChip(
              label: Text(o),
              selected: isSelected,
              selectedColor: AppTheme.neonCyan.withOpacity(0.5),
              onSelected: (bool value) {
                setState(() {
                  if (value) {
                    selected.add(o);
                  } else {
                    selected.remove(o);
                  }
                  _answers[key] = selected;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSlider(String label, String key) {
    double val = _answers[key] ?? 5.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${val.round()} *", style: const TextStyle(fontSize: 16, color: Colors.white70)),
        Slider(
          value: val,
          min: 1, max: 10, divisions: 9,
          activeColor: AppTheme.neonCyan,
          onChanged: (v) => setState(() => _answers[key] = v),
        )
      ],
    );
  }
}
