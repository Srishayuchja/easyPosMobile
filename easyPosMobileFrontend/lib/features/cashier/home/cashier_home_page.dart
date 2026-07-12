import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/utils.dart';
import '../../auth/login_page.dart';
import '../scan/scan_page.dart';
import '../cart/cart_page.dart';
import '../../admin/products/add_product_page.dart';
import '../../admin/purchase/purchase_page.dart';
import '../../admin/inventory/inventory_page.dart';
import 'low_stock_page.dart';
import 'my_requests_page.dart';

class CashierHomePage extends StatelessWidget {
  const CashierHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cartCount = state.cartCount;
    final lowStock = state.lowStockCount;
    final myRequests = state.myRequests;
    final pendingCount = myRequests.where((r) => r.status == 'pending').length;
    final rejectedCount =
        myRequests.where((r) => r.status == 'rejected').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Hi, ${state.currentUser?.name ?? "Cashier"}',
              subtitle: (state.currentUser?.branch.isNotEmpty ?? false)
                  ? 'Cashier · ${state.currentUser!.branch}'
                  : 'Cashier',
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
                  if (cartCount > 0)
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CartPage())),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.accent.withOpacity(0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              height: 28,
                              constraints: const BoxConstraints(minWidth: 28),
                              decoration: BoxDecoration(
                                  color: AppColors.accentInk,
                                  borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text('$cartCount',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('Continue sale',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accentInk)),
                            ),
                            Text('LKR ${fmtLKR(state.cartTotal)}',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentInk)),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right,
                                color: AppColors.accentInk, size: 20),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LowStockPage())),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 14),
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
                              const Text('LOW STOCK',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.accentInk,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3)),
                              const SizedBox(height: 4),
                              Text('$lowStock',
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.8,
                                      color: AppColors.accentInk)),
                              const SizedBox(height: 14),
                              Text(
                                  lowStock == 1
                                      ? 'product below alert quantity'
                                      : 'products below alert quantity',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.accentInk
                                          .withOpacity(0.85))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Text('QUICK ACTIONS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      ActionCard(
                        label: 'New sale',
                        sub: 'Scan or enter code',
                        icon: Icons.qr_code_scanner,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScanPage())),
                      ),
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
                        label: 'Add stock',
                        sub: 'Restock a product',
                        icon: Icons.local_shipping_outlined,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PurchasePage())),
                      ),
                      ActionCard(
                        label: 'View products',
                        sub: 'Prices & stock',
                        icon: Icons.inventory_2_outlined,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const InventoryPage())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyRequestsPage())),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent.withOpacity(0.5),
                            AppColors.accent.withOpacity(0.3)
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
                                color: AppColors.accent.withOpacity(0.06),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MY REQUESTS',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3)),
                              const SizedBox(height: 4),
                              Text('${myRequests.length}',
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.8,
                                      color: AppColors.accent)),
                              const SizedBox(height: 14),
                              Text(
                                  '$pendingCount pending  ·  $rejectedCount rejected',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          AppColors.accent.withOpacity(0.85))),
                            ],
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
    );
  }
}
