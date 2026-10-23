import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  final TextEditingController _manualController = TextEditingController();
  late final AnimationController _laserAnimController;
  late final Animation<double> _laserPositionAnimation;

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

    // Laser scanning line animation
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserPositionAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
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
        HapticFeedback.mediumImpact();
        Navigator.pop(context, barcode.rawValue);
        break;
      }
    }
  }

  void _submitManual() {
    final text = _manualController.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      Navigator.pop(context, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.88,
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Hỗ trợ EAN-13, Code 128, QR Code & Nhập tay',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _isTorchOn ? 'Tắt Flash' : 'Bật Flash',
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: _isTorchOn ? Colors.amber : Colors.white70,
                  ),
                  onPressed: () {
                    _scannerController.toggleTorch();
                    setState(() => _isTorchOn = !_isTorchOn);
                  },
                ),
                IconButton(
                  tooltip: 'Đổi Camera',
                  icon: Icon(
                    _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    _scannerController.switchCamera();
                    setState(() => _isFrontCamera = !_isFrontCamera);
                  },
                ),
                IconButton(
                  tooltip: 'Đóng',
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
                            const Icon(Icons.videocam_off, size: 56, color: Colors.white38),
                            const SizedBox(height: 12),
                            const Text(
                              'Không thể mở Camera trên môi trường này (Desktop/Web/Giả lập).\nBạn có thể chọn mã mẫu hoặc gõ barcode ở thanh bên dưới.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Viewfinder Target Frame
                SizedBox(
                  width: 270,
                  height: 270,
                  child: Stack(
                    children: [
                      // Outer border with corner notches
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryLight, width: 2.5),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryLight.withValues(alpha: 0.15),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      // Animated Laser Beam
                      AnimatedBuilder(
                        animation: _laserPositionAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 270 * _laserPositionAnimation.value,
                            left: 12,
                            right: 12,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF38BDF8),
                                    Color(0xFF00E5FF),
                                    Color(0xFF38BDF8),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 1.5,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Prompt message at bottom of camera
                Positioned(
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.center_focus_strong, size: 16, color: AppColors.primaryLight),
                        const SizedBox(width: 8),
                        Text(
                          widget.prompt,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nhập mã thủ công / Kiểm thử nhanh:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    InkWell(
                      onTap: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data != null && data.text != null && data.text!.isNotEmpty) {
                          _manualController.text = data.text!.trim();
                          _submitManual();
                        }
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.content_paste, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Dán mã', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualController,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Nhập Barcode (VD: 8938501230012) hoặc SKU...',
                          prefixIcon: const Icon(Icons.keyboard_outlined, size: 20),
                          suffixIcon: _manualController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _manualController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submitManual(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _submitManual,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Nhập'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Quick chip suggestions from SeedData
                const Text(
                  'Mã vạch mẫu (Click để kiểm thử ngay):',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _sampleBarcodeChip('8938501230012', 'iPhone 15'),
                      _sampleBarcodeChip('8938501230029', 'Sony TV 65"'),
                      _sampleBarcodeChip('8938501230036', 'Dell XPS 13'),
                      _sampleBarcodeChip('8938501230043', 'Nồi chiên Philips'),
                      _sampleBarcodeChip('8938501230050', 'Robot Xiaomi'),
                      _sampleBarcodeChip('8938501230074', 'Sữa TH Nut'),
                      _sampleBarcodeChip('8938501230104', 'Nước giặt OMO'),
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
        avatar: const Icon(Icons.qr_code, size: 14, color: AppColors.primary),
        label: Text('$label ($barcode)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        onPressed: () {
          _manualController.text = barcode;
          _submitManual();
        },
      ),
    );
  }
}
