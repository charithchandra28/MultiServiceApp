import 'package:get_it/get_it.dart';
import '../data/repositories/image_repository.dart';
import '../blocs/connectivity_handler.dart';
import '../blocs/internet_connectivity_bloc.dart';
import '../blocs/service_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/cache_manager.dart';


final getIt = GetIt.instance;

Future<void> setupDependencies() async {

  final prefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<CacheManager>(() => CacheManager(prefs));


  // Register ImageRepository as a singleton
  getIt.registerLazySingleton<ImageRepository>(() => ImageRepository('ServiceImages'));

  // Register ConnectivityHandler as a singleton
  getIt.registerLazySingleton<ConnectivityHandler>(() => ConnectivityHandler());

  // Register InternetConnectivityBloc as a singleton
  getIt.registerLazySingleton<InternetConnectivityBloc>(
        () => InternetConnectivityBloc(connectivityHandler: getIt<ConnectivityHandler>()),
  );

  // Register ServiceCubit as a factory
  getIt.registerFactory<ServiceCubit>(
        () => ServiceCubit(
      imageRepository: getIt<ImageRepository>(),
      connectivityBloc: getIt<InternetConnectivityBloc>(),
          cacheManager: getIt<CacheManager>(),
        ),
  );
}
