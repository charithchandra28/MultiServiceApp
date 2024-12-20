import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/blocs/service_cubit.dart';
import '../../domain/state/service_state.dart';
import '../widgets/service_card.dart';
import 'screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  Timer? _debounceTimer;




  @override
  void initState() {
    super.initState();
    print("First called");

    final serviceCubit = context.read<ServiceCubit>();

    // Load cached data initially
    serviceCubit.loadCachedData();

    // If online, fetch services from the server
    if (serviceCubit.state.isOnline) {
      serviceCubit.fetchServices();
    }
  }



  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      BlocProvider.of<ServiceCubit>(context).searchServices(query);
    });
  }



  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceCubit, ServiceState>(
        buildWhen: (previous, current) =>
        previous.isOnline != current.isOnline ||
            previous.services != current.services ||
            previous.isLoading != current.isLoading ||
            previous.hasReachedMax != current.hasReachedMax,
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(state),
          body: SafeArea(
            child: Column(
              children: [
                if (!state.isOnline) _buildOfflineBanner(state),
                Expanded(child: _buildBody(state)),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildOfflineBanner(ServiceState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: Colors.red,
      padding: const EdgeInsets.all(8.0),
      height: state.isOnline ? 0 : 50,
      child: const Center(
        child: Text(
          'Offline mode: Data may be outdated.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }



  PreferredSizeWidget _buildAppBar(ServiceState state) {
    return AppBar(
      title: state.isSearchMode ? _buildSearchBar(): const Text(
        'Multi-Service App',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.teal,
      elevation: 8.0,
      actions: [ _buildSearchToggle(state)],
    );
  }


  Widget _buildSearchBar() {
    return TextField(
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
            BlocProvider.of<ServiceCubit>(context).searchServices('');
          },
        )
            : null,
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: onSearchChanged,
    );
  }



  IconButton _buildSearchToggle(ServiceState state) {
    return IconButton(
      icon: Icon(state.isSearchMode ? Icons.cancel : Icons.search),
      tooltip: state.isSearchMode ? 'Close search' : 'Open search',
      onPressed: () {
        context.read<ServiceCubit>().toggleSearchMode();
        if (state.isSearchMode) {
          _searchController.clear();
          BlocProvider.of<ServiceCubit>(context).searchServices('');
          _focusNode.unfocus();
        } else {
            _focusNode.requestFocus();

        }
      },
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


    if (state.services.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.services.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(state.errorMessage!),
          ElevatedButton(
            onPressed: () => context.read<ServiceCubit>().retry(),
            child: const Text('Retry'),
          ),
        ],
      );
    }


    final servicesWithScreens = attachScreens(
      state.isSearchMode ? state.filteredServices : state.services,
    );

      return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return

              RefreshIndicator(
                onRefresh: () async {
              await context.read<ServiceCubit>().refreshServices();
            },
            child:  NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                  !state.isLoading &&
                  !state.hasReachedMax && state.isOnline) {
                _onScrollEnd(context);
                return true;
              }
              return false;
            },

            child: GridView.builder(

                    controller: _scrollController,

                    physics: const BouncingScrollPhysics(), // Ensure scroll physics are enabled

                    padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: paddingHorizontal),

                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: maxCrossAxisExtent,
                      crossAxisSpacing: paddingHorizontal,
                      mainAxisSpacing: paddingVertical,
                      childAspectRatio: 1.0,
                    ),

                    itemCount:  servicesWithScreens.length + (state.hasReachedMax ? 0 : 1),

                    shrinkWrap: true,

                    itemBuilder: (context, index) {

                     if (index == servicesWithScreens.length) {
                       return const Center(
                         child: Padding(
                         padding: EdgeInsets.all(8.0),
                         child: CircularProgressIndicator(),
                          ),
                       );
                      }

                      final service = servicesWithScreens[index];

                      return Hero(
                        tag: service['name'],
                        child: ServiceCard(
                          service: service,
                          imageUrl: service['imageUrl'],
                          fontSize: fontSize,
                          theme: theme,
                        ),
                      );
                    },
                  )
            )
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

  void _onScrollEnd(BuildContext context) {
    // Cancel any existing debounce timer
    _debounceTimer?.cancel();

    // Set a new debounce timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      print("clicked me fuck");


      context.read<ServiceCubit>().fetchServices();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }


}
