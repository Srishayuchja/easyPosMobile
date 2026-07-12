import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/prod_avatar.dart';
import '../../../models/product_model.dart';
import '../cart/cart_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  bool _manualMode = false;
  final _codeCtrl = TextEditingController();
  String _toast = '';
  late final AnimationController _scanLineCtrl;
  late final MobileScannerController _scannerCtrl;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scannerCtrl = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
    _codeCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _scanLineCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleManualMode() async {
    setState(() => _manualMode = !_manualMode);
    try {
      if (_manualMode) {
        await _scannerCtrl.stop();
      } else {
        await _scannerCtrl.start();
      }
    } catch (_) {
      // Camera may already be in the desired state; safe to ignore.
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;
    final product = context.read<AppState>().findByBarcode(code);
    if (product != null) {
      context.read<AppState>().addToCart(product);
      _showToast('+1 ${product.name}');
    } else {
      _showToast('No product for "$code"');
    }
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _toast = '');
    });
  }

  void _selectManual(ProductModel p) {
    context.read<AppState>().addToCart(p);
    _showToast('+1 ${p.name}');
    _codeCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cartCount = state.cartCount;
    final cartTotal = state.cartTotal;
    final query = _codeCtrl.text.trim();
    final manualResults = query.isEmpty ? <ProductModel>[] : state.searchProducts(query).take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'New Sale',
              subtitle: 'Scan or enter a barcode',
              onBack: Navigator.canPop(context) ? () => Navigator.pop(context) : null,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  // Scanner card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: !_manualMode ? AppColors.success : AppColors.textDim,
                                  boxShadow: !_manualMode
                                      ? [BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_manualMode ? 'Manual entry' : 'Scanning…',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                            ]),
                            GestureDetector(
                              onTap: _toggleManualMode,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(children: [
                                  Icon(_manualMode ? Icons.qr_code_2 : Icons.dialpad_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 5),
                                  Text(_manualMode ? 'Use camera' : 'Enter code',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                                ]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Viewport
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: RadialGradient(
                                colors: [AppColors.surface, AppColors.background],
                                center: const Alignment(0, -0.2),
                              ),
                              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Offstage(
                                    offstage: _manualMode,
                                    child: _ScanViewport(
                                      anim: _scanLineCtrl,
                                      controller: _scannerCtrl,
                                      onDetect: _onBarcodeDetected,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Offstage(
                                    offstage: !_manualMode,
                                    child: _ManualEntry(ctrl: _codeCtrl, results: manualResults, onSelect: _selectManual),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Toast
            if (_toast.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(_toast, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                ]),
              ),

            // Cart pill
            if (cartCount > 0)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        height: 28,
                        constraints: const BoxConstraints(minWidth: 28),
                        decoration: BoxDecoration(
                          color: AppColors.accentInk,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text('$cartCount',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Review cart',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accentInk)),
                      ),
                      Text('LKR ${fmtLKR(cartTotal)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accentInk)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: AppColors.accentInk, size: 20),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScanViewport extends StatelessWidget {
  const _ScanViewport({required this.anim, required this.controller, required this.onDetect});
  final AnimationController anim;
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        // Live camera feed
        MobileScanner(
          controller: controller,
          onDetect: onDetect,
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
        // Corner reticle
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(painter: _ReticlePainter()),
        ),
        // Scan line
        AnimatedBuilder(
          animation: anim,
          builder: (_, __) {
            final t = anim.value;
            // Animate top→bottom→top
            final frac = t < 0.5 ? t * 2 : (1 - t) * 2;
            return Positioned(
              top: 40 + frac * (200),
              left: 40,
              right: 40,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    AppColors.accent,
                    Colors.transparent,
                  ]),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.6), blurRadius: 8)],
                ),
              ),
            );
          },
        ),
        const Positioned(
          bottom: 14,
          child: Text('Point at barcode or QR',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ),
      ],
    );
  }
}

class _ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const inset = 60.0;
    const corner = 26.0;
    final r = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);

    // Top-left
    canvas.drawLine(Offset(r.left, r.top + corner), Offset(r.left, r.top), paint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + corner, r.top), paint);
    // Top-right
    canvas.drawLine(Offset(r.right - corner, r.top), Offset(r.right, r.top), paint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + corner), paint);
    // Bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - corner), Offset(r.left, r.bottom), paint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + corner, r.bottom), paint);
    // Bottom-right
    canvas.drawLine(Offset(r.right - corner, r.bottom), Offset(r.right, r.bottom), paint);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - corner), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ManualEntry extends StatelessWidget {
  const _ManualEntry({required this.ctrl, required this.results, required this.onSelect});
  final TextEditingController ctrl;
  final List<ProductModel> results;
  final ValueChanged<ProductModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'BARCODE OR NAME',
            controller: ctrl,
            placeholder: 'e.g. 4792024031019',
            autofocus: true,
          ),
          const SizedBox(height: 10),
          if (ctrl.text.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Start typing to search products',
                  style: TextStyle(fontSize: 12, color: AppColors.textDim)),
            )
          else if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No match found',
                  style: TextStyle(fontSize: 12, color: AppColors.textDim)),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: results.length,
                itemBuilder: (_, i) {
                  final p = results[i];
                  return GestureDetector(
                    onTap: () => onSelect(p),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          ProdAvatar(name: p.name, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                                Text('${p.unit} · ${p.barcode}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.add_circle_outline, size: 18, color: AppColors.accent),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
