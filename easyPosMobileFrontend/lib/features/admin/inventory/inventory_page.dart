import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/prod_avatar.dart';
import '../../../core/widgets/barcode_scan_page.dart';
import '../../../core/utils.dart';
import '../products/add_product_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScanPage(title: 'Scan product barcode')),
    );
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _searchCtrl.text = code);
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final q        = _searchCtrl.text.toLowerCase();
    final products = q.isEmpty
        ? state.products
        : state.products.where((p) => p.name.toLowerCase().contains(q) || p.barcode.contains(q)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Inventory',
              subtitle: '${state.products.length} products',
              onBack: () => Navigator.pop(context),
              trailing: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 14, color: AppColors.accentInk),
                    SizedBox(width: 4),
                    Text('New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentInk)),
                  ]),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  // Search
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: AppColors.text, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Search products',
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
                  const SizedBox(height: 10),

                  if (products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Center(
                        child: Text('No matches for "${_searchCtrl.text}"',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ),
                    )
                  else
                    ...products.map((p) {
                      final low = p.stock < p.alertQty;
                      return Container(
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
                                Text('${p.unit}  ·  LKR ${fmtLKR(p.sell)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(
                                '${p.stock}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: low ? AppColors.warning : AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                low ? 'LOW' : 'IN STOCK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  color: low ? AppColors.warning : AppColors.textMuted,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
