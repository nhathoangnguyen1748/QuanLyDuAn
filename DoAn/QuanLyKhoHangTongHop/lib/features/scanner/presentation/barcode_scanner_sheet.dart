import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';

class BarcodeScannerSheet extends StatefulWidget {
  final String title;
  final String prompt;

  const BarcodeScannerSheet({
    super.key,
    this.title = 'Quét mã Barcode / QR Code',
    this.prompt = 'Đặt mã vạch hoặc mã QR vào khung ngắm để quét',
  });

  /// Hàm tiện ích mở BottomSheet quét mã vạch
  static Future<String?> scan(BuildContext context, {String? title, String? prompt}) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BarcodeScannerSheet(
        title: title ?? 'Quét mã Barcode / QR Code',
        prompt: prompt ?? 'Đặt mã vạch hoặc mã QR vào khung ngắm để quét',
      ),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  late final MobileScannerController _scannerController;
  final TextEditingController _manualController = TextEditingController();
  bool _isTorchOn = false;
  bool _isFrontCamera = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() => _hasScanned = true);
        Navigator.pop(context, barcode.rawValue);
        break;
      }
    }
  }

  void _submitManual() {
    final text = _manualController.text.trim();
    if (text.isNotEmpty) {
      Navigator.pop(context, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: _isTorchOn ? Colors.amber : Colors.white70),
                  onPressed: () {
                    _scannerController.toggleTorch();
                    setState(() => _isTorchOn = !_isTorchOn);
                  },
                ),
                IconButton(
                  icon: Icon(_isFrontCamera ? Icons.camera_front : Icons.camera_rear, color: Colors.white70),
                  onPressed: () {
                    _scannerController.switchCamera();
                    setState(() => _isFrontCamera = !_isFrontCamera);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Camera Viewport & Overlay
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off, size: 64, color: Colors.white38),
                            const SizedBox(height: 12),
                            const Text(
                              'Không thể mở Camera trên thiết bị này.\nVui lòng nhập mã vạch thủ công bên dưới.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Viewfinder Target Frame
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryLight, width: 2.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                // Prompt message at bottom of camera
                Positioned(
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.prompt,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Manual Entry Fallback Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Hoặc nhập mã vạch thủ công / giả lập quét:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập Barcode hoặc SKU...',
                          prefixIcon: Icon(Icons.keyboard),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _submitManual(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _submitManual,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Xác nhận'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quick chip suggestions for demo / fast testing
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Mã mẫu: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      _sampleBarcodeChip('8938501230012', 'iPhone 15'),
                      _sampleBarcodeChip('8938501230029', 'Sony TV'),
                      _sampleBarcodeChip('8938501230074', 'Sữa Hạt'),
                      _sampleBarcodeChip('8938501230104', 'Nước Giặt'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sampleBarcodeChip(String barcode, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text('$label ($barcode)', style: const TextStyle(fontSize: 10)),
        onPressed: () {
          _manualController.text = barcode;
          _submitManual();
        },
      ),
    );
  }
}
