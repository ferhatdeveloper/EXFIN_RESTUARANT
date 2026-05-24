// Dosya Adı: roles_modal_style.dart
// Açıklama: Tüm modal dialoglar için ortak başlık ve içerik stili sağlar.
// Oluşturulma Tarihi: 2024-06-08
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-06-08

import 'package:flutter/material.dart';
import '../../../reports/model/report_data_model.dart';

/// {@template ModalHeader}
/// Kırmızı arka plan, beyaz başlık ve ikonlar ile modal başlığı.
///
/// Kullanım örneği:
/// ```dart
/// ModalHeader(
///   title: 'Geçmiş Adisyonlar',
///   onClose: () => Navigator.pop(context),
///   actions: [IconButton(icon: Icon(Icons.filter_alt), onPressed: ...)],
/// )
/// ```
/// {@endtemplate}
class ModalHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;
  final List<Widget>? actions;
  const ModalHeader({
    Key? key,
    required this.title,
    this.onClose,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onClose ?? () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }
}

/// {@template ModalBody}
/// Modal içeriği için beyaz arka planlı, köşeleri yuvarlatılmış container.
///
/// Kullanım örneği:
/// ```dart
/// ModalBody(
///   child: ...
/// )
/// ```
/// {@endtemplate}
class ModalBody extends StatelessWidget {
  final Widget child;
  const ModalBody({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Gelişmiş, kurumsal DataGrid (DevExpress tarzı) - tüm projede kullanılacak ana tablo widget'ı
class CorporateDataGrid extends StatefulWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final int totalCount;
  final List<Widget>? topActions;
  final Widget? groupHeader;
  final void Function(String column, String value)? onColumnFilter;
  final void Function(String type)? onExport;
  final TextEditingController? globalSearchController;
  const CorporateDataGrid({
    Key? key,
    required this.columns,
    required this.rows,
    required this.totalCount,
    this.topActions,
    this.groupHeader,
    this.onColumnFilter,
    this.onExport,
    this.globalSearchController,
  }) : super(key: key);

  @override
  State<CorporateDataGrid> createState() => _CorporateDataGridState();
}

class _CorporateDataGridState extends State<CorporateDataGrid> {
  late String selectedGroupField;

  @override
  void initState() {
    super.initState();
    selectedGroupField = widget.columns.first;
  }

  Map<String, List<ReportDataModel>> groupByField(
      List<ReportDataModel> data, String field) {
    final Map<String, List<ReportDataModel>> grouped = {};
    for (final row in data) {
      String value = '';
      switch (field) {
        case 'id':
          value = row.id;
          break;
        case 'title':
          value = row.title;
          break;
        case 'value1':
          value = row.value1.toString();
          break;
        case 'value2':
          value = row.value2.toString();
          break;
        case 'value3':
          value = row.value3.toString();
          break;
        case 'date':
          value = row.date.toString();
          break;
        default:
          value = '';
      }
      grouped.putIfAbsent(value, () => []).add(row);
    }
    return grouped;
  }

  List<ReportDataModel> getReportData() {
    // ... mevcut veri dönüşüm fonksiyonu ...
    // Örnek veri
    return widget.rows.map((row) {
      return ReportDataModel(
        id: row[0],
        title: row[1],
        value1: double.tryParse(row[2]) ?? 0,
        value2: double.tryParse(row[3]) ?? 0,
        value3: double.tryParse(row[4]) ?? 0,
        date: DateTime.now(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reportData = getReportData();
    final groupOptions = widget.columns;
    final grouped = groupByField(reportData, selectedGroupField);
    final List<Widget> tableRows = [];
    grouped.forEach((group, rows) {
      // Grup başlığı satırı
      tableRows.add(Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
                child: Text('$selectedGroupField : $group',
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Text(
                'Toplam: ${rows.fold<double>(0, (sum, e) => sum + (e.value2)).toStringAsFixed(2)}  (${rows.length} Adet)'),
          ],
        ),
      ));
      // Grup altındaki satırlar
      for (final row in rows) {
        tableRows.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              for (final col in widget.columns)
                Expanded(child: Text(_getCellValue(row, col))),
            ],
          ),
        ));
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Gruplama Alanı: '),
            DropdownButton<String>(
              value: selectedGroupField,
              items: groupOptions
                  .map((col) => DropdownMenuItem(
                        value: col,
                        child: Text(col),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedGroupField = val;
                  });
                }
              },
            ),
            const Spacer(),
            if (widget.topActions != null) ...widget.topActions!,
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: tableRows,
          ),
        ),
      ],
    );
  }

  String _getCellValue(ReportDataModel row, String col) {
    switch (col) {
      case 'id':
        return row.id;
      case 'title':
        return row.title;
      case 'value1':
        return row.value1.toString();
      case 'value2':
        return row.value2.toString();
      case 'value3':
        return row.value3.toString();
      case 'date':
        return row.date.toString();
      default:
        return '';
    }
  }
}
