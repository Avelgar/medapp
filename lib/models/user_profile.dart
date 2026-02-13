import 'dart:convert';
import 'package:intl/intl.dart';

class UserProfile {
  String name;
  String birthDate;
  String gender;
  double height;
  double weight;

  String weightGoal;

  UserProfile({
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.height,
    required this.weight,
    this.weightGoal = 'maintain',
  });

  int get age {
    try {
      final dob = DateFormat('dd.MM.yyyy').parse(birthDate);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  double get bmr {
    double base = (10 * weight) + (6.25 * height) - (5 * age);
    if (gender == 'Мужской') {
      return base + 5;
    } else {
      return base - 161;
    }
  }

  int get baseWaterNorm {
    double val = (height - 100) * 30;
    return val > 0 ? val.round() : 1500;
  }

  double get sleepNorm {
    if (age >= 14 && age <= 17) return 9.0;
    if (age >= 18 && age <= 25) return 8.0;
    if (age >= 26 && age <= 64) return 8.0;
    if (age >= 65) return 7.5;
    return 8.0;
  }

  String toJson() {
    return jsonEncode({
      'name': name,
      'birthDate': birthDate,
      'gender': gender,
      'height': height,
      'weight': weight,
      'weightGoal': weightGoal,
    });
  }

  factory UserProfile.fromJson(String source) {
    final map = jsonDecode(source);
    return UserProfile(
      name: map['name'],
      birthDate: map['birthDate'],
      gender: map['gender'],
      height: map['height'],
      weight: map['weight'],
      weightGoal: map['weightGoal'] ?? 'maintain',
    );
  }

  UserProfile copyWith({
    String? name,
    String? birthDate,
    String? gender,
    double? height,
    double? weight,
    String? weightGoal,
  }) {
    return UserProfile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      weightGoal: weightGoal ?? this.weightGoal,
    );
  }
}
