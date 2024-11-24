import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/service_cubit.dart';
import '../blocs/service_state.dart';
import '../di.dart';
import '../features/booking_screens/screens.dart';
import '../widgets/service_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final serviceCubit = getIt<ServiceCubit>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;



  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      serviceCubit.searchServices(query);
    });
  }



  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceCubit, ServiceState>(
        bloc: serviceCubit,
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: state.isSearchMode ? TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.white70),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      serviceCubit.searchServices('');
                    },
                  )
                      : null,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: onSearchChanged,
              ) : const Text(
                'Multi-Service App',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.teal,
              elevation: 8.0,
              actions: [IconButton(
                icon: Icon(state.isSearchMode ? Icons.cancel : Icons.search),
                tooltip: state.isSearchMode ? 'Close search' : 'Open search',
                onPressed: () {
                  if (state.isSearchMode) {
                    serviceCubit.toggleSearchMode();
                    _searchController.clear();
                    serviceCubit.searchServices('');
                    _focusNode.unfocus();
                  } else {
                    serviceCubit.toggleSearchMode();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _focusNode.requestFocus();
                    });
                  }
                },
              )
              ],
            ),
            body: _buildBody(state),
          );
        }
    );
  }

  Widget _buildBody(ServiceState state) {

    final theme = Theme.of(context);
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final isPortrait = MediaQuery
        .of(context)
        .orientation == Orientation.portrait;

    double paddingHorizontal = screenWidth * 0.04;
    double paddingVertical = screenHeight * 0.02;
    double fontSize = screenWidth * 0.04;

    if (screenWidth < 320) {
      fontSize = 12;
    } else if (screenWidth > 800) {
      fontSize = 18;
    }

    double maxCrossAxisExtent = isPortrait ? screenWidth * 0.5 : screenWidth *
        0.3;

    if (screenWidth < 320) {
      maxCrossAxisExtent = 180;
      paddingHorizontal = 10;
      paddingVertical = 8;
    } else if (screenWidth > 800) {
      maxCrossAxisExtent = screenWidth * 0.25;
    }

    if (state.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (state.errorMessage != null) {
        return Center(child: Text(state.errorMessage!, style: const TextStyle(color: Colors.red)));
      }

      if (state.services.isEmpty | state.filteredServices.isEmpty) {
        return const Center(child: Text('No services available.'));
      }

      final servicesWithScreens;

      if(state.isSearchMode){
        servicesWithScreens = attachScreens(state.filteredServices);

      }else{
        servicesWithScreens = attachScreens(state.services);
      }

      return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return
              SingleChildScrollView(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Call the initialize() method in ServiceCubit to reload data
                    await context.read<ServiceCubit>().refreshData();
                    ();
                  },

                  child: GridView.builder(

                    padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: paddingHorizontal),

                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: maxCrossAxisExtent,
                      crossAxisSpacing: paddingHorizontal,
                      mainAxisSpacing: paddingVertical,
                      childAspectRatio: 1.0,
                    ),

                    itemCount: servicesWithScreens.length,

                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    itemBuilder: (context, index) {

                      final service = servicesWithScreens[index];

                      return Hero(
                        tag: service['name'],
                        child: ServiceCard(
                          service: service,
                          imageUrl: state.imageUrlCache[service['imageKey']],
                          fontSize: fontSize,
                          theme: theme,
                        ),
                      );
                    },
                  ),
                ),
              );
          },
        ),
      );
  }

    List<Map<String, dynamic>> attachScreens(List<Map<String, dynamic>> services) {
    return services.map((service) {
      switch (service['name']) {
        case 'Grocery Booking':
          return {...service, 'screen': GroceryBookingScreen()};
        case 'Hair Salon Booking':
          return {...service, 'screen': HairSalonBookingScreen()};
        case 'Room Rent Booking':
          return {...service, 'screen': RoomRentBookingScreen()};
        case 'Land Availability':
          return {...service, 'screen': LandAvailabilityScreen()};
        case 'Cab Booking':
          return {...service, 'screen': CabBookingScreen()};
        case 'Restaurant Booking':
          return {...service, 'screen': RestaurantBookingScreen()};
        case 'Chicken Booking':
          return {...service, 'screen': MeatBookingScreen()};
        case 'Tent Booking':
          return {...service, 'screen': RestaurantBookingScreen()};
        case 'Cloud Booking':
          return {...service, 'screen': MeatBookingScreen()};
        default:
          return service;
      }
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }


}
