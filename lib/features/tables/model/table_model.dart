class TableModel {
  final String id;
  final String name;
  final int number;
  final String salon;
  final int capacity;
  final String status; // 'available', 'occupied', 'reserved'
  final String? currentOrderId;
  final DateTime? lastUpdated;
  final bool isActive;

  TableModel({
    required this.id,
    required this.name,
    required this.number,
    required this.salon,
    required this.capacity,
    required this.status,
    this.currentOrderId,
    this.lastUpdated,
    this.isActive = true,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      number: json['number'] ?? 0,
      salon: json['salon'] ?? '',
      capacity: json['capacity'] ?? 0,
      status: json['status'] ?? 'available',
      currentOrderId: json['current_order_id'],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'salon': salon,
      'capacity': capacity,
      'status': status,
      'current_order_id': currentOrderId,
      'last_updated': lastUpdated?.toIso8601String(),
      'is_active': isActive,
    };
  }

  TableModel copyWith({
    String? id,
    String? name,
    int? number,
    String? salon,
    int? capacity,
    String? status,
    String? currentOrderId,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      salon: salon ?? this.salon,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
}
