class ReportModel {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;

  ReportModel({
    required this.id,
    required this.type,
    required this.title,
    required this.data,
    required this.createdAt,
    this.startDate,
    this.endDate,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      data: json['data'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  ReportModel copyWith({
    String? id,
    String? type,
    String? title,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ReportModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
