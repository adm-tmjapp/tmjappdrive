import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wallet_api.dart';
import '../data/wallet_repository_impl.dart';
import '../domain/wallet_models.dart';
import '../domain/wallet_repository.dart';

class WalletController extends StateNotifier<WalletState> {
  WalletController(this._repository) : super(WalletState.initial()) {
    load();
  }

  final WalletRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait<dynamic>([
        _repository.getSummary(state.period),
        _repository.getActivities(limit: 20),
      ]);

      final summary = results[0] as WalletSummaryData;
      final activities = results[1] as List<WalletTransaction>;

      state = state.copyWith(
        isLoading: false,
        availableBalance: summary.availableBalance,
        pendingBalance: summary.pendingBalance,
        weekEarnings: summary.weekEarnings,
        totalAccumulated: summary.totalAccumulated,
        periodEarnings: summary.periodEarnings,
        history: activities,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _errorMessage(e, 'Falha ao carregar carteira.'),
      );
    }
  }

  Future<void> setPeriod(WalletPeriod period) async {
    state = state.copyWith(period: period, clearError: true);
    await load();
  }

  void setCpfDraft(String value) {
    state = state.copyWith(cpfDraft: value, clearError: true);
  }

  void setAmountDraft(String value) {
    state = state.copyWith(amountDraft: value, clearError: true);
  }

  Future<bool> submitTransfer() async {
    final rawCpf = state.cpfDraft.replaceAll(RegExp(r'\D'), '');
    final amount = double.tryParse(state.amountDraft.replaceAll(',', '.'));

    if (rawCpf.length != 11) {
      state = state.copyWith(error: 'CPF invalido. Informe 11 digitos.');
      return false;
    }

    if (amount == null || amount <= 0) {
      state = state.copyWith(error: 'Valor invalido.');
      return false;
    }

    if (amount > state.availableBalance) {
      state = state.copyWith(error: 'Saldo insuficiente para transferencia.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final tx = await _repository.createPixTransfer(
        cpf: rawCpf,
        amount: amount,
      );

      final summary = await _repository.getSummary(state.period);
      final activities = await _repository.getActivities(limit: 20);

      state = state.copyWith(
        isSubmitting: false,
        availableBalance: summary.availableBalance,
        pendingBalance: summary.pendingBalance,
        weekEarnings: summary.weekEarnings,
        totalAccumulated: summary.totalAccumulated,
        periodEarnings: summary.periodEarnings,
        cpfDraft: '',
        amountDraft: '',
        lastTransfer: tx,
        history: activities,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _errorMessage(e, 'Nao foi possivel concluir a transferencia.'),
      );
      return false;
    }
  }

  Future<WalletTransaction?> fetchTransferDetails(String transferId) async {
    try {
      return await _repository.getTransfer(transferId);
    } catch (_) {
      return null;
    }
  }

  String _errorMessage(Object error, String fallback) {
    final message = error.toString().trim();
    if (message.isEmpty) return fallback;
    return message;
  }
}

final walletApiProvider = Provider<WalletApi>((ref) {
  return WalletApi();
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final api = ref.watch(walletApiProvider);
  return WalletRepositoryImpl(api: api);
});

final walletControllerProvider =
    StateNotifierProvider<WalletController, WalletState>((ref) {
      final repository = ref.watch(walletRepositoryProvider);
      return WalletController(repository);
    });
