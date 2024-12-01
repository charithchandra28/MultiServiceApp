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
  Set<int> loadedServiceIds = {}; // Track already loaded service IDs


  Timer? _debounceTimer;
  Timer? _debounce;

  bool _isFetching = false;

  int _currentPage = 0;


  ServiceCubit({
    required this.connectivityBloc,
    required this.cacheManager,
  }) : super(ServiceState(
    services: [],
    filteredServices: [],
    imageUrlCache: {},
    searchIndex: {},
    isSearchMode: false,
  )) {
    connectivityBloc.internetAvailabilityStream.listen((isAvailable) {
      if (isAvailable) {
        print("fetching");
        fetchData();
      } else {
        _loadCachedData();
      }
    });
  }


  int get currentPage => _currentPage;


  DateTime? get lastUpdated => state.lastUpdated;

  /// Fetch services with pagination and partial fallback

  Future<void> fetchData({int page = 0}) async {
    if (state.hasReachedMax || _isFetching) return; // Prevent overlapping fetch calls

    _isFetching = true;
    emit(state.copyWith(isLoading: true));

    cacheManager.clearCache();

    try {
      List<Map<String, dynamic>> combinedServices = state.services;
      // Load cached data for the first page
      if (page == 0 && cacheManager.getCachedServices() != null) {
        combinedServices = cacheManager.getCachedServices()!;
        loadedServiceIds.addAll(combinedServices.map((service) => service['id'] as int? ?? -1));
      }

      // Fetch new services from Supabase
      final newServices = await _fetchPaginatedServices(page);


      if (newServices.isEmpty) {
        emit(state.copyWith(hasReachedMax: true, isLoading: false));
        return;
      }

      // Deduplicate services by 'id'
      final uniqueNewServices = newServices.where((service) {

        final id = service['id'] as int? ?? -1;

        if (id == -1) {
          print('Null ID encountered for service: $service');
          return false;
        }

        if (loadedServiceIds.contains(id)) {
          return false;
        } else {
          loadedServiceIds.add(id);
          return true;
        }
      }).toList();

      combinedServices.addAll(uniqueNewServices);
      await _saveServicesWithHash(combinedServices);

      emit(state.copyWith(
        services: combinedServices,
        filteredServices: combinedServices,
        lastUpdated: DateTime.now(),
        isLoading: false,
      ));
      _currentPage = page;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _categorizeError(e),
      ));
    } finally {
      _isFetching = false;
    }
  }


  /// Save services with hash validation
  Future<void> _saveServicesWithHash(List<Map<String, dynamic>> services) async {
    final hash = _computeHash(services);
    final cachedHash = cacheManager.getHash();

    if (cachedHash != hash) {
      await cacheManager.saveServices(services);
      await cacheManager.saveHash(hash);
      print('Cache updated with hash: $hash');
    } else {
      print('No changes detected. Cache remains the same.');
    }
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

  /// Add or update a specific service in the cache
  Future<void> addOrUpdateService(Map<String, dynamic> service) async {
    try {
      final cachedServices = cacheManager.getCachedServices() ?? [];
      final updatedServices = cachedServices.map((item) {
        if (item['id'] == service['id']) return service; // Replace if ID matches
        return item;
      }).toList();

      if (!updatedServices.any((item) => item['id'] == service['id'])) {
        updatedServices.add(service); // Add if not already in the cache
      }

      await _saveServicesWithHash(updatedServices);
    } catch (e) {
      throw Exception('Failed to add or update service: $e');
    }
  }


  /// Compute hash for a list of services
  String _computeHash(List<Map<String, dynamic>> services) {
    final jsonString = jsonEncode(services);
    return jsonString.hashCode.toString();
  }


  /// Refresh data from the beginning
  Future<void> refreshData() async {
    emit(state.copyWith(hasReachedMax: false, services: []));
    await fetchData(page: 0);
  }

  /// Retry fetch with exponential backoff
  Future<List<Map<String, dynamic>>> _retryFetch(
      int retries, {
        required Future<List<Map<String, dynamic>>> Function() fetchFunction,
      }) async {
    int delayMs = 200;
    for (int i = 0; i < retries; i++) {
      try {
        _logRetry(i + 1);
        return await fetchFunction();
      } catch (e) {
        if (i == retries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
      }
    }
    return [];
  }

  /// Fetch services from Supabase with pagination and slow network feedback
  Future<List<Map<String, dynamic>>> _fetchPaginatedServices(int page) async {
    final slowNetworkTimer = Timer(const Duration(seconds: 5), () {
      emit(state.copyWith(errorMessage: 'This is taking longer than expected...'));
    });

    try {
      return _retryFetch(3, fetchFunction: () async {
        final response = await Supabase.instance.client
            .from(AppConfig.servicesTable)
            .select('${AppConfig.columnName},${AppConfig.columnId}, ${AppConfig.columnImageUrl}, ${AppConfig.columnServiceType}')
            .range(page * AppConfig.pageSize, ((page + 1) * AppConfig.pageSize) - 1);

        return (response as List<dynamic>).map((item) => item as Map<String, dynamic>).toList();
      });
    } finally {
      slowNetworkTimer.cancel();
    }
  }


  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isEmpty ||
        connectivityResult[0] == ConnectivityResult.none) {
      return false;
    }
    return true;
  }





  /// Logging: Cache usage
  void _logCacheUsage(int count) {
    print('Cache hit: Loaded $count services from cache.');
  }

  /// Logging: Retry attempts
  void _logRetry(int attempt) {
    print('Retry attempt: $attempt');
  }

  /// Fallback to cached data when offline
  Future<void> _loadCachedData() async {
    try {
      final cachedServices = cacheManager.getCachedServices();
      if (cachedServices != null) {
        emit(state.copyWith(
          services: cachedServices,
          filteredServices: cachedServices,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'No cached data available. Please connect to the internet.',
        ));
      }
    } catch (e) {
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
  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    connectivityBloc.dispose();
    return super.close();
  }
}
