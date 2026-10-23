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
    final titleController = TextEditingController(text: 'Kiểm kê định kỳ tháng ${DateTime.now().month}/${DateTime.now().year}');
    final scopeController = TextEditingController(text: 'Toàn bộ kho hàng');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tạo Phiên Kiểm Kê Mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tên đợt kiểm kê *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scopeController,
                decoration: const InputDecoration(labelText: 'Phạm vi kiểm (Kệ A, Toàn kho,...) *'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final scope = scopeController.text.trim();
                if (title.isEmpty) return;

                final products = ref.read(productListProvider);
                final items = products.map((p) {
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
                  scope: scope,
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
