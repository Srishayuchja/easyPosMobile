import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/prod_avatar.dart';
import '../../../core/widgets/qty_stepper.dart';
import '../../../core/widgets/action_bar.dart';
import '../../../core/utils.dart';
import '../receipt/receipt_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int _paymentIdx = 0; // 0 = Cash, 1 = Card, 2 = QR Pay
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final state = context.read<AppState>();
    final sale = await state.submitSale();
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReceiptPage(sale: sale)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cart = state.cart;

    final subtotal = cart.fold(0.0, (s, i) => s + i.lineTotal);
    final tax = subtotal * 0.05;
    final total = subtotal + tax;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Review sale',
              subtitle: '${cart.length} ${cart.length == 1 ? "item" : "items"}',
              onBack: () => Navigator.pop(context),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  // Cart items
                  ...cart.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProdAvatar(name: item.product.name),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text, height: 1.25)),
                                    const SizedBox(height: 2),
                                    Text('${item.product.unit} · ${item.product.barcode}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => state.removeFromCart(item.product.id),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close, size: 16, color: AppColors.textDim),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Price input
                              Expanded(
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('LKR', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: item.price.toStringAsFixed(0),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                          onChanged: (v) {
                                            final price = double.tryParse(v) ?? item.price;
                                            state.changePrice(item.product.id, price);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('×', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                              ),
                              QtyStepper(
                                value: item.qty,
                                onChanged: (v) => state.changeQty(item.product.id, v),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  fmtLKR(item.lineTotal),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),

                  // Totals
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _TotalRow(label: 'Subtotal', value: fmtLKR(subtotal)),
                        _TotalRow(label: 'Service (5%)', value: fmtLKR(tax)),
                        const Divider(color: AppColors.border, height: 17),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text('LKR ', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                Text(fmtLKR(total),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.text)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment method
                  const Text('PAYMENT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PayBtn(label: 'Cash',   icon: Icons.account_balance_wallet_outlined, selected: _paymentIdx == 0, onTap: () => setState(() => _paymentIdx = 0)),
                      const SizedBox(width: 8),
                      _PayBtn(label: 'Card',   icon: Icons.credit_card_outlined,            selected: _paymentIdx == 1, onTap: () => setState(() => _paymentIdx = 1)),
                      const SizedBox(width: 8),
                      _PayBtn(label: 'QR Pay', icon: Icons.qr_code_2,                       selected: _paymentIdx == 2, onTap: () => setState(() => _paymentIdx = 2)),
                    ],
                  ),
                ],
              ),
            ),

            ActionBar(
              children: [
                AppButton(label: 'Back', kind: BtnKind.surface, onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 10),
                Expanded(
                  child: _submitting
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : AppButton(
                          label: 'Submit · LKR ${fmtLKR(total)}',
                          onPressed: cart.isEmpty ? null : _submit,
                          disabled: cart.isEmpty,
                          icon: const Icon(Icons.check, size: 18, color: AppColors.accentInk),
                          expand: true,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            Text('LKR $value', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      );
}

class _PayBtn extends StatelessWidget {
  const _PayBtn({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent.withOpacity(0.13) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.accent : AppColors.border),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: selected ? AppColors.accent : AppColors.textMuted),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.text : AppColors.textMuted,
                    )),
              ],
            ),
          ),
        ),
      );
}
