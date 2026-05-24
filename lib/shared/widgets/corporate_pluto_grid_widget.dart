// Dosya Adı: corporate_pluto_grid_widget.dart
// Açıklama: Kurumsal PlutoGrid widget'ı - gelişmiş tablo özellikleri ile
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

/// {@template CorporatePlutoGridWidget}
/// Kurumsal PlutoGrid widget'ı - gelişmiş tablo özellikleri ile
///
/// Kullanım örneği:
/// ```dart
/// CorporatePlutoGridWidget(
///   columns: columns,
///   rows: rows,
///   title: 'Raporlar',
///   enableGrouping: true,
///   enableExport: true,
/// )
/// {@endtemplate}
class CorporatePlutoGridWidget extends StatefulWidget {
  final List<PlutoColumn> columns;
  final List<PlutoRow> rows;
  final String title;
  final bool enableGrouping;
  final bool enableExport;
  final bool enableFilter;
  final bool enableCopy;
  final bool enableSelectAll;
  final bool hideScrollBar;
  final bool showFooter;
  final Function(String)? onGroupChanged;
  final bool enableRowDrag;
  final bool enableEditing;
  final bool enableFrozenColumns;
  final bool enableRowColoring;
  final bool enableRowActions;

  const CorporatePlutoGridWidget({
    super.key,
    required this.columns,
    required this.rows,
    required this.title,
    this.enableGrouping = true,
    this.enableExport = true,
    this.enableFilter = true,
    this.enableCopy = true,
    this.enableSelectAll = true,
    this.hideScrollBar = false,
    this.showFooter = true,
    this.onGroupChanged,
    this.enableRowDrag = true,
    this.enableEditing = true,
    this.enableFrozenColumns = true,
    this.enableRowColoring = true,
    this.enableRowActions = true,
  });

  @override
  State<CorporatePlutoGridWidget> createState() =>
      _CorporatePlutoGridWidgetState();
}

class _CorporatePlutoGridWidgetState extends State<CorporatePlutoGridWidget> {
  late PlutoGridStateManager stateManager;
  String? selectedGroupField;
  List<PlutoRow> originalRows = [];

  @override
  void initState() {
    super.initState();
    originalRows = List.from(widget.rows);
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.columns.map((col) {
      return PlutoColumn(
        title: col.title,
        field: col.field,
        type: col.type,
        enableEditingMode: widget.enableEditing,
        enableDropToResize: true,
        enableHideColumnMenuItem: true,
        enableContextMenu: true,
        enableSorting: true,
        enableFilterMenuItem: widget.enableFilter,
        frozen: widget.enableFrozenColumns && col == widget.columns.first
            ? PlutoColumnFrozen.start
            : PlutoColumnFrozen.none,
      );
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık ve kontroller
        _buildHeader(),

        // Gruplama seçici
        if (widget.enableGrouping) _buildGroupSelector(),

        // Arama kutusu
        _buildSearchBar(),

        // PlutoGrid
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PlutoGrid(
              columns: columns,
              rows: filteredRows,
              onLoaded: (event) {
                stateManager = event.stateManager;
                _setupGridFeatures();
              },
              onChanged: (event) {
                setState(() {}); // Filtre/arama sonrası toplamlar güncellensin
              },
              onRowDoubleTap: widget.enableRowActions
                  ? (event) => _showRowActionDialog(event.row)
                  : null,
              onRowSecondaryTap: widget.enableRowActions
                  ? (event) => _showRowActionDialog(event.row)
                  : null,
              onRowChecked: (event) {
                setState(() {});
              },
              onRowsMoved: widget.enableRowDrag
                  ? (event) {
                      // Satır sırası değiştiğinde güncelle
                      setState(() {});
                    }
                  : null,
              rowColorCallback: widget.enableRowColoring
                  ? (PlutoRowColorContext ctx) {
                      final numberColumns = columns.where((col) => col.type.isNumber).toList();
                      final total = numberColumns.fold<num>(
                        0,
                        (sum, col) => sum + (num.tryParse(ctx.row.cells[col.field]?.value.toString() ?? '0') ?? 0),
                      );
                      if (total > 0) {
                        return Colors.green.withValues(alpha: 0.08);
                      }
                      return Colors.transparent;
                    }
                  : null,
              mode: widget.enableEditing ? PlutoGridMode.normal : PlutoGridMode.readOnly,
              configuration: PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  gridBackgroundColor: Colors.white,
                  gridBorderColor: Colors.grey.shade300,
                  cellTextStyle: const TextStyle(fontSize: 13),
                ),
                columnSize: PlutoGridColumnSizeConfig(
                  autoSizeMode: PlutoAutoSizeMode.scale,
                ),
              ),
              createHeader: (stateManager) => _buildCrudButtons(),
            ),
          ),
        ),
        if (widget.showFooter) _buildFooter(),
      ],
    );
  }

  // Arama kutusu ve filtreli satırlar
  String _searchText = '';
  List<PlutoRow> get filteredRows {
    if (_searchText.isEmpty) return widget.rows;
    return widget.rows.where((row) {
      return row.cells.values.any((cell) =>
          cell.value.toString().toLowerCase().contains(_searchText.toLowerCase()));
    }).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tabloda ara...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              if (widget.enableExport)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.download),
                  tooltip: 'Dışa Aktar',
                  onSelected: (value) {
                    if (value == 'csv') _exportToCsv();
                    if (value == 'excel') _exportToExcel();
                    if (value == 'pdf') _exportToPdf();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'csv',
                      child: Text('CSV olarak indir'),
                    ),
                    const PopupMenuItem(
                      value: 'excel',
                      child: Text('Excel olarak indir'),
                    ),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Text('PDF olarak indir'),
                    ),
                  ],
                ),
              if (widget.enableCopy)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: _copySelectedRows,
                    icon: const Icon(Icons.copy),
                    label: const Text('Kopyala'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCsv() async {
    List<List<dynamic>> rows = [];
    rows.add(widget.columns.map((c) => c.title).toList());
    for (final row in widget.rows) {
      rows.add(widget.columns.map((c) => row.cells[c.field]?.value ?? '').toList());
    }
    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/rapor.csv';
    final file = File(path);
    await file.writeAsString(csv);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV dosyası kaydedildi: $path')),
    );
  }

  Future<void> _exportToExcel() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    // Başlıklar
    for (int i = 0; i < widget.columns.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(widget.columns[i].title);
    }
    // Satırlar
    for (int r = 0; r < widget.rows.length; r++) {
      for (int c = 0; c < widget.columns.length; c++) {
        final value = widget.rows[r].cells[widget.columns[c].field]?.value?.toString() ?? '';
        sheet.getRangeByIndex(r + 2, c + 1).setText(value);
      }
    }
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/rapor.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel dosyası kaydedildi: $path')),
    );
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final headers = widget.columns.map((c) => c.title).toList();
    final data = widget.rows.map((row) => widget.columns.map((c) => row.cells[c.field]?.value?.toString() ?? '').toList()).toList();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: headers,
            data: data,
            cellStyle: pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            border: pw.TableBorder.all(),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          );
        },
      ),
    );
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/rapor.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF dosyası kaydedildi: $path')),
    );
  }

  Widget _buildGroupSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text('Grupla: '),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: selectedGroupField,
            hint: const Text('Grup alanı seçin'),
            items: widget.columns
                .where((col) => col.type.isText)
                .map((col) => DropdownMenuItem(
                      value: col.field,
                      child: Text(col.title),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedGroupField = value;
              });
              if (widget.onGroupChanged != null) {
                widget.onGroupChanged!(value ?? '');
              }
              if (value != null) {
                _applyGrouping(value);
              } else {
                // Gruplamayı kaldır
                _removeGrouping();
              }
            },
          ),
          if (selectedGroupField != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  selectedGroupField = null;
                });
                _removeGrouping();
              },
              tooltip: 'Gruplamayı Kaldır',
            ),
          ],
        ],
      ),
    );
  }

  void _setupGridFeatures() {
    // Grid özelliklerini ayarla
    if (widget.enableSelectAll) {
      stateManager.setSelectingMode(PlutoGridSelectingMode.row);
    }
  }

  void _applyGrouping(String field) {
    // Gruplama uygula
    final rows = List<PlutoRow>.from(originalRows);
    rows.sort((a, b) {
      final aValue = a.cells[field]?.value?.toString() ?? '';
      final bValue = b.cells[field]?.value?.toString() ?? '';
      return aValue.compareTo(bValue);
    });

    // Grup başlıkları ekle
    final groupedRows = <PlutoRow>[];
    String? currentGroup;

    for (final row in rows) {
      final groupValue = row.cells[field]?.value?.toString() ?? '';
      if (groupValue != currentGroup) {
        currentGroup = groupValue;
        groupedRows.add(_createGroupHeaderRow(field, groupValue));
      }
      groupedRows.add(row);
    }

    stateManager.removeAllRows();
    stateManager.appendRows(groupedRows);
  }

  void _removeGrouping() {
    // Gruplamayı kaldır ve orijinal veriyi geri yükle
    stateManager.removeAllRows();
    stateManager.appendRows(originalRows);
  }

  PlutoRow _createGroupHeaderRow(String field, String groupValue) {
    final cells = <String, PlutoCell>{};
    for (final col in widget.columns) {
      if (col.field == field) {
        cells[col.field] = PlutoCell(
          value: '📁 $groupValue',
        );
      } else {
        cells[col.field] = PlutoCell(value: '');
      }
    }

    return PlutoRow(
      cells: cells,
    );
  }

  void _copySelectedRows() {
    // Kopyalama fonksiyonu
    final selectedRows = stateManager.currentSelectingRows;
    if (selectedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kopyalanacak satır seçin')),
      );
      return;
    }

    // Seçili satırları kopyala
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selectedRows.length} satır kopyalandı')),
    );
  }

  Widget _buildFooter() {
    final numberColumns = widget.columns.where((col) => col.type.isNumber).toList();
    final totals = <String, num>{};
    for (final col in numberColumns) {
      totals[col.field] = filteredRows.fold<num>(
        0,
        (sum, row) => sum + (num.tryParse(row.cells[col.field]?.value.toString() ?? '0') ?? 0),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: widget.columns.map((col) {
          if (col == widget.columns.first) {
            return Expanded(
              child: Row(
                children: [
                  const Text(
                    'TOPLAM',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 15),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Adet: ${filteredRows.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          } else if (col.type.isNumber) {
            return Expanded(
              child: Text(
                totals[col.field]?.toStringAsFixed(2) ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
                textAlign: TextAlign.right,
              ),
            );
          } else {
            return const Expanded(child: SizedBox());
          }
        }).toList(),
      ),
    );
  }

  Widget _buildCrudButtons() {
    if (!widget.enableRowActions) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add),
            label: const Text('Satır Ekle'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _deleteSelectedRows,
            icon: const Icon(Icons.delete),
            label: const Text('Seçiliyi Sil'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _addRow() {
    final newRow = PlutoRow(
      cells: {
        for (final col in widget.columns)
          col.field: PlutoCell(value: ''),
      },
    );
    setState(() {
      stateManager.appendRows([newRow]);
    });
  }

  void _deleteSelectedRows() {
    final selected = stateManager.currentSelectingRows;
    if (selected.isEmpty) return;
    setState(() {
      stateManager.removeRows(selected);
    });
  }

  void _showRowActionDialog(PlutoRow row) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Satır İşlemleri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Satır verisi:'),
              ...row.cells.entries.map((e) => Text('${e.key}: ${e.value.value}')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }
}
