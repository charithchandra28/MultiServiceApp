/*
ServiceState: This class holds the current data (state) for the UI:
services: The list of services (like Grocery Booking, Hair Salon Booking).
imageUrlCache: Stores image URLs for the services.
isLoading: Tells if the data is still loading.
errorMessage: Stores any error message if something goes wrong.
copyWith(): This method helps create a new state by copying the current one and updating only the parts that change.
 */



class ServiceState {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> filteredServices;
  final Map<String, String> imageUrlCache;
  final bool isLoading;
  final bool isRetrying;
  final bool isSearchMode;
  final String? errorMessage;


  ServiceState({
    required this.services,
    required this.filteredServices,
    required this.imageUrlCache,
    this.isLoading = false,
    this.isRetrying = false,
    this.isSearchMode = false,
    this.errorMessage,
  });

  /*
  copyWith(): This method helps create a new state by copying the current one and
  updating only the parts that change.
   */
  ServiceState copyWith({
    List<Map<String, dynamic>>? services,
    List<Map<String, dynamic>>? filteredServices,
    Map<String, String>? imageUrlCache,
    bool? isLoading,
    bool? isRetrying,
    bool? isSearchMode,
    String? errorMessage,
  }) {
    return ServiceState(
      services: services ?? this.services,
      filteredServices: filteredServices ?? this.filteredServices,
      imageUrlCache: imageUrlCache ?? this.imageUrlCache,
      isLoading: isLoading ?? this.isLoading,
      isRetrying: isRetrying ?? this.isRetrying,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      errorMessage: errorMessage,
    );
  }
}

