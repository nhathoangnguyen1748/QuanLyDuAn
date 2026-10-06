import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/cycle_count_session.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';
import 'cycle_count_audit_screen.dart';

class CycleCountListScreen extends ConsumerWidget {
  const CycleCountListScreen({super.key});

  void _showCreateSessionDialog(BuildContext context, WidgetRef ref) {
    final allProducts = ref.read(productListProvider);
    final categories = ref.read(categoryListProvider);

    // Extract unique shelf zones (e.g. KHO-A, KHO-B, KHO-C, or first 5 chars)
    final Set<String> zones = {};
    for (final p in allProducts) {
      if (p.locationTag.isNotEmpty) {
        final parts = p.locationTag.split('-');
        if (parts.length >= 2) {
          zones.add('${parts[0]}-${parts[1]}'); // VD: KHO-A, KHO-B
        } else {
          zones.add(p.locationTag);
        }
      }
    }
    final sortedZones = zones.toList()..sort();

    int scopeType = 0; // 0: Toàn kho, 1: Phân khu kệ, 2: Ngành hàng
    String selectedZone = sortedZones.isNotEmpty ? sortedZones.first : '';
    String selectedCategoryId = categories.isNotEmpty ? categories.first.id : '';

    final titleController = TextEditingController(
      text: 'Kiểm kê định kỳ tháng ${DateTime.now().month}/${DateTime.now().year}',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            List selectedProducts;
            String scopeDescription;

            if (scopeType == 1 && selectedZone.isNotEmpty) {
              selectedProducts = allProducts.where((p) => p.locationTag.startsWith(selectedZone)).toList();
              scopeDescription = 'Phân khu kệ $selectedZone';
            } else if (scopeType == 2 && selectedCategoryId.isNotEmpty) {
              final cat = categories.firstWhere((c) => c.id == selectedCategoryId, orElse: () => categories.first);
              selectedProducts = allProducts.where((p) => p.categoryId == selectedCategoryId).toList();
              scopeDescription = 'Ngành hàng ${cat.name}';
            } else {
              selectedProducts = allProducts;
              scopeDescription = 'Toàn bộ kho hàng';
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.fact_check, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Tạo Đợt Kiểm Kê Mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên đợt kiểm kê *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Phạm vi kiểm kê:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Toàn kho', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 1, label: Text('Theo kệ', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 2, label: Text('Ngành', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {scopeType},
                      onSelectionChanged: (val) {
                        setState(() {
                          scopeType = val.first;
                          if (scopeType == 1) {
                            titleController.text = 'Kiểm kê phân khu kệ $selectedZone';
                          } else if (scopeType == 2) {
                            final cat = categories.firstWhere((c) => c.id == selectedCategoryId, orElse: () => categories.first);
                            titleController.text = 'Kiểm kê ngành hàng ${cat.name}';
                          } else {
                            titleController.text = 'Kiểm kê định kỳ tháng ${DateTime.now().month}/${DateTime.now().year}';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Selector for shelf zone
                    if (scopeType == 1) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedZone,
                        decoration: const InputDecoration(
                          labelText: 'Chọn dãy kệ / Phân khu',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: sortedZones.map((z) {
                          final count = allProducts.where((p) => p.locationTag.startsWith(z)).length;
                          return DropdownMenuItem(
                            value: z,
                            child: Text('$z ($count SKU)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedZone = val;
                              titleController.text = 'Kiểm kê phân khu kệ $selectedZone';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Selector for category
                    if (scopeType == 2) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Chọn ngành hàng',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: categories.map((c) {
                          final count = allProducts.where((p) => p.categoryId == c.id).length;
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.name} ($count SKU)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedCategoryId = val;
                              final cat = categories.firstWhere((c) => c.id == selectedCategoryId, orElse: () => categories.first);
                              titleController.text = 'Kiểm kê ngành hàng ${cat.name}';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // SKU Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đã chọn: ${selectedProducts.length} mặt hàng SKU cho đợt kiểm này ($scopeDescription).',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: selectedProducts.isEmpty
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final items = selectedProducts.map((p) {
                            return CycleCountItem(
                              skuId: p.id,
                              skuCode: p.skuCode,
                              skuName: p.name,
                              barcode: p.barcode,
                              locationTag: p.locationTag,
                              bookStock: p.currentStock,
                              physicalCount: p.currentStock,
                              costPrice: p.costPrice,
                              isAudited: false,
                            );
                          }).toList();

                          final now = DateTime.now();
                          final newSession = CycleCountSession(
                            id: const Uuid().v4(),
                            sessionCode: 'KK-${now.year}${now.month.toString().padLeft(2, '0')}-${now.minute}${now.second}',
                            title: title,
                            scope: scopeDescription,
                            items: items,
                            createdAt: now,
                          );

                          await ref.read(cycleCountListProvider.notifier).saveSession(newSession);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CycleCountAuditScreen(session: newSession)),
                            );
                          }
                        },
                  child: const Text('Bắt đầu kiểm kê'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(cycleCountListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm Kê Định Kỳ (Cycle Count)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Chưa có đợt kiểm kê nào', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateSessionDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo Đợt Kiểm Kê Mới'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isReconciled = session.status == CycleCountStatus.reconciled;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CycleCountAuditScreen(session: session)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                session.sessionCode,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isReconciled ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  session.status.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isReconciled ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(session.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Phạm vi: ${session.scope} • Ngày tạo: ${DateFormatter.formatDate(session.createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tiến độ: ${session.auditedCount}/${session.items.length} SKU',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Sai lệch: ${session.discrepancyItemsCount} SKU (${CurrencyFormatter.formatCompactVND(session.totalVarianceValue)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: session.discrepancyItemsCount > 0 ? AppColors.danger : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: session.items.isNotEmpty ? session.auditedCount / session.items.length : 0,
                              minHeight: 5,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(isReconciled ? AppColors.success : AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSessionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Đợt Kiểm Kê Mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
