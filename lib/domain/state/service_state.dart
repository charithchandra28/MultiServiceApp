
class ServiceState  {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> filteredServices;
  final Map<String, String> imageUrlCache;
  final Map<String, List<Map<String, dynamic>>> searchIndex;
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
    required this.imageUrlCache,
    required this.searchIndex,
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
    Map<String, String>? imageUrlCache,
    Map<String, List<Map<String, dynamic>>>? searchIndex,
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
      imageUrlCache: imageUrlCache ?? this.imageUrlCache,
      searchIndex: searchIndex ?? this.searchIndex,
      isLoading: isLoading ?? this.isLoading,
      isRetrying: isRetrying ?? this.isRetrying,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      isOnline: isOnline ?? this.isOnline,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      lastUpdated: lastUpdated,
      errorMessage: errorMessage,
    );
  }
}
