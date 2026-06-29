import '../domain/wallet_models.dart';
import '../domain/wallet_repository.dart';
import 'wallet_api.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({required WalletApi api}) : _api = api;

  final WalletApi _api;

  @override
  Future<WalletSummaryData> getSummary(WalletPeriod period) async {
    final payload = await _api.getSummary(period);
    final balances = _mapFrom(payload['balances']);

    return WalletSummaryData(
      availableBalance: _asDouble(balances['available']),
      pendingBalance: _asDouble(balances['pending']),
      weekEarnings: _asDouble(payload['weekEarnings']),
      totalAccumulated: _asDouble(payload['totalAccumulated']),
      periodEarnings: _asDouble(payload['periodEarnings']),
    );
  }

  @override
  Future<List<WalletTransaction>> getActivities({int limit = 20}) async {
    final payload = await _api.getActivities(limit: limit);
    final items = payload['items'];
    final list = items is List ? items : const [];

    return list.map(_mapActivityToTransaction).toList(growable: false);
  }

  @override
  Future<WalletTransaction> createPixTransfer({
    required String cpf,
    required double amount,
  }) async {
    final idempotencyKey =
        'pix_${DateTime.now().microsecondsSinceEpoch}_${cpf.substring(cpf.length - 4)}';
    final createPayload = await _api.createPixTransfer(
      cpf: cpf,
      amount: amount,
      idempotencyKey: idempotencyKey,
    );

    final transferId = _asString(createPayload['transferId']);
    if (transferId.isEmpty) {
      throw const WalletApiException('Transferencia criada sem identificador.');
    }

    return getTransfer(transferId);
  }

  @override
  Future<WalletTransaction> getTransfer(String transferId) async {
    final payload = await _api.getTransfer(transferId);
    final transfer = _mapFrom(payload['transfer']);
    return _mapTransferToTransaction(transfer);
  }

  WalletTransaction _mapActivityToTransaction(dynamic item) {
    final map = _mapFrom(item);
    final type = _asString(map['type']);
    final referenceId = _asString(map['referenceId']);
    final amount = _asDouble(map['amount']).abs();

    return WalletTransaction(
      id: _asString(map['id']),
      referenceId: referenceId.isEmpty ? null : referenceId,
      type: type.isEmpty ? 'ADJUSTMENT' : type,
      amount: amount,
      cpf: null,
      createdAt: _asDateTime(map['createdAt']),
      status:
          type == 'PIX_TRANSFER_DEBIT'
              ? TransferStatus.completed
              : TransferStatus.pending,
    );
  }

  WalletTransaction _mapTransferToTransaction(Map<String, dynamic> transfer) {
    final statusRaw = _asString(transfer['status']).toUpperCase();
    final status =
        statusRaw == 'FAILED'
            ? TransferStatus.failed
            : (statusRaw == 'PENDING'
                ? TransferStatus.pending
                : TransferStatus.completed);

    final referenceId = _asString(transfer['id']);
    return WalletTransaction(
      id: referenceId,
      referenceId: referenceId,
      type: 'PIX_TRANSFER_DEBIT',
      amount: _asDouble(transfer['amount']),
      cpf: _nullableString(transfer['cpfMasked']),
      createdAt: _asDateTime(transfer['createdAt']),
      status: status,
      providerTxId: _nullableString(transfer['providerTxId']),
      receiptUrl: _nullableString(transfer['receiptUrl']),
      failureReason: _nullableString(transfer['failureReason']),
    );
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String? _nullableString(dynamic value) {
    final text = _asString(value);
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_asString(value).replaceAll(',', '.')) ?? 0;
  }

  DateTime _asDateTime(dynamic value) {
    final parsed = DateTime.tryParse(_asString(value));
    return parsed ?? DateTime.now();
  }
}
