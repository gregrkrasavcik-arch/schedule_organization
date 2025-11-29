class StudentModel {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final int? groupId;

  StudentModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.groupId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      groupId: json['group_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'group_id': groupId,
  };
}
