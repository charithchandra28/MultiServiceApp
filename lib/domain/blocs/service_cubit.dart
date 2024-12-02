import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/exceptions.dart';
import '../../data/cache_manager.dart';
import '../state/service_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'internet_connectivity_bloc.dart';


class AppConfig {
  static const String servicesTable = 'services';
  static const String columnName = 'name';
  static const String columnImageUrl = 'imageUrl';
  static const String columnServiceType = 'servicetype';
  static const int pageSize = 8;
  static const String columnId='id' ;
}



class ServiceCubit extends Cubit<ServiceState> {
  final CacheManager cacheManager;
  final InternetConnectivityBloc connectivityBloc;

  bool _isFetching = false;
  int _currentPage = 0;
  static const int _pageSize = 10; // Number of items per page
  final Set<int> _loadedServiceIds = {}; // Tracks IDs of already loaded services


  Timer? _debounceTimer;
  Timer? _debounce;




  ServiceCubit({
    required this.connectivityBloc,
    required this.cacheManager,
  }) : super(ServiceState(
    services: [],
    filteredServices: [],
    isOnline: true,
    isSearchMode: false,
  )) {
    connectivityBloc.internetAvailabilityStream.listen((isAvailable) {

      emit(state.copyWith(isOnline:isAvailable));

      if (isAvailable) {
        print("did it got called 1");

        if((state.services.isNotEmpty && !state.hasReachedMax) || (cacheManager.getCachedServices()==null) ){
          print("did it got called 2");

          fetchServices();
        }

      } else {
        loadCachedData();
      }
    });

  }

  void loadCachedData() {
      print("did it got called 3");
      _loadCachedData();

  }




  /// Fetch services with pagination and partial fallback

  Future<void> fetchServices({bool isRefresh = false}) async {

    if (_isFetching || state.hasReachedMax) return;

    _isFetching = true;

    print("fetch $isRefresh ");


    if (isRefresh) {
      emit(state.copyWith(isLoading: true, hasReachedMax: false, errorMessage: null));
      _currentPage = 0;
      _loadedServiceIds.clear(); // Reset the set when refreshing
    } else {
      emit(state.copyWith(isLoading: true, errorMessage: null));
    }

    try {

      final newServices = await _fetchPaginatedData();

      // Deduplicate services by checking `_loadedServiceIds`
      final uniqueServices = newServices.where((service) {
        final id = service['id'] as int? ?? -1;
        if (id == -1 || _loadedServiceIds.contains(id)) {
          return false; // Exclude duplicates or invalid IDs
        } else {
          _loadedServiceIds.add(id); // Mark ID as loaded
          return true;
        }
      }).toList();

      print("$newServices");
      print("$uniqueServices");
      // Skip emitting state if no new unique services
      if (uniqueServices.isEmpty) {
        emit(state.copyWith(isLoading: false, hasReachedMax: true));
        return;
      }



      final updatedServices = isRefresh ? uniqueServices : [...state.services, ...uniqueServices];

      // Save updated services to cache
      if (isRefresh || _currentPage == 0) {
          await cacheManager.saveServices(updatedServices);

      } // Save to cache
        emit(state.copyWith(
          services: updatedServices,
          filteredServices: updatedServices,
          hasReachedMax: uniqueServices.length < _pageSize,
          isLoading: false,
        ));
        _currentPage++;
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: _categorizeError(e)));
    } finally {
      _isFetching = false;
    }
  }


  /// Fetch paginated data with retry logic
  Future<List<Map<String, dynamic>>> _fetchPaginatedData({int retries = 3}) async {
    final start = _currentPage * _pageSize;
    final end = start + _pageSize - 1;

    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final response = await Supabase.instance.client
            .from('services')
            .select('*')
            .range(start, end);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        if (attempt == retries - 1) rethrow; // Rethrow after final attempt
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1))); // Exponential backoff
      }
    }
    return [];
  }





  /// Search services with debouncing
  void searchServices(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        emit(state.copyWith(filteredServices: state.services));
        return;
      }

      emit(state.copyWith(isLoading: true));
      try {
        final isOnline = await isConnected(); // Check connectivity

        if (isOnline) {
          final results = await Supabase.instance.client
              .from(AppConfig.servicesTable)
              .select('${AppConfig.columnName},${AppConfig.columnId}, ${AppConfig.columnImageUrl}, ${AppConfig.columnServiceType}')
              .ilike(AppConfig.columnName, '%$query%');

          emit(state.copyWith(
            filteredServices: (results as List<dynamic>).map((item) => item as Map<String, dynamic>).toList(),
            isLoading: false,
          ));
        } else {
          final cachedServices = cacheManager.getCachedServices() ?? [];
          final filteredServices = cachedServices.where((service) {
            return (service[AppConfig.columnName] as String).toLowerCase().contains(query.toLowerCase());
          }).toList();

          emit(state.copyWith(
            filteredServices: filteredServices,
            isLoading: false,
          ));
        }
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Search failed: ${e.toString()}',
        ));
      }
    });
  }





  /// Refresh data from the beginning
  Future<void> refreshData() async {
    print("fghfgh");
    emit(state.copyWith(hasReachedMax: false, services: []));
    // await fetchData(page: 0);
  }





  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isEmpty ||
        connectivityResult[0] == ConnectivityResult.none) {
      return false;
    }
    return true;
  }




  /// Logging: Retry attempts
  void _logRetry(int attempt) {
    print('Retry attempt: $attempt');
  }
  /// Load cached data for offline use
  Future<void> _loadCachedData() async {
    try {

      print("does it came here");
      // Check if the cache is expired or does not exist
      if (cacheManager.isCacheExpired()) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'No cached data available. Please connect to the internet.',
        ));
        return;
      }
      // Fetch cached services from CacheManager
      final cachedServices = cacheManager.getCachedServices();

      print(cachedServices);

      // Exit if no cached services are available
      if (cachedServices == null || cachedServices.isEmpty) {
        // No cached data available
        print("it is entering here");
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'No cached data available. Please connect to the internet.',
        ));
        return;
      }

      // Check if cached services are already present in the state
      final currentServiceIds = state.services.map((service) => service['id']).toSet();

      final newCachedServices = cachedServices.where((service) {
        final id = service['id'];
        return id != null && !currentServiceIds.contains(id);
      }).toList();

      _loadedServiceIds.addAll(cachedServices.map((service) => service['id']).whereType<int>());

      // Set the current page to the cached page
      _currentPage = 1;


      // If no new cached services to add, skip emitting state
      if (newCachedServices.isEmpty) {
        return;
      }

      print(state.services);
      print(newCachedServices);

      // Emit updated state with deduplicated cached services
      emit(state.copyWith(
        services: [...state.services, ...newCachedServices],
        filteredServices: [...state.services, ...newCachedServices],
        isLoading: false,
        hasReachedMax: newCachedServices.length < _pageSize,
      ));
    } catch (e) {
      print("does error coming here");
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load cached data: ${e.toString()}',
      ));
    }
  }

  /// Toggle search mode
  void toggleSearchMode() {
    emit(state.copyWith(isSearchMode: !state.isSearchMode));
  }

  /// Refresh services (pull-to-refresh functionality)
  Future<void> refreshServices() async {
    await fetchServices(isRefresh: true);
  }

  /// Categorize and handle errors for user-friendly messages
  String _categorizeError(Object error) {
    if (error is NetworkException) {
      return 'Please check your internet connection and try again.';
    } else if (error is SupabaseException) {
      return 'A server error occurred. Please try again later.';
    } else if (error is TimeoutException) {
      return 'The request timed out. Please try again later.';
    } else if (error is FormatException) {
      return 'Data format error. Please contact support.';
    } else if (error is Exception) {
      return 'An unexpected error occurred: ${error.toString()}';
    } else {
      // Handle non-Exception errors gracefully
      return 'An unknown error occurred: ${error.toString()}';
    }
  }


  /// Retry fetching services
  Future<void> retry() async {
    if (state.isOnline) {
      fetchServices();
    } else {
      _loadCachedData();
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    connectivityBloc.dispose();
    return super.close();
  }
}
