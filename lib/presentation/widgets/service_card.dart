import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/shop_repository.dart';
import '../../domain/blocs/shop_cubit.dart';
import '../screens/shop_list_screen.dart';

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final String? imageUrl;
  final double fontSize;
  final ThemeData theme;

  const ServiceCard({super.key,
    required this.service,
    required this.imageUrl,
    required this.fontSize,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double paddingHorizontal = 0.04 * screenWidth;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BlocProvider(
              create: (_) => ShopCubit(
                repository: ShopRepository(),
              )..fetchShops(service['servicetype']), // Pass service name as servicetype
              child: ShopListScreen(serviceName: service['name']),
            ),),
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 12,
          shadowColor: Colors.tealAccent.withOpacity(0.5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: theme.brightness == Brightness.dark
                    ? [Colors.grey.shade800, Colors.grey.shade600]
                    : [Colors.teal.shade400, Colors.teal.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child:_RetryableCachedImage(
                      imageUrl: imageUrl ?? '',
                      serviceName: service['name'] ?? 'Unknown Service',
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Padding(
                  padding:  EdgeInsets.symmetric(horizontal: paddingHorizontal),
                  child: Text(
                    service['name'] ?? 'Unknown Service',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color:theme.textTheme.bodyLarge?.color,
                      shadows: const <Shadow>[
                        Shadow(
                          offset: Offset(0.5, 0.5),
                          blurRadius: 1.0,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _RetryableCachedImage extends StatefulWidget {
  final String imageUrl;
  final String serviceName;

  const _RetryableCachedImage({
    Key? key,
    required this.imageUrl,
    required this.serviceName,
  }) : super(key: key);

  @override
  State<_RetryableCachedImage> createState() => _RetryableCachedImageState();
}

class _RetryableCachedImageState extends State<_RetryableCachedImage> {
  bool _isRetrying = false;

  Future<void> _retryImage() async {
    setState(() {
      _isRetrying = true;
    });

    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult != ConnectivityResult.none) {
      // Clear cached image and retry loading
      await CachedNetworkImage.evictFromCache(widget.imageUrl);
      setState(() {
        _isRetrying = false;
      });
    } else {
      setState(() {
        _isRetrying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Retry failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isRetrying
        ? const Center(child: CircularProgressIndicator())
        : CachedNetworkImage(
      imageUrl: widget.imageUrl,
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => GestureDetector(
        onTap: _retryImage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 50),
            const SizedBox(height: 10),
            const Text('Tap to Retry', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }
}