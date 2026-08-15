class DepartmentStatsModel {
  final Map<String, int> departments;

  DepartmentStatsModel({required this.departments});

  factory DepartmentStatsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, int> departments = {};
    json.forEach((key, value) {
      departments[key] = (value as num).toInt();
    });
    return DepartmentStatsModel(departments: departments);
  }
}
