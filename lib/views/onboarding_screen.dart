import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../models/user_profile.dart';
import '../viewmodels/profile_view_model.dart';
import 'main_screen.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _selectedGender = 'Мужской';

  final maskFormatter = MaskTextInputFormatter(
    mask: '##.##.####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.health_and_safety,
                size: 50,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              const Text(
                "Давайте знакомиться",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Заполните данные для расчета норм",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Как вас зовут?'),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(labelText: 'Пол'),
                items: ['Мужской', 'Женский'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedGender = val!),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _dobController,
                keyboardType: TextInputType.number,
                inputFormatters: [maskFormatter],
                decoration: const InputDecoration(
                  labelText: 'Дата рождения (дд.мм.гггг)',
                  hintText: '01.01.1990',
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Вес (кг)'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Рост (см)'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    if (_nameController.text.isEmpty ||
                        _dobController.text.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Заполните все поля')),
                      );
                      return;
                    }

                    final user = UserProfile(
                      name: _nameController.text,
                      birthDate: _dobController.text,
                      gender: _selectedGender,
                      height: double.tryParse(_heightController.text) ?? 0,
                      weight: double.tryParse(_weightController.text) ?? 0,
                    );

                    await context.read<ProfileViewModel>().saveUserProfile(
                      user,
                    );

                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    );
                  },
                  child: const Text('Начать путь'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
