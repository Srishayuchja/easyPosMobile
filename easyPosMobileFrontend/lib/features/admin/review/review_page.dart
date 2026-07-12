import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/utils.dart';
import '../../../models/approval_request_model.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool _busy = false;
  int? _busyId;
  // Buying price entered by the admin for each pending request: required for
  // 'new_product' (cashiers don't set one), and prefilled with the product's current
  // price for 'stock_add' so the admin can keep it or override it if the cost changed.
  final Map<int, TextEditingController> _buyCtrls = {};

  @override
  void initState() {
    super.initState();
    context.read<AppState>().fetchApprovals();
  }

  @override
  void dispose() {
    for (final c in _buyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _buyCtrlFor(int id, {double? initial}) => _buyCtrls.putIfAbsent(id, () {
        final c = TextEditingController();
        if (initial != null && initial > 0) c.text = initial.toStringAsFixed(2);
        return c;
      });

  // True when the buying price entered for [r] would block approval.
  bool _buyInvalid(ApprovalRequestModel r) {
    if (r.type == 'new_product') {
      return (double.tryParse(_buyCtrlFor(r.id).text) ?? 0) <= 0;
    }
    if (r.type == 'stock_add') {
      final text = _buyCtrlFor(r.id, initial: r.currentBuy).text.trim();
      if (text.isEmpty) return false; // keep the product's current buying price
      return (double.tryParse(text) ?? 0) <= 0;
    }
    return false;
  }

  Future<void> _approve(ApprovalRequestModel r) async {
    double? buy;
    if (r.type == 'new_product') {
      buy = double.tryParse(_buyCtrlFor(r.id).text);
      if (buy == null || buy <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a buying price before approving'), backgroundColor: AppColors.danger),
        );
        return;
      }
    } else if (r.type == 'stock_add') {
      final text = _buyCtrlFor(r.id, initial: r.currentBuy).text.trim();
      if (text.isNotEmpty) {
        buy = double.tryParse(text);
        if (buy == null || buy <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid buying price'), backgroundColor: AppColors.danger),
          );
          return;
        }
      }
    }

    setState(() { _busy = true; _busyId = r.id; });
    try {
      await context.read<AppState>().approveRequest(r.id, buy: buy);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() { _busy = false; _busyId = null; });
  }

  Future<void> _reject(ApprovalRequestModel r) async {
    setState(() { _busy = true; _busyId = r.id; });
    try {
      await context.read<AppState>().rejectRequest(r.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() { _busy = false; _busyId = null; });
  }

  Future<void> _approveAll() async {
    setState(() => _busy = true);
    try {
      await context.read<AppState>().approveAllRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve all: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<AppState>().pendingApprovals;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Review requests',
              subtitle: '${requests.length} pending',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: requests.isEmpty
                  ? const Center(
                      child: Text('No pending requests',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      children: [
                        AppButton(
                          label: 'Approve all (${requests.length})',
                          onPressed: _busy ? null : _approveAll,
                          disabled: _busy,
                          expand: true,
                          icon: const Icon(Icons.done_all, size: 18, color: AppColors.accentInk),
                        ),
                        const SizedBox(height: 14),
                        ...requests.map((r) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 34, height: 34,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          r.type == 'new_product' ? Icons.add_circle_outline : Icons.local_shipping_outlined,
                                          size: 18, color: AppColors.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(r.summary,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Requested by ${r.requestedByName} · ${timeAgo(r.requestedAt)}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  if (r.type == 'new_product') ...[
                                    const SizedBox(height: 12),
                                    AppTextField(
                                      label: 'BUYING PRICE',
                                      controller: _buyCtrlFor(r.id),
                                      prefix: 'LKR',
                                      numeric: true,
                                      placeholder: 'Required to approve',
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ] else if (r.type == 'stock_add') ...[
                                    const SizedBox(height: 12),
                                    AppTextField(
                                      label: 'BUYING PRICE',
                                      controller: _buyCtrlFor(r.id, initial: r.currentBuy),
                                      prefix: 'LKR',
                                      numeric: true,
                                      placeholder: 'Same as current price',
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton(
                                          label: 'Reject',
                                          kind: BtnKind.danger,
                                          size: BtnSize.sm,
                                          onPressed: (_busy && _busyId == r.id) ? null : () => _reject(r),
                                          disabled: _busy && _busyId == r.id,
                                          expand: true,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: AppButton(
                                          label: 'Approve',
                                          size: BtnSize.sm,
                                          onPressed: (_busy && _busyId == r.id) || _buyInvalid(r)
                                              ? null
                                              : () => _approve(r),
                                          disabled: (_busy && _busyId == r.id) || _buyInvalid(r),
                                          expand: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
}
