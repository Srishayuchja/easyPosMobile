import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/prod_avatar.dart';

class LowStockPage extends StatelessWidget {
  const LowStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lowStockProducts = state.products
        .where((p) => p.stock < p.alertQty)
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Low stock',
              subtitle:
                  '${lowStockProducts.length} products below alert quantity',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: lowStockProducts.isEmpty
                  ? const Center(
                      child: Text('No low stock products',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: lowStockProducts.map((p) {
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
                                child: Text(p.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text)),
                              ),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${p.stock}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.warning)),
                                    const SizedBox(height: 2),
                                    const Text('LOW',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                            color: AppColors.warning)),
                                  ]),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
