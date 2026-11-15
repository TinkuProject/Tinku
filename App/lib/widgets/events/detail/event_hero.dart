import 'package:flutter/material.dart';
import '../../../models/media_model.dart';
import '../../common/image_carousel.dart';

class EventHero extends StatelessWidget {
  final String title;
  final List<MediaModel> medias;
  final bool isLoading;

  const EventHero({
    super.key,
    required this.title,
    required this.medias,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: SizedBox(
            height: 320,
            width: double.infinity,
            child: isLoading
                ? Container(color: Colors.grey[200])
                : medias.isEmpty
                ? _errorImage()
                : (medias.length == 1
                ? Image.network(
              medias.first.url,
              height: 320,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : ImageCarousel(medias: medias)),
          ),
        ),

        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorImage() {
    return Container(
      height: 300,
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 80),
    );
  }
}