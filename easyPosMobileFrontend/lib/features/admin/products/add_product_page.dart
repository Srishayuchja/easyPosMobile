import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/action_bar.dart';
import '../../../core/widgets/barcode_scan_page.dart';
import '../../../core/utils.dart';
import '../../../models/product_model.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key, this.prefillBarcode = ''});
  final String prefillBarcode;
  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _buyCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _marginCtrl = TextEditingController();
  final _marginFocus = FocusNode();
  final _stockCtrl = TextEditingController(text: '0');
  final _alertQtyCtrl = TextEditingController(text: '0');
  final _newBrandCtrl = TextEditingController();
  final _newUnitCtrl = TextEditingController();
  String _brand = '';
  String _unitType = '';
  bool _saving = false;
  bool _isCashier = false;

  @override
  void initState() {
    super.initState();
    _isCashier = context.read<AppState>().currentRole == 'cashier';
    _barcodeCtrl.text = widget.prefillBarcode;
    _buyCtrl.addListener(_recalcMargin);
    _sellCtrl.addListener(_recalcMargin);
  }

  void _recalcMargin() {
    if (_marginFocus.hasFocus) {
      setState(() {});
      return;
    }
    final b = double.tryParse(_buyCtrl.text);
    final s = double.tryParse(_sellCtrl.text);
    setState(() {
      _marginCtrl.text = (b == null || b <= 0 || s == null)
          ? ''
          : (((s - b) / b) * 100).toStringAsFixed(0);
    });
  }

  void _onMarginChanged(String v) {
    final pct = double.tryParse(v);
    final b = double.tryParse(_buyCtrl.text);
    if (pct == null || b == null || b <= 0) return;
    _sellCtrl.text = (b * (1 + pct / 100)).toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
          builder: (_) => const BarcodeScanPage(title: 'Scan product barcode')),
    );
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _barcodeCtrl.text = code);
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _barcodeCtrl,
      _buyCtrl,
      _sellCtrl,
      _marginCtrl,
      _stockCtrl,
      _alertQtyCtrl,
      _newBrandCtrl,
      _newUnitCtrl
    ]) {
      c.dispose();
    }
    _marginFocus.dispose();
    super.dispose();
  }

  Future<void> _pickBrand() async {
    final state = context.read<AppState>();
    _newBrandCtrl.clear();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SELECT BRAND',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 12),
                  if (state.brands.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No brands yet. Add one below.',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.brands.length,
                        itemBuilder: (_, i) {
                          final b = state.brands[i];
                          final selected = b == _brand;
                          return GestureDetector(
                            onTap: () => Navigator.pop(sheetCtx, b),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: selected
                                        ? AppColors.accent
                                        : AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(b,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text)),
                                  ),
                                  if (selected)
                                    const Icon(Icons.check,
                                        size: 16, color: AppColors.accent),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),
                  const Text('ADD NEW BRAND',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                            label: '',
                            controller: _newBrandCtrl,
                            placeholder: 'e.g. Nestle'),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          final name = _newBrandCtrl.text.trim();
                          if (name.isEmpty) return;
                          state.addBrand(name);
                          Navigator.pop(sheetCtx, name);
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('Add',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentInk)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _brand = picked);
    }
  }

  Future<void> _pickUnit() async {
    final state = context.read<AppState>();
    _newUnitCtrl.clear();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SELECT UNIT',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.units.length,
                      itemBuilder: (_, i) {
                        final u = state.units[i];
                        final selected = u == _unitType;
                        return GestureDetector(
                          onTap: () => Navigator.pop(sheetCtx, u),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(u,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text)),
                                ),
                                if (selected)
                                  const Icon(Icons.check,
                                      size: 16, color: AppColors.accent),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('ADD NEW UNIT',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                            label: '',
                            controller: _newUnitCtrl,
                            placeholder: 'e.g. dozen'),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          final name = _newUnitCtrl.text.trim();
                          if (name.isEmpty) return;
                          state.addUnit(name);
                          Navigator.pop(sheetCtx, name);
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('Add',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentInk)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _unitType = picked);
    }
  }

  bool get _canSave =>
      _nameCtrl.text.isNotEmpty &&
      _barcodeCtrl.text.isNotEmpty &&
      _unitType.isNotEmpty &&
      (_isCashier || _buyCtrl.text.isNotEmpty) &&
      _sellCtrl.text.isNotEmpty;

  int? get _margin {
    final b = double.tryParse(_buyCtrl.text);
    final s = double.tryParse(_sellCtrl.text);
    if (b == null || b <= 0 || s == null) return null;
    return (((s - b) / b) * 100).round();
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final product = ProductModel(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim(),
      unit: _unitType,
      buy: _isCashier ? 0 : double.parse(_buyCtrl.text),
      sell: double.parse(_sellCtrl.text),
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      brand: _brand,
      alertQty: int.tryParse(_alertQtyCtrl.text) ?? 0,
    );
    final applied = await state.addProduct(product);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(applied ? 'Product saved' : 'Submitted for admin approval'),
        backgroundColor: AppColors.success,
      ),
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
            AppHeader(
                title: 'Add Product',
                subtitle: 'Add a new product',
                onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  AppTextField(
                      label: 'PRODUCT NAME',
                      controller: _nameCtrl,
                      placeholder: 'Enter name',
                      onChanged: (_) => setState(() {})),
                  const SizedBox(height: 12),

                  // Brand field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BRAND(OPTIONAL)',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              letterSpacing: 0.2)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickBrand,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _brand.isEmpty ? 'Select brand' : _brand,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _brand.isEmpty
                                        ? AppColors.textDim
                                        : AppColors.text,
                                  ),
                                ),
                              ),
                              const Icon(Icons.expand_more,
                                  size: 18, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Barcode field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BARCODE',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              letterSpacing: 0.2)),
                      const SizedBox(height: 6),
                      AppTextField(
                        label: '',
                        controller: _barcodeCtrl,
                        placeholder: 'Enter or scan value',
                        numeric: true,
                        onChanged: (_) => setState(() {}),
                        trailing: GestureDetector(
                          onTap: _scanBarcode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner,
                                      size: 14, color: AppColors.text),
                                  SizedBox(width: 4),
                                  Text('Scan',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text)),
                                ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('UNIT',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              letterSpacing: 0.2)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickUnit,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _unitType.isEmpty ? 'Select unit' : _unitType,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _unitType.isEmpty
                                        ? AppColors.textDim
                                        : AppColors.text,
                                  ),
                                ),
                              ),
                              const Icon(Icons.expand_more,
                                  size: 18, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    label: 'ALERT QUANTITY (OPTIONAL)',
                    controller: _alertQtyCtrl,
                    numeric: true,
                    suffix: _unitType.isEmpty ? 'units' : _unitType,
                  ),
                  const SizedBox(height: 12),

                  if (_isCashier)
                    AppTextField(
                        label: 'SELLING PRICE',
                        controller: _sellCtrl,
                        prefix: 'LKR',
                        numeric: true,
                        placeholder: '0')
                  else
                    Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: AppTextField(
                                label: 'BUYING PRICE',
                                controller: _buyCtrl,
                                prefix: 'LKR',
                                numeric: true,
                                placeholder: '0')),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            label: 'MARGIN',
                            controller: _marginCtrl,
                            focusNode: _marginFocus,
                            suffix: '%',
                            numeric: true,
                            placeholder: '0',
                            onChanged: _onMarginChanged,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: AppTextField(
                                label: 'SELLING PRICE',
                                controller: _sellCtrl,
                                prefix: 'LKR',
                                numeric: true,
                                placeholder: '0')),
                      ],
                    ),
                  const SizedBox(height: 8),

                  if (m != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.bar_chart_outlined,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          'Margin: $m%  ·  Profit LKR ${fmtLKR(double.parse(_sellCtrl.text) - double.parse(_buyCtrl.text))} per unit',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],

                  AppTextField(
                    label: 'OPENING STOCK',
                    controller: _stockCtrl,
                    numeric: true,
                    suffix: _unitType.isEmpty ? 'units' : _unitType,
                  ),
                ],
              ),
            ),
            ActionBar(children: [
              AppButton(
                  label: 'Cancel',
                  kind: BtnKind.surface,
                  onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 10),
              Expanded(
                child: _saving
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent))
                    : AppButton(
                        label: 'Save product',
                        onPressed: _canSave ? _save : null,
                        disabled: !_canSave,
                        icon: const Icon(Icons.check,
                            size: 18, color: AppColors.accentInk),
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
