import 'dart:math';

import 'package:flutter/material.dart';

import '../models/payment.dart';
import 'status_badge.dart';

class PaymentCard extends StatelessWidget {
  final Payment payment;

  const PaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = payment;
    final total = p.totalAmount / pow(10, p.assetScale);
    final hasSplit = p.artisanShare > 0;
    final artisanAmt = p.artisanShare / pow(10, p.assetScale);
    final galleryAmt = p.galleryShare / pow(10, p.assetScale);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.artisanName,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.productName,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge(status: p.status),
              ],
            ),
          ),

          Divider(height: 1, color: cs.outlineVariant),

          // Amount + timestamps
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.assetCode} ${total.toStringAsFixed(p.assetScale)}',
                      style: tt.titleMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmtDateTime(p.createdAt),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (p.completedAt != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 11,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Liquidado ${_fmtTime(p.completedAt!)}',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                if (hasSplit) ...[
                  const SizedBox(height: 10),
                  _SplitRow(
                    color: cs.primary,
                    label: p.artisanName.isNotEmpty
                        ? p.artisanName
                        : 'Artesano',
                    amount: artisanAmt,
                    assetCode: p.assetCode,
                    assetScale: p.assetScale,
                    total: total,
                    tt: tt,
                    cs: cs,
                  ),
                  const SizedBox(height: 4),
                  _SplitRow(
                    color: cs.onSurfaceVariant,
                    label: p.galleryName.isNotEmpty ? p.galleryName : 'Galería',
                    amount: galleryAmt,
                    assetCode: p.assetCode,
                    assetScale: p.assetScale,
                    total: total,
                    tt: tt,
                    cs: cs,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDateTime(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${m[dt.month - 1]} ${dt.day} · $h:$min';
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }
}

class _SplitRow extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;
  final String assetCode;
  final int assetScale;
  final double total;
  final TextTheme tt;
  final ColorScheme cs;

  const _SplitRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.assetCode,
    required this.assetScale,
    required this.total,
    required this.tt,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$assetCode ${amount.toStringAsFixed(assetScale)}',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($pct%)',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
