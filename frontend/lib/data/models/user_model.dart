class User {
  final int? id;
  final String username;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String? password;
  final int totalScore;
  final DateTime createdAt;
  final double? targetWeightKg;

  final String email;

  User({
    this.id,
    required this.username,
    required this.email,
    this.password,
    this.totalScore = 0,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    this.targetWeightKg,
    required this.createdAt,
  });

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    int? totalScore,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      totalScore: totalScore ?? this.totalScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'password': password,
        'total_score': totalScore,
        'age': age,
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'target_weight_kg': targetWeightKg, // Already snake_case in source
        'created_at': createdAt.toIso8601String(),
      };

    static User fromJson(Map<String, dynamic> json) {
    // Helper to safely parse ints from String/Int/Double
    int parseInt(dynamic value, int defaultVal) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultVal;
      return defaultVal;
    }

    // Helper to safely parse doubles
    double parseDouble(dynamic value, double defaultVal) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultVal;
      return defaultVal;
    }

    // Safely parse Date
    DateTime parseDate(dynamic value) {
       if (value is String) {
          try { return DateTime.parse(value); } catch (_) {}
       }
       return DateTime.now(); // Fallback
    }

    return User(
      id: parseInt(json['id'], 0) == 0 ? null : parseInt(json['id'], 0), // SQLite ID
      // MongoDB returns '_id', we track it locally mostly via username
      
      username: json['username']?.toString() ?? "User",
      email: json['email']?.toString() ?? json['username']?.toString() ?? "user@example.com",
      password: json['password']?.toString(),
      
      totalScore: parseInt(json['total_score'] ?? json['totalScore'], 0),
      
      age: parseInt(json['age'], 25),
      gender: json['gender']?.toString() ?? "Other",
      
      heightCm: parseDouble(json['height_cm'] ?? json['heightCm'], 170.0),
      weightKg: parseDouble(json['weight_kg'] ?? json['weightKg'], 70.0),
      
      targetWeightKg: (json['target_weight_kg'] ?? json['targetWeightKg'] ?? json['targetWeight']) != null 
          ? parseDouble(json['target_weight_kg'] ?? json['targetWeightKg'] ?? json['targetWeight'], 70.0) 
          : null,
          
      createdAt: parseDate(json['created_at'] ?? json['createdAt']), 
    );
  }
}
