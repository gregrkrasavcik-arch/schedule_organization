class TeacherModel {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? specialization;
  final int maxHoursPerWeek;

  TeacherModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.specialization,
    required this.maxHoursPerWeek,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      specialization: json['specialization'] as String?,
      maxHoursPerWeek: json['max_hours_per_week'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'specialization': specialization,
    'max_hours_per_week': maxHoursPerWeek,
  };
}
