enum InstitutePlan { basic, standard, premium }

enum InstituteStatus { active, expired, blocked }

class Institute {
  const Institute({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.plan,
    required this.status,
    required this.studentsCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerName;
  final String email;
  final String phone;
  final InstitutePlan plan;
  final InstituteStatus status;
  final int studentsCount;
  final DateTime createdAt;
}

