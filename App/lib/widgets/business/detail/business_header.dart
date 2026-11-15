import 'package:flutter/material.dart';
import '../../../ui/themes/colors.dart';

class BusinessHeader extends StatelessWidget {
  final List<String> images;
  final bool isFavorite;
  final bool isOwner;
  final bool isLogged;
  final bool isLoading;

  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;

  const BusinessHeader({
    super.key,
    required this.images,
    required this.isFavorite,
    required this.isOwner,
    required this.isLogged,
    required this.isLoading,
    required this.onBack,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 320,
          width: double.infinity,
          child: isLoading
              ? Container(
            color: Colors.grey[200],
          )
              : images.isEmpty
              ? Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported,
              size: 80,
              color: Colors.grey,
            ),
          )
              : PageView.builder(
            itemCount: images.length,
            itemBuilder: (_, i) {
              return Image.network(
                images[i],
                fit: BoxFit.cover,
              );
            },
          ),
        ),

        Positioned(
          top: 40,
          left: 16,
          child: CircleAvatar(
            backgroundColor: AppColors.pureWhite,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: onBack,
            ),
          ),
        ),

        if (!isOwner)
          Positioned(
            top: 40,
            right: 16,
            child: CircleAvatar(
              backgroundColor: AppColors.pureWhite,
              child: IconButton(
                icon: Icon(
                  isLogged
                      ? (isFavorite ? Icons.favorite : Icons.favorite_border)
                      : Icons.favorite_border,
                  color: isLogged ? Colors.red : Colors.grey,
                ),
                onPressed: onToggleFavorite,
              ),
            ),
          ),
      ],
    );
  }
}