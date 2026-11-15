import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../models/media_model.dart';
import '../../../ui/themes/colors.dart';

class ImageCarousel extends StatefulWidget {
  final List<MediaModel> medias;
  final double height;

  const ImageCarousel({
    super.key,
    required this.medias,
    this.height = 300,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  bool get _hasImages => widget.medias.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _setupAutoPlay();
  }

  @override
  void didUpdateWidget(covariant ImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.medias != widget.medias) {
      _currentPage = 0;
      _setupAutoPlay();
    }
  }

  void _setupAutoPlay() {
    _stopAutoPlay();

    if (_hasImages && widget.medias.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || !_pageController.hasClients) return;

        _currentPage =
            (_currentPage + 1) % widget.medias.length;

        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  Widget _fallback() {
    return Container(
      color: AppColors.surfaceSoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.image,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasImages) {
      return SizedBox(
        height: widget.height,
        child: _fallback(),
      );
    }

    return SizedBox(
      height: widget.height,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction != ScrollDirection.idle) {
            _stopAutoPlay();
          } else if (widget.medias.length > 1) {
            _setupAutoPlay();
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.medias.length,
          onPageChanged: (index) {
            _currentPage = index;
          },
          itemBuilder: (context, index) {
            return Image.network(
              widget.medias[index].url,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            );
          },
        ),
      ),
    );
  }
}