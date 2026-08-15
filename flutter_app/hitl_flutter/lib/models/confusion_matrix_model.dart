class ConfusionMatrixModel {
  final Map<String, Map<String, int>> matrix;
  final List<String> departments;

  ConfusionMatrixModel({required this.matrix, required this.departments});

  factory ConfusionMatrixModel.fromJson(Map<String, dynamic> json) {
    final Map<String, Map<String, int>> matrix = {};
    final Set<String> departmentSet = {};

    json.forEach((predicted, actualMap) {
      departmentSet.add(predicted);
      final Map<String, int> row = {};

      if (actualMap is Map) {
        actualMap.forEach((actual, count) {
          departmentSet.add(actual);
          row[actual] = (count as num).toInt();
        });
      }
      matrix[predicted] = row;
    });

    final departments = departmentSet.toList()..sort();
    return ConfusionMatrixModel(matrix: matrix, departments: departments);
  }
}
