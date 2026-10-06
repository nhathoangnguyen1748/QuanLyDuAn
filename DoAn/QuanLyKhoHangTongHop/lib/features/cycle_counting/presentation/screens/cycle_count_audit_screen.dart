import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/cycle_count_session.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/services/pdf_report_service.dart';
import 'package:smartstock_admin/core/services/excel_export_service.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/features/scanner/presentation/barcode_scanner_sheet.dart';

class CycleCountAuditScreen extends ConsumerStatefulWidget {
  final CycleCountSession session;

  const CycleCountAuditScreen({super.key, required this.session});

  @override
  ConsumerState<CycleCountAuditScreen> createState() => _CycleCountAuditScreenState();
}

class _CycleCountAuditScreenState extends ConsumerState<CycleCountAuditScreen> {
  late CycleCountSession _session;
  String _searchQuery = '';
  int _statusFilter = 0; // 0: Tất cả, 1: Chưa kiểm, 2: Khớp, 3: Lệch

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  Future<void> _scanBarcodeToCount() async {
    final barcode = await BarcodeScannerSheet.scan(
      context,
      title: 'Quét Barcode Đối Soát Kiểm Kê',
      prompt: 'Quét mã vạch trên sản phẩm hoặc thùng hàng',
    );

    if (barcode != null && barcode.isNotEmpty && mounted) {
      final index = _session.items.indexWhere((i) => i.barcode == barcode || i.skuCode == barcode);
      if (index != -1) {
        final item = _session.items[index];
        _promptQuantityDialog(item, index);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mã "$barcode" không nằm trong đợt kiểm kê này!'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _promptQuantityDialog(CycleCountItem item, int index) {
    final initialCount = item.isAudited ? item.physicalCount : item.bookStock;
    final controller = TextEditingController(text: '$initialCount');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final currentVal = int.tryParse(controller.text) ?? 0;
            final diff = currentVal - item.bookStock;
            final diffPercent = item.bookStock == 0 ? (currentVal > 0 ? 100.0 : 0.0) : (diff / item.bookStock) * 100;
            final diffValue = diff * item.costPrice;

            Color statusColor;
            String statusText;
            if (diff == 0) {
              statusColor = AppColors.success;
              statusText = 'KHỚP SỔ SÁCH';
            } else if (diff > 0) {
              statusColor = AppColors.warning;
              statusText = 'THỪA +$diff';
            } else {
              statusColor = AppColors.danger;
              statusText = 'THIẾU $diff';
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.skuCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.skuName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Vị trí kệ: ${item.locationTag} • Sổ sách: ${item.bookStock}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 14),

                    // Input
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng thực tế kiểm đếm',
                        suffixText: 'đơn vị',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),

                    // Realtime Variance Preview Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor)),
                              Text('${diffPercent >= 0 ? '+' : ''}${diffPercent.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor)),
                            ],
                          ),
                          if (diff != 0) ...[
                            const SizedBox(height: 4),
                            Text('Lệch giá trị: ${diff > 0 ? '+' : ''}${CurrencyFormatter.formatVND(diffValue)}', style: TextStyle(fontSize: 11, color: statusColor)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick quantity buttons
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          label: const Text('-5', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final cur = int.tryParse(controller.text) ?? 0;
                            final newVal = (cur - 5) < 0 ? 0 : cur - 5;
                            controller.text = '$newVal';
                            setDialogState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('-1', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final cur = int.tryParse(controller.text) ?? 0;
                            final newVal = (cur - 1) < 0 ? 0 : cur - 1;
                            controller.text = '$newVal';
                            setDialogState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('+1', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final cur = int.tryParse(controller.text) ?? 0;
                            controller.text = '${cur + 1}';
                            setDialogState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('+5', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final cur = int.tryParse(controller.text) ?? 0;
                            controller.text = '${cur + 5}';
                            setDialogState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('+10', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final cur = int.tryParse(controller.text) ?? 0;
                            controller.text = '${cur + 10}';
                            setDialogState(() {});
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.check, size: 14, color: AppColors.success),
                          label: Text('Khớp (${item.bookStock})', style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            controller.text = '${item.bookStock}';
                            setDialogState(() {});
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.clear, size: 14, color: AppColors.danger),
                          label: const Text('Hết hàng (0)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            controller.text = '0';
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final qty = int.tryParse(controller.text) ?? 0;
                    setState(() {
                      item.physicalCount = qty;
                      item.isAudited = true;
                      if (_session.auditedCount == _session.items.length && _session.status == CycleCountStatus.inProgress) {
                        _session.status = CycleCountStatus.completed;
                      }
                    });
                    Navigator.pop(ctx);
                    await ref.read(cycleCountListProvider.notifier).saveSession(_session);

                    if (mounted) {
                      final sign = item.varianceQty > 0 ? '+' : '';
                      final msg = item.varianceQty == 0
                          ? 'Đã khớp tồn (${item.bookStock})'
                          : 'Lệch: $sign${item.varianceQty} (${item.discrepancyStatus})';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.skuCode}: $msg'),
                          backgroundColor: item.varianceQty == 0 ? AppColors.success : (item.varianceQty > 0 ? AppColors.warning : AppColors.danger),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text('Ghi nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _quickMatchItem(CycleCountItem item) async {
    setState(() {
      item.physicalCount = item.bookStock;
      item.isAudited = true;
      if (_session.auditedCount == _session.items.length && _session.status == CycleCountStatus.inProgress) {
        _session.status = CycleCountStatus.completed;
      }
    });
    await ref.read(cycleCountListProvider.notifier).saveSession(_session);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.skuCode}: Đã xác nhận khớp tồn (${item.bookStock})'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _editNotesDialog() {
    final notesController = TextEditingController(text: _session.notes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghi Chú Đợt Kiểm Kê'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú hoặc kết luận kiểm kê...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _session.notes = notesController.text.trim();
              });
              await ref.read(cycleCountListProvider.notifier).saveSession(_session);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _reconcileInventory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Điều Chỉnh Kho?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hệ thống sẽ cập nhật số tồn kho thực tế cho tất cả mặt hàng đã kiểm trong đợt này.'),
            const SizedBox(height: 8),
            Text('Số SKU có sai lệch: ${_session.discrepancyItemsCount} SKU', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
            Text('Tổng chênh lệch giá trị: ${CurrencyFormatter.formatVND(_session.totalVarianceValue)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Duyệt & Cân Bằng Tồn'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(cycleCountListProvider.notifier).reconcile(_session.id);
      setState(() {
        _session.status = CycleCountStatus.reconciled;
        _session.completedAt = DateTime.now();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cân bằng số tồn kho theo biên bản kiểm kê!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _session.items.where((i) {
      // 1. Status Filter
      if (_statusFilter == 1 && i.isAudited) return false;
      if (_statusFilter == 2 && (!i.isAudited || i.varianceQty != 0)) return false;
      if (_statusFilter == 3 && (!i.isAudited || i.varianceQty == 0)) return false;

      // 2. Search Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return i.skuName.toLowerCase().contains(q) ||
            i.skuCode.toLowerCase().contains(q) ||
            i.barcode.contains(q) ||
            i.locationTag.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final isReconciled = _session.status == CycleCountStatus.reconciled;

    return Scaffold(
      appBar: AppBar(
        title: Text(_session.sessionCode, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Ghi chú đợt kiểm kê',
            icon: const Icon(Icons.note_alt_outlined),
            onPressed: _editNotesDialog,
          ),
          IconButton(
            tooltip: 'In Biên Bản Kiểm Kê PDF',
            icon: const Icon(Icons.print_outlined, color: AppColors.primary),
            onPressed: () async {
              await PdfReportService.printCycleCountReport(_session);
            },
          ),
          IconButton(
            tooltip: 'Xuất file Excel Kiểm Kê',
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: () async {
              await ExcelExportService.exportCycleCount(_session);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(_session.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isReconciled ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _session.status.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isReconciled ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_session.notes != null && _session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Ghi chú: ${_session.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight)),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Đã kiểm', '${_session.auditedCount}/${_session.items.length}', AppColors.primary),
                    _buildStatCol('Khớp chuẩn', '${_session.matchedItemsCount}', AppColors.success),
                    _buildStatCol('Sai lệch', '${_session.discrepancyItemsCount}', _session.discrepancyItemsCount > 0 ? AppColors.danger : AppColors.textSecondaryLight),
                    _buildStatCol('Lệch giá trị', CurrencyFormatter.formatCompactVND(_session.totalVarianceValue), _session.totalVarianceValue >= 0 ? AppColors.success : AppColors.danger),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _session.items.isNotEmpty ? _session.auditedCount / _session.items.length : 0,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(isReconciled ? AppColors.success : AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search & Fast Scan button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Tìm SKU, Barcode, Kệ...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _scanBarcodeToCount,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Quét đối soát'),
                ),
              ],
            ),
          ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Tất cả (${_session.items.length})'),
                  selected: _statusFilter == 0,
                  onSelected: (val) {
                    if (val) setState(() => _statusFilter = 0);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Chưa kiểm (${_session.items.length - _session.auditedCount})'),
                  selected: _statusFilter == 1,
                  onSelected: (val) {
                    if (val) setState(() => _statusFilter = 1);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Khớp (${_session.matchedItemsCount})'),
                  selected: _statusFilter == 2,
                  selectedColor: AppColors.success.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _statusFilter == 2 ? AppColors.success : null,
                    fontWeight: _statusFilter == 2 ? FontWeight.bold : null,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _statusFilter = 2);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Sai lệch (${_session.discrepancyItemsCount})'),
                  selected: _statusFilter == 3,
                  selectedColor: AppColors.danger.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _statusFilter == 3 ? AppColors.danger : null,
                    fontWeight: _statusFilter == 3 ? FontWeight.bold : null,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _statusFilter = 3);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Items Table
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy mặt hàng phù hợp với bộ lọc'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final sign = item.varianceQty > 0 ? '+' : '';

                      Color statusColor = Colors.grey;
                      if (item.isAudited) {
                        if (item.varianceQty == 0) {
                          statusColor = AppColors.success;
                        } else if (item.varianceQty > 0) {
                          statusColor = AppColors.warning;
                        } else {
                          statusColor = AppColors.danger;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.2),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _promptQuantityDialog(item, index),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item.skuCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.discrepancyStatus,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: statusColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(item.skuName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Kệ: ${item.locationTag}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                    Text('Sổ sách: ${item.bookStock}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    Text(
                                      'Thực tế: ${item.isAudited ? item.physicalCount : "Chưa kiểm"}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: item.isAudited ? Colors.black : Colors.grey,
                                      ),
                                    ),
                                    if (item.isAudited)
                                      Text(
                                        'Lệch: $sign${item.varianceQty}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                  ],
                                ),
                                if (item.isAudited && item.varianceQty != 0) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Chênh lệch giá trị: $sign${CurrencyFormatter.formatVND(item.varianceValue)} (${item.variancePercent.toStringAsFixed(1)}%)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ],
                                if (!item.isAudited) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _quickMatchItem(item),
                                        icon: const Icon(Icons.check, size: 14, color: AppColors.success),
                                        label: Text('Khớp (${item.bookStock})', style: const TextStyle(fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _promptQuantityDialog(item, index),
                                        icon: const Icon(Icons.edit, size: 14),
                                        label: const Text('Nhập số lượng', style: TextStyle(fontSize: 11)),
                                        style: ElevatedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action: Reconcile
          if (!isReconciled)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _reconcileInventory,
                icon: const Icon(Icons.fact_check),
                label: const Text('PHÊ DUYỆT & ĐIỀU CHỈNH TỒN KHO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
      ],
    );
  }
}
