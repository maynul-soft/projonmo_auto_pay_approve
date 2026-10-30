import 'package:equatable/equatable.dart';
import '../../data/models/pending_payment.dart';

enum PendingMatchStatus { matched, noSms, amountMismatch }

class PendingItemWithMatch extends Equatable {
  final PendingPayment payment;
  final PendingMatchStatus matchStatus;
  final double? smsAmount;

  const PendingItemWithMatch({
    required this.payment,
    required this.matchStatus,
    this.smsAmount,
  });

  @override
  List<Object?> get props => [payment, matchStatus, smsAmount];
}

class PendingState extends Equatable {
  final List<PendingItemWithMatch> allItems;
  final List<PendingItemWithMatch> filteredItems;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastFetchedAt;
  final int totalCount;
  final double totalAmount;

  const PendingState({
    this.allItems = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.lastFetchedAt,
    this.totalCount = 0,
    this.totalAmount = 0.0,
  });

  PendingState copyWith({
    List<PendingItemWithMatch>? allItems,
    List<PendingItemWithMatch>? filteredItems,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastFetchedAt,
    int? totalCount,
    double? totalAmount,
  }) {
    return PendingState(
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      totalCount: totalCount ?? this.totalCount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  @override
  List<Object?> get props => [
        allItems,
        filteredItems,
        searchQuery,
        isLoading,
        errorMessage,
        lastFetchedAt,
        totalCount,
        totalAmount,
      ];
}
