import 'blocs/connectivity_handler.dart';
import 'blocs/internet_connectivity_bloc.dart';
import 'core/config/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/service_cubit.dart';
import 'data/repositories/image_repository.dart';
import 'di.dart';
import 'screens/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await setupDependencies();
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    final serviceCubit = getIt<ServiceCubit>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Multi-Service App',
      home: BlocProvider(
        create: (context) => serviceCubit,
        child: HomeScreen(),
      ),
    );
  }
}
