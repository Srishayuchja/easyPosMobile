import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/utils.dart';
import '../../auth/login_page.dart';
import '../products/add_product_page.dart';
import '../purchase/purchase_page.dart';
import '../inventory/inventory_page.dart';
import '../sales/sales_history_page.dart';
import '../review/review_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final todayTotal = state.todayTotal;
    final todaySales = state.todaySales;
    final lowStock = state.lowStockCount;
    final products = state.products;
    final totalItems = todaySales.fold(0, (s, x) => s + x.itemCount);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Hi, ${state.currentUser?.name ?? "Admin"}',
              subtitle: (state.currentUser?.branch.isNotEmpty ?? false)
                  ? 'Admin · ${state.currentUser!.branch}'
                  : 'Admin',
              trailing: GestureDetector(
                onTap: () {
                  state.logout();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginPage()));
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.logout_outlined,
                      size: 20, color: AppColors.textMuted),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  // Hero stat
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent,
                          AppColors.accent.withOpacity(0.6)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentInk.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("TODAY'S SALES",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accentInk,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text('LKR ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.accentInk,
                                        fontWeight: FontWeight.w600)),
                                Text(fmtLKR(todayTotal),
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.8,
                                        color: AppColors.accentInk)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                                '${todaySales.length} sales  ·  $totalItems items  ·  $lowStock low stock',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppColors.accentInk.withOpacity(0.85))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Stats row
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StatCard(
                            label: 'Products',
                            value: '${products.length}',
                            sub: 'in catalog'),
                        const SizedBox(width: 10),
                        StatCard(
                            label: 'Low stock',
                            value: '$lowStock',
                            sub: 'below alert quantity',
                            accentColor:
                                lowStock > 0 ? AppColors.warning : null),
                        const SizedBox(width: 10),
                        StatCard(
                          label: 'Review',
                          value: '${state.pendingApprovals.length}',
                          sub: 'pending requests',
                          accentColor: state.pendingApprovals.isNotEmpty
                              ? AppColors.accent
                              : null,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ReviewPage())),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  const Text('QUICK ACTIONS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 10),

                  // Actions grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      ActionCard(
                        label: 'Add product',
                        sub: 'New SKU',
                        icon: Icons.add_circle_outline,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddProductPage())),
                      ),
                      ActionCard(
                        label: 'Purchase',
                        sub: 'Add stock',
                        icon: Icons.local_shipping_outlined,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PurchasePage())),
                      ),
                      ActionCard(
                        label: 'Inventory',
                        sub: '${products.length} items',
                        icon: Icons.inventory_2_outlined,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const InventoryPage())),
                      ),
                      ActionCard(
                        label: 'Sales',
                        sub: '${todaySales.length} today',
                        icon: Icons.receipt_long_outlined,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SalesHistoryPage())),
                      ),
                    ],
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
