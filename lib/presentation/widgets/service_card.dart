import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

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
            MaterialPageRoute(builder: (context) => service['screen']),
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
                    child: CachedNetworkImage(
                      width: double.infinity,
                      height: double.infinity,
                      imageUrl: imageUrl ?? '',
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                      fit: BoxFit.cover,
                      imageBuilder: (context, imageProvider) => Semantics(
                        label: 'Image of ${service['name']}',
                        child: Image(image: imageProvider, fit: BoxFit.cover),
                      ),
                      fadeInDuration: const Duration(milliseconds: 200),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Padding(
                  padding:  EdgeInsets.symmetric(horizontal: paddingHorizontal),
                  child: Text(
                    service['name'],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
