import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/advertisement_model.dart';
import 'dart:async'; // Added for Timer

class AdvertisementSlider extends StatefulWidget {
  final List<AdvertisementModel> advertisements;
  final double height;
  final Duration autoPlayInterval;
  final bool autoPlay;
  final Function(AdvertisementModel)? onTap;

  const AdvertisementSlider({
    super.key,
    required this.advertisements,
    this.height = 200,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.autoPlay = true,
    this.onTap,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AdvertisementSliderState createState() => _AdvertisementSliderState();
}

class _AdvertisementSliderState extends State<AdvertisementSlider> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoPlay && widget.advertisements.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (mounted && widget.advertisements.length > 1) {
        if (_currentIndex < widget.advertisements.length - 1) {
          _pageController.nextPage(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.advertisements.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8),
                Text(
                  'لا توجد إعلانات',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // PageView للإعلانات
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.advertisements.length,
            itemBuilder: (context, index) {
              final advertisement = widget.advertisements[index];
              return GestureDetector(
                onTap: () {
                  if (widget.onTap != null) {
                    widget.onTap!(advertisement);
                  }
                },
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: advertisement.imageUrl,
                      fit: BoxFit.fill,
                      width: double.infinity,
                      height: widget.height,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.pink[600]!,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'خطأ في تحميل الصورة',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // مؤشرات الصفحات (Dots)
          if (widget.advertisements.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.advertisements.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          // ignore: deprecated_member_use
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
