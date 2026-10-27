import 'package:flutter/material.dart';

/// Modal Barcode Scanner tuân thủ chỉ thị AI_AGENT_SKILL.md:
/// Bắt buộc có Manual Fallback Input và Chip mã mẫu để tránh treo camera trên Desktop/Web/CI
class BarcodeScannerSheet extends StatefulWidget {
  final ValueChanged<String>? onBarcodeDetected;

  const BarcodeScannerSheet({
    super.key,
    this.onBarcodeDetected,
  });

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final TextEditingController _manualSkuController = TextEditingController();

  final List<String> _sampleBarcodes = const [
    'BAR-8935001',
    'BAR-8935002',
    'BAR-8935003',
    'BAR-8935004',
    'BAR-8935005',
  ];

  @override
  void dispose() {
    _manualSkuController.dispose();
    super.dispose();
  }

  void _submitSku(String sku) {
    final cleanSku = sku.trim();
    if (cleanSku.isEmpty) return;

    Navigator.of(context).pop();
    widget.onBarcodeDetected?.call(cleanSku);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã nhận diện mã SKU: $cleanSku'),
        backgroundColor: const Color(0xFF0F4C81),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24, // Triệt tiêu lỗi RenderFlex khi bàn phím ảo xuất hiện
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quét hoặc Nhập Mã Vạch Vật Tư',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Hỗ trợ máy quét quang học, camera và chế độ nhập thủ công',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            // Khung giả lập Camera Viewfinder (Tự động thích ứng trên Web/Desktop/CI)
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white70, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Cảm biến Camera sẵn sàng',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hướng ống kính vào barcode trên bao bì',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Chế độ nhập tay (Manual Fallback Input) bắt buộc
            Text(
              'Nhập mã thủ công (Manual Fallback):',
              style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualSkuController,
                    decoration: const InputDecoration(
                      hintText: 'Ví dụ: BAR-8935001',
                      isDense: true,
                      prefixIcon: Icon(Icons.edit_note, size: 20),
                    ),
                    onSubmitted: _submitSku,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _submitSku(_manualSkuController.text),
                  child: const Text('Xác nhận'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Danh sách mã mẫu để kiểm thử nhanh trên Web/Desktop/CI không cần camera
            Text(
              'Mã kiểm thử nhanh (Test / CI Data Chips):',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sampleBarcodes.map((code) {
                return ActionChip(
                  label: Text(
                    code,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                  avatar: const Icon(Icons.label_outline, size: 14),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  onPressed: () {
                    _manualSkuController.text = code;
                    _submitSku(code);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
