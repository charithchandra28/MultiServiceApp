import 'package:get_it/get_it.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/cache_manager.dart';
import '../data/repositories/shop_repository.dart';
import '../domain/blocs/shop_cubit.dart';
import 'connectivity_handler.dart';
import '../domain/blocs/internet_connectivity_bloc.dart';
import '../domain/blocs/service_cubit.dart';


final getIt = GetIt.instance;

Future<void> setupDependencies() async {

  final prefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<CacheManager>(() => CacheManager(prefs));



  // Register ConnectivityHandler as a singleton
  getIt.registerLazySingleton<ConnectivityHandler>(() => ConnectivityHandler());

  // Register InternetConnectivityBloc as a singleton
  getIt.registerLazySingleton<InternetConnectivityBloc>(
        () => InternetConnectivityBloc(connectivityHandler: getIt<ConnectivityHandler>()),
  );

  // Register ShopRepository
  getIt.registerLazySingleton<ShopRepository>(
        () => ShopRepository(),
  );

  // Register ShopCubit
  getIt.registerFactory<ShopCubit>(
        () => ShopCubit(repository: getIt<ShopRepository>()),
  );


  // Register ServiceCubit as a factory
  getIt.registerFactory<ServiceCubit>(
        () => ServiceCubit(
      connectivityBloc: getIt<InternetConnectivityBloc>(),
          cacheManager: getIt<CacheManager>(),
        ),
  );
}
