import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/utils.dart';
import '../../../models/sale_model.dart';
import '../scan/scan_page.dart';

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key, required this.sale});
  final SaleModel sale;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final timeStr = DateFormat('hh:mm a').format(sale.timestamp);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 60, 18, 16),
          child: Column(
            children: [
              // Success icon
              Center(
                child: SizedBox(
                  width: 72 + 16,
                  height: 72 + 16,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _spinCtrl,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.33),
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withOpacity(0.13),
                        ),
                        child: const Icon(Icons.check, size: 36, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Sale complete',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text('${sale.id} · $timeStr',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 22),

              // Receipt card
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Header
                        const Column(
                          children: [
                            Text('EASY POS', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 13, color: AppColors.text)),
                            SizedBox(height: 2),
                            Text('Galle Road · Colombo 04',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _DashedDivider(),
                        ),

                        // Items
                        if (sale.items != null)
                          ...sale.items!.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          text: item.product.name,
                                          style: const TextStyle(fontSize: 12.5, color: AppColors.text),
                                          children: [
                                            TextSpan(
                                              text: ' ×${item.qty}',
                                              style: const TextStyle(color: AppColors.textDim),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Text(fmtLKR(item.lineTotal),
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text)),
                                  ],
                                ),
                              )),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _DashedDivider(),
                        ),

                        // Totals
                        _ReceiptRow(label: 'Subtotal', value: 'LKR ${fmtLKR(sale.subtotal)}'),
                        const SizedBox(height: 4),
                        _ReceiptRow(label: 'Service 5%', value: 'LKR ${fmtLKR(sale.tax)}'),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                            Text('LKR ${fmtLKR(sale.total)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('Served by ${sale.cashier}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Row(children: [
                Expanded(child: AppButton(label: 'Print', kind: BtnKind.surface, onPressed: () {})),
                const SizedBox(width: 10),
                Expanded(child: AppButton(label: 'Share', kind: BtnKind.surface, onPressed: () {})),
              ]),
              const SizedBox(height: 10),
              AppButton(
                label: 'New sale',
                expand: true,
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanPage()),
                  (route) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      );
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashedPainter(),
      );
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.border..strokeWidth = 1;
    const dashWidth = 5.0, dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
