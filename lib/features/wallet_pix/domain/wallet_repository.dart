import 'wallet_models.dart';

class WalletSummaryData {
  final double availableBalance;
  final double pendingBalance;
  final double weekEarnings;
  final double totalAccumulated;
  final double periodEarnings;

  const WalletSummaryData({
    required this.availableBalance,
    required this.pendingBalance,
    required this.weekEarnings,
    required this.totalAccumulated,
    required this.periodEarnings,
  });
}

abstract class WalletRepository {
  Future<WalletSummaryData> getSummary(WalletPeriod period);

  Future<List<WalletTransaction>> getActivities({int limit = 20});

  Future<WalletTransaction> createPixTransfer({
    required String cpf,
    required double amount,
  });

  Future<WalletTransaction> getTransfer(String transferId);
}
