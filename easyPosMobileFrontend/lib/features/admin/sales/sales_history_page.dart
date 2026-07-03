import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/utils.dart';
import '../../../models/sale_model.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});
  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  int _periodIdx = 0; // 0=Today, 1=Week, 2=Month, 3=All

  List<SaleModel> _filter(List<SaleModel> all) {
    final now = DateTime.now();
    switch (_periodIdx) {
      case 0:
        return all.where((s) => _sameDay(s.timestamp, now)).toList();
      case 1:
        final week = now.subtract(const Duration(days: 7));
        return all.where((s) => s.timestamp.isAfter(week)).toList();
      case 2:
        final month = DateTime(now.year, now.month - 1, now.day);
        return all.where((s) => s.timestamp.isAfter(month)).toList();
      default:
        return all;
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Group sales by day
  Map<String, List<SaleModel>> _grouped(List<SaleModel> sales) {
    final map = <String, List<SaleModel>>{};
    for (final s in sales) {
      final key = dayLabel(s.timestamp);
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final filtered = _filter(state.sales);
    final total    = filtered.fold(0.0, (s, x) => s + x.total);
    final grouped  = _grouped(filtered);
    final periods  = ['Today', 'Week', 'Month', 'All'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Sales history',
              subtitle: '${filtered.length} sales · LKR ${fmtLKR(total)}',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  // Period filter chips
                  Row(
                    children: periods.asMap().entries.map((e) {
                      final i = e.key;
                      final label = e.value;
                      final active = i == _periodIdx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _periodIdx = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active ? AppColors.accent : AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: active ? null : Border.all(color: AppColors.border),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: active ? AppColors.accentInk : AppColors.textMuted,
                                )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  if (filtered.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: Text('No sales in this period',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ),
                    )
                  else
                    ...grouped.entries.map((entry) {
                      final dayTotal = entry.value.fold(0.0, (s, x) => s + x.total);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key.toUpperCase(),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
                                Text('LKR ${fmtLKR(dayTotal)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: entry.value.asMap().entries.map((e) {
                                final i = e.key;
                                final s = e.value;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: i > 0 ? const Border(top: BorderSide(color: AppColors.border)) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.textMuted),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(s.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                                          const SizedBox(height: 2),
                                          Text('${s.itemCount} items · ${timeAgo(s.timestamp)} · ${s.cashier}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        ]),
                                      ),
                                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                                        const Text('LKR ', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                        Text(fmtLKR(s.total),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                                      ]),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
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
