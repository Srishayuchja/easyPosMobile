import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/action_bar.dart';
import '../../../core/utils.dart';
import '../../../models/product_model.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key, this.prefillBarcode = ''});
  final String prefillBarcode;
  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameCtrl    = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _unitCtrl    = TextEditingController();
  final _buyCtrl     = TextEditingController();
  final _sellCtrl    = TextEditingController();
  final _stockCtrl   = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _barcodeCtrl.text = widget.prefillBarcode;
    _buyCtrl.addListener(_update);
    _sellCtrl.addListener(_update);
  }

  void _update() => setState(() {});

  @override
  void dispose() {
    for (final c in [_nameCtrl, _barcodeCtrl, _unitCtrl, _buyCtrl, _sellCtrl, _stockCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.isNotEmpty &&
      _barcodeCtrl.text.isNotEmpty &&
      _unitCtrl.text.isNotEmpty &&
      _buyCtrl.text.isNotEmpty &&
      _sellCtrl.text.isNotEmpty;

  int? get _margin {
    final b = double.tryParse(_buyCtrl.text);
    final s = double.tryParse(_sellCtrl.text);
    if (b == null || s == null || s <= 0) return null;
    return (((s - b) / s) * 100).round();
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final product = ProductModel(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim(),
      unit: _unitCtrl.text.trim(),
      buy: double.parse(_buyCtrl.text),
      sell: double.parse(_sellCtrl.text),
      stock: int.tryParse(_stockCtrl.text) ?? 0,
    );
    await state.addProduct(product);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product saved'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = _margin;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Add product', subtitle: 'Create a new SKU', onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  // Image placeholder
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image_outlined, size: 22, color: AppColors.textMuted),
                        SizedBox(height: 6),
                        Text('Add product image (optional)',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  AppTextField(label: 'PRODUCT NAME', controller: _nameCtrl,
                      placeholder: 'e.g. Anchor Full Cream Milk', onChanged: (_) => setState(() {})),
                  const SizedBox(height: 12),

                  // Barcode field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BARCODE',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.2)),
                      const SizedBox(height: 6),
                      AppTextField(
                        label: '',
                        controller: _barcodeCtrl,
                        placeholder: '13-digit EAN',
                        numeric: true,
                        onChanged: (_) => setState(() {}),
                        trailing: GestureDetector(
                          onTap: () {
                            // Generate random barcode for demo
                            final code = (1000000000000 + DateTime.now().millisecondsSinceEpoch % 9000000000000).toString();
                            _barcodeCtrl.text = code.substring(0, 13);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.qr_code_scanner, size: 14, color: AppColors.text),
                              SizedBox(width: 4),
                              Text('Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  AppTextField(label: 'UNIT / PACK SIZE', controller: _unitCtrl,
                      placeholder: 'e.g. 1L, 500g, 100 bags', onChanged: (_) => setState(() {})),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: AppTextField(label: 'BUYING PRICE', controller: _buyCtrl, prefix: 'LKR', numeric: true, placeholder: '0')),
                      const SizedBox(width: 10),
                      Expanded(child: AppTextField(label: 'SELLING PRICE', controller: _sellCtrl, prefix: 'LKR', numeric: true, placeholder: '0')),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (m != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.bar_chart_outlined, size: 14, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          'Margin: $m%  ·  Profit LKR ${fmtLKR(double.parse(_sellCtrl.text) - double.parse(_buyCtrl.text))} per unit',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],

                  AppTextField(label: 'OPENING STOCK', controller: _stockCtrl, numeric: true, suffix: 'units'),
                ],
              ),
            ),

            ActionBar(children: [
              AppButton(label: 'Cancel', kind: BtnKind.surface, onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 10),
              Expanded(
                child: _saving
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                    : AppButton(
                        label: 'Save product',
                        onPressed: _canSave ? _save : null,
                        disabled: !_canSave,
                        icon: const Icon(Icons.check, size: 18, color: AppColors.accentInk),
                        expand: true,
                      ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
