import 'dart:async';
import 'package:ex1/data/models/service_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/exceptions.dart';
import '../../data/cache_manager.dart';
import '../../data/repositories/image_repository.dart';
import '../state/service_state.dart';
import 'internet_connectivity_bloc.dart';








class ServiceCubit extends Cubit<ServiceState> {
  final ImageRepository imageRepository;
  final InternetConnectivityBloc connectivityBloc;
  final CacheManager cacheManager;
  Timer? _debounceTimer;
  bool _isFetching = false;



  ServiceCubit({
    required this.imageRepository,
    required this.connectivityBloc,
    required this.cacheManager,

  })
      : super(ServiceState(services: [], imageUrlCache: {}, filteredServices: [],isSearchMode: false,
  )) {
    connectivityBloc.internetAvailabilityStream.listen((isAvailable) {
      if (isAvailable) {
        _fetchDataWithRetries();
      } else {
        _loadCachedData();
      }
    });
  }





  /// Fetches data with retries using exponential backoff.
  Future<void> _fetchDataWithRetries() async {
    if (_isFetching) return;
    _isFetching = true;

    emit(state.copyWith(isLoading: true, isRetrying: true,errorMessage: 'Retrying to fetch data...'));
    try {
      await connectivityBloc.retryWithBackoff(_fetchData);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isRetrying: false,
        errorMessage: _categorizeError(e as Exception),
      ));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _loadCachedData() async {

    try {
      if (cacheManager.isCacheExpired()) {
        emit(state.copyWith(
            isLoading: false, errorMessage: 'Cache expired. Please refresh.'));
        return;
      }

      final cachedServices = await cacheManager.getCachedServices();
      if (cachedServices != null) {
        emit(state.copyWith(
          services: cachedServices,
          filteredServices: cachedServices,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
            isLoading: false, errorMessage: 'No cached data available.'));
        return;

      }
    }
    catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: _categorizeError(e as Exception)));
    }
  }


  Future<void> _fetchData() async {

    emit(state.copyWith(isLoading: true, errorMessage: null));


    try {

      // Define the list of services
      final serviceMaps = [
        ServiceModel(id:'1',name: 'Grocery Booking', imageKey: 'grocery.jpg'),
        ServiceModel(id:'2',name: 'Hair Salon Booking', imageKey: 'salon.jpg'),
        ServiceModel(id:'3',name: 'Room Rent Booking', imageKey: 'room_rent.jpg'),
        ServiceModel(id:'4',name: 'Land Availability', imageKey: 'land.jpg'),
        ServiceModel(id:'5',name: 'Cab Booking', imageKey: 'cab.jpg'),
        ServiceModel(id:'6',name: 'Restaurant Booking', imageKey: 'restaurant.jpg'),
        ServiceModel(id:'7',name: 'Chicken Booking', imageKey: 'chicken_mutton.jpg'),
        ServiceModel(id:'8',name: 'Tent Booking', imageKey: 'restaurant.jpg'),
        ServiceModel(id:'9',name: 'Cloud Booking', imageKey: 'restaurant.jpg'),

      ];

      // Convert to List<Map<String, dynamic>>
      List<Map<String, dynamic>> services = ServiceModel.toMapList(serviceMaps);


      // Fetch all images in parallel
      final imageFetchTasks = services.map((service) async {
        final imageKey = service['imageKey'] ?? 'unknown';

        try {
          // Check cache first
          final cachedUrl = await cacheManager.getCachedImageUrl(imageKey);
          if (cachedUrl != null) return {imageKey: cachedUrl};

          // Fetch image URL
          final url = await imageRepository.fetchImageUrl(imageKey);
          final validUrl = url ?? 'https://via.placeholder.com/150?text=No+Image';

          // Cache the fetched URL
          await cacheManager.saveImageUrl(imageKey, validUrl);

          return {imageKey: validUrl};
        } catch (e) {
          throw NetworkException('Failed to fetch image for $imageKey: ${e.toString()}');
        }
      });

      // Wait for all tasks to complete
      final fetchedImages = await Future.wait(imageFetchTasks);

      // Build the image cache map
       final imageUrlCache = <String, String>{
        for (var imageMap in fetchedImages) ...imageMap,
      };


      await cacheManager.saveServices(services);

      emit(state.copyWith(services: services, filteredServices: services, imageUrlCache: imageUrlCache, isLoading: false,isRetrying: false,
      ));
    }
    catch (e) {

      throw NetworkException('Failed to fetch services: ${e.toString()}');

    }

  }




  Future<void> refreshData() async {
    await _fetchData();
  }



  void searchServices(String query) async{

    _debounce(() async {

      if (query.isEmpty) {
        // Reset to show all services if the query is empty
        emit(state.copyWith(filteredServices: state.services));
      } else {
        // Filter services based on the search query
        final filtered = await compute(_filterServices, {'services': state.services, 'query': query});
        emit(state.copyWith(filteredServices: filtered)); // Update filtered services.

      }

    });

  }

  static List<Map<String, dynamic>> _filterServices(Map<String, dynamic> params) {
    final List<Map<String, dynamic>> services = params['services'];
    final String query = params['query'];
    return services
        .where((service) =>
        service['name'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }


  void _debounce(Function callback, {Duration duration = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, () => callback());
  }

  void toggleSearchMode() {
    emit(state.copyWith(isSearchMode: !state.isSearchMode));
  }

  String _categorizeError(Exception e) {
    if (e is NetworkException) {
      return e.message;
    } else if (e is CacheException) {
      return e.message;
    } else {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }



  @override
  Future<void> close() {

    _debounceTimer?.cancel();

    connectivityBloc.dispose();

    return super.close();
  }
}
