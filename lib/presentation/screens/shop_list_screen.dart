import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/shop_model.dart';
import '../../domain/blocs/shop_cubit.dart';
import '../../domain/state/shop_state.dart';

class ShopListScreen extends StatelessWidget {
  final String serviceName;

  const ShopListScreen({Key? key, required this.serviceName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$serviceName Shops',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ShopCubit, ShopState>(
            listenWhen: (previous, current) => previous.errorMessage != current.errorMessage,
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<ShopCubit, ShopState>(
          builder: (context, state) {
            if (state.isLoading && state.shops.isEmpty) {
              return ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => const SkeletonLoader(),
              );
            }

            if (state.shops.isEmpty) {
              return const EmptyState();
            }

            return ShopListView(
              shops: state.shops,
              fetchNextPage: () {
                context.read<ShopCubit>().fetchNextPage();
              },
            );
          },
        ),
      ),
    );
  }
}

class ShopListView extends StatefulWidget {
  final List<ShopModel> shops;
  final VoidCallback fetchNextPage;

  const ShopListView({Key? key, required this.shops, required this.fetchNextPage}) : super(key: key);

  @override
  _ShopListViewState createState() => _ShopListViewState();
}

class _ShopListViewState extends State<ShopListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        widget.fetchNextPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: widget.shops.length,
      itemBuilder: (context, index) {
        return ShopCard(shop: widget.shops[index]);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ShopCard extends StatelessWidget {
  final ShopModel shop;

  const ShopCard({Key? key, required this.shop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: shop.imageUrl,
              width: double.infinity,
              height: screenWidth * 0.5,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045,
                  ),
                ),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  shop.description,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenWidth * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service: ${shop.servicetype}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        fontStyle: FontStyle.italic,
                        color: Colors.teal,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(
                          vertical: screenWidth * 0.025,
                          horizontal: screenWidth * 0.04,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'More Info',
                        style: TextStyle(fontSize: screenWidth * 0.035),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: double.infinity,
        height: screenWidth * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Text(
        'No shops found.',
        style: TextStyle(
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}
