import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_colors.dart';
import 'app_header.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Full-screen barcode/QR scanner. Pops with the scanned code (String),
/// or null if the user backs out without scanning anything.
class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key, this.title = 'Scan barcode'});
  final String title;

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  late final MobileScannerController _controller;
  final _manualCtrl = TextEditingController();
  bool _manualMode = false;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _toggleManualMode() {
    setState(() => _manualMode = !_manualMode);
    if (_manualMode) {
      _controller.stop();
    } else {
      _controller.start();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;
    _handled = true;
    Navigator.pop(context, code);
  }

  void _submitManual() {
    final code = _manualCtrl.text.trim();
    if (code.isEmpty) return;
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: widget.title,
              onBack: () => Navigator.pop(context),
              trailing: GestureDetector(
                onTap: _toggleManualMode,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(_manualMode ? Icons.qr_code_2 : Icons.keyboard_outlined,
                      size: 20, color: AppColors.textMuted),
                ),
              ),
            ),
            Expanded(
              child: _manualMode
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppTextField(
                            label: 'BARCODE',
                            controller: _manualCtrl,
                            placeholder: 'e.g. 4792024031019',
                            numeric: true,
                            autofocus: true,
                          ),
                          const SizedBox(height: 12),
                          AppButton(label: 'Use this code', onPressed: _submitManual, expand: true),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: _onDetect,
                          errorBuilder: (context, error, child) => Container(
                            color: AppColors.background,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(16),
                            child: const Text(
                              'Camera unavailable.\nUse manual entry instead.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Text(
                            'Point camera at a barcode or QR code',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.white, shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ]),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
