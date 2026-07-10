import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/action_bar.dart';
import '../../../core/widgets/prod_avatar.dart';
import '../../../core/widgets/barcode_scan_page.dart';
import '../../../core/utils.dart';
import '../../../models/product_model.dart';
import '../products/add_product_page.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});
  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final _searchCtrl   = TextEditingController();
  final _unitCostCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _qtyCtrl      = TextEditingController(text: '1');
  ProductModel? _selected;
  int _qty = 1;
  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _unitCostCtrl.dispose();
    _supplierCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _setQty(int value) {
    final v = value < 1 ? 1 : value;
    setState(() {
      _qty = v;
      _qtyCtrl.text = '$v';
    });
  }

  List<ProductModel> _filtered(List<ProductModel> all) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return all.take(6).toList();
    return all.where((p) => p.name.toLowerCase().contains(q) || p.barcode.contains(_searchCtrl.text.trim())).take(8).toList();
  }

  void _select(ProductModel p) {
    setState(() {
      _selected = p;
      _unitCostCtrl.text = p.buy.toStringAsFixed(0);
      _qty = 1;
      _qtyCtrl.text = '1';
    });
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScanPage(title: 'Scan product barcode')),
    );
    if (code == null || code.isEmpty || !mounted) return;
    final product = context.read<AppState>().findByBarcode(code);
    if (product != null) {
      _select(product);
    } else {
      setState(() {
        _searchCtrl.text = code;
      });
    }
  }

  Future<void> _addStock() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    final applied = await context.read<AppState>().addStock(_selected!.id, _qty);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(applied ? 'Added $_qty units to ${_selected!.name}' : 'Submitted for admin approval'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final products = state.products;
    final filtered = _filtered(products);

    if (_selected == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(title: 'Purchase', subtitle: 'Add stock for a product', onBack: () => Navigator.pop(context)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    // Search bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              autofocus: true,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(color: AppColors.text, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: 'Scan barcode or type name',
                                hintStyle: TextStyle(color: AppColors.textDim),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _scanBarcode,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.qr_code_scanner, size: 14, color: AppColors.accentInk),
                                SizedBox(width: 4),
                                Text('Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentInk)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      _searchCtrl.text.isNotEmpty ? 'MATCHES (${filtered.length})' : 'RECENT',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 8),

                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Text('No product matches "${_searchCtrl.text}"',
                                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => AddProductPage(prefillBarcode: _searchCtrl.text))),
                              child: const Text('+ Create as new product',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filtered.map((p) => GestureDetector(
                            onTap: () => _select(p),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  ProdAvatar(name: p.name),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                                      const SizedBox(height: 2),
                                      Text('${p.unit} · stock ${p.stock}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    ]),
                                  ),
                                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textDim),
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Product selected → show qty/cost form
    final p = _selected!;
    final totalCost = (double.tryParse(_unitCostCtrl.text) ?? p.buy) * _qty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Add to stock', onBack: () => setState(() => _selected = null)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  // Product card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(children: [
                          ProdAvatar(name: p.name, size: 48),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                            const SizedBox(height: 2),
                            Text('${p.unit} · ${p.barcode}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ])),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.only(top: 12),
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('CURRENT STOCK',
                                    style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                                Text('${p.stock} ${p.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                              ]),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                const Text('AFTER',
                                    style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                                Text('${p.stock + _qty} ${p.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Qty stepper
                  Text('QUANTITY TO ADD (${p.unit.toUpperCase()})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.2)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _qty > 1 ? () => _setQty(_qty - 1) : null,
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.remove, size: 20, color: _qty > 1 ? AppColors.text : AppColors.textDim),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _qtyCtrl,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.text),
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final parsed = int.tryParse(v);
                              setState(() => _qty = (parsed == null || parsed < 1) ? 1 : parsed);
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _setQty(_qty + 1),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.add, size: 20, color: AppColors.accentInk),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [10, 24, 50, 100].map((n) => Expanded(
                      child: GestureDetector(
                        onTap: () => _setQty(n),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: Text('+$n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(child: AppTextField(label: 'UNIT COST', controller: _unitCostCtrl, prefix: 'LKR', numeric: true, onChanged: (_) => setState(() {}))),
                    const SizedBox(width: 10),
                    Expanded(child: AppTextField(label: 'SUPPLIER', controller: _supplierCtrl, placeholder: 'Optional')),
                  ]),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text('Purchase total', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                          const Text('LKR ', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          Text(fmtLKR(totalCost),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            ActionBar(children: [
              AppButton(label: 'Back', kind: BtnKind.surface, onPressed: () => setState(() => _selected = null)),
              const SizedBox(width: 10),
              Expanded(
                child: _saving
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                    : AppButton(
                        label: 'Add $_qty to stock',
                        onPressed: _addStock,
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
