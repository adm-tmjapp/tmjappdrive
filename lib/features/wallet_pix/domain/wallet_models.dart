import 'package:flutter/foundation.dart';

enum WalletPeriod { today, week, month }

enum TransferStatus { pending, completed, failed }

@immutable
class WalletTransaction {
  final String id;
  final double amount;
  final String? cpf;
  final DateTime createdAt;
  final TransferStatus status;
  final String? referenceId;
  final String type;
  final String? providerTxId;
  final String? receiptUrl;
  final String? failureReason;

  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
    required this.status,
    this.cpf,
    this.referenceId,
    this.providerTxId,
    this.receiptUrl,
    this.failureReason,
  });
}

@immutable
class WalletState {
  final WalletPeriod period;
  final bool isLoading;
  final double availableBalance;
  final double pendingBalance;
  final double weekEarnings;
  final double totalAccumulated;
  final double periodEarnings;
  final bool isSubmitting;
  final String cpfDraft;
  final String amountDraft;
  final String? error;
  final WalletTransaction? lastTransfer;
  final List<WalletTransaction> history;

  const WalletState({
    required this.period,
    required this.isLoading,
    required this.availableBalance,
    required this.pendingBalance,
    required this.weekEarnings,
    required this.totalAccumulated,
    required this.periodEarnings,
    required this.isSubmitting,
    required this.cpfDraft,
    required this.amountDraft,
    required this.history,
    this.error,
    this.lastTransfer,
  });

  factory WalletState.initial() {
    return const WalletState(
      period: WalletPeriod.today,
      isLoading: true,
      availableBalance: 0,
      pendingBalance: 0,
      weekEarnings: 0,
      totalAccumulated: 0,
      periodEarnings: 0,
      isSubmitting: false,
      cpfDraft: '',
      amountDraft: '',
      history: [],
    );
  }

  WalletState copyWith({
    WalletPeriod? period,
    bool? isLoading,
    double? availableBalance,
    double? pendingBalance,
    double? weekEarnings,
    double? totalAccumulated,
    double? periodEarnings,
    bool? isSubmitting,
    String? cpfDraft,
    String? amountDraft,
    String? error,
    bool clearError = false,
    WalletTransaction? lastTransfer,
    List<WalletTransaction>? history,
  }) {
    return WalletState(
      period: period ?? this.period,
      isLoading: isLoading ?? this.isLoading,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      weekEarnings: weekEarnings ?? this.weekEarnings,
      totalAccumulated: totalAccumulated ?? this.totalAccumulated,
      periodEarnings: periodEarnings ?? this.periodEarnings,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      cpfDraft: cpfDraft ?? this.cpfDraft,
      amountDraft: amountDraft ?? this.amountDraft,
      error: clearError ? null : (error ?? this.error),
      lastTransfer: lastTransfer ?? this.lastTransfer,
      history: history ?? this.history,
    );
  }
}
