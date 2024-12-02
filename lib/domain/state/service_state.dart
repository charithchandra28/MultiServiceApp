import 'package:equatable/equatable.dart';

class ServiceState extends Equatable {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> filteredServices;
  final bool isLoading;
  final bool isRetrying;
  final bool isSearchMode;
  final bool isOnline;
  final bool hasReachedMax;
  final DateTime? lastUpdated;
  final String? errorMessage;

  const ServiceState({
    required this.services,
    required this.filteredServices,
    this.isLoading = false,
    this.isRetrying = false,
    this.isSearchMode = false,
    this.isOnline = true,
    this.hasReachedMax = false,
    this.lastUpdated,
    this.errorMessage,
  });

  ServiceState copyWith({
    List<Map<String, dynamic>>? services,
    List<Map<String, dynamic>>? filteredServices,
    bool? isLoading,
    bool? isRetrying,
    bool? isSearchMode,
    bool? isOnline,
    bool? hasReachedMax,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return ServiceState(
      services: services ?? this.services,
      filteredServices: filteredServices ?? this.filteredServices,
      isLoading: isLoading ?? this.isLoading,
      isRetrying: isRetrying ?? this.isRetrying,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      isOnline: isOnline ?? this.isOnline,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    services,
    filteredServices,
    isLoading,
    isRetrying,
    isSearchMode,
    isOnline,
    hasReachedMax,
    lastUpdated,
    errorMessage,
  ];
}
