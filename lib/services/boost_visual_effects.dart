import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

class BoostVisualEffects {
  // Apply visual boost effects to marketplace cards
  static Widget applyBoostEffects({
    required Widget child,
    required List<String> activeBoostTypes,
    bool isInSmartRecommendations = false,
    bool applyRandomSingle = false,
  }) {
    if (activeBoostTypes.isEmpty) return child;

    Widget wrappedChild = child;

    // If applyRandomSingle is true and there are multiple boosts, select only one
    final List<String> finalBoostTypes;
    if (applyRandomSingle && activeBoostTypes.length > 1) {
      final random = math.Random();
      final randomIndex = random.nextInt(activeBoostTypes.length);
      finalBoostTypes = [activeBoostTypes[randomIndex]];
    } else {
      finalBoostTypes = activeBoostTypes;
    }

    // Apply effects in layers
    for (String boostType in finalBoostTypes) {
      wrappedChild = _applyBoostEffect(wrappedChild, boostType, isInSmartRecommendations);
    }

    return wrappedChild;
  }

  static Widget _applyBoostEffect(Widget child, String boostType, bool isInSmartRecommendations) {
    switch (boostType) {
      // 🔖 Classic Badge Boosts
      case 'new_badge':
        return _addNewBadge(child, isInSmartRecommendations);
      case 'discount_badge':
        return _addDiscountBadge(child, isInSmartRecommendations);
      case 'negotiable_badge':
        return _addNegotiableBadge(child, isInSmartRecommendations);
      case 'delivery_badge':
        return _addDeliveryBadge(child, isInSmartRecommendations);
      case 'popular_badge':
        return _addPopularBadge(child, isInSmartRecommendations);

      // 🟩 Border/Outline Boosts
      case 'colored_border':
        return _addColoredBorder(child, isInSmartRecommendations);
      case 'animated_border':
        return _addAnimatedBorder(child, isInSmartRecommendations);
      case 'glow_effect':
        return _addGlowEffect(child, isInSmartRecommendations);

      // ⚡ Dynamic/Impact Boosts
      case 'pulsing_card':
        return _addPulsingEffect(child, isInSmartRecommendations);
      case 'shimmer_label':
        return _addShimmerLabel(child, isInSmartRecommendations);
      case 'bounce_load':
        return _addBounceEffect(child, isInSmartRecommendations);

      // 🧩 Creative/Unique Boosts
      case 'triangle_corner':
        return _addTriangleCorner(child, isInSmartRecommendations);
      case 'orbital_star':
        return _addOrbitalStar(child, isInSmartRecommendations);
      case 'hologram_effect':
        return _addHologramEffect(child, isInSmartRecommendations);
      case 'light_ray':
        return _addLightRay(child, isInSmartRecommendations);
      case 'floating_badge':
        return _addFloatingBadge(child, isInSmartRecommendations);
      case 'torn_sticker':
        return _addTornSticker(child, isInSmartRecommendations);
      case 'handwritten_sticker':
        return _addHandwrittenSticker(child, isInSmartRecommendations);

      // Legacy/Alternative boost names
      case 'coloredFrame':
        return _addColoredBorder(child, isInSmartRecommendations);
      case 'animatedBorder':
        return _addAnimatedBorder(child, isInSmartRecommendations);
      case 'labelTags':
        return _addNewBadge(child, isInSmartRecommendations); // Use new badge for label tags

      default:
        return child;
    }
  }

  // 🔖 Classic Badge Effects
  static Widget _addNewBadge(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned(
          top: isInSmartRecommendations ? 4.h : 8.h,
          right: isInSmartRecommendations ? 4.w : 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isInSmartRecommendations ? 6.w : 8.w, 
              vertical: isInSmartRecommendations ? 2.h : 4.h
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: isInSmartRecommendations ? 2 : 4,
                  offset: Offset(0, isInSmartRecommendations ? 1 : 2),
                ),
              ],
            ),
            child: Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: isInSmartRecommendations ? 8.sp : 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _addDiscountBadge(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned(
          top: isInSmartRecommendations ? 4.h : 8.h,
          left: isInSmartRecommendations ? 4.w : 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isInSmartRecommendations ? 6.w : 8.w, 
              vertical: isInSmartRecommendations ? 2.h : 4.h
            ),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: isInSmartRecommendations ? 2 : 4,
                  offset: Offset(0, isInSmartRecommendations ? 1 : 2),
                ),
              ],
            ),
            child: Text(
              '-15%',
              style: TextStyle(
                color: Colors.white,
                fontSize: isInSmartRecommendations ? 8.sp : 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _addNegotiableBadge(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned(
          bottom: isInSmartRecommendations ? 4.h : 8.h,
          right: isInSmartRecommendations ? 4.w : 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isInSmartRecommendations ? 5.w : 8.w, 
              vertical: isInSmartRecommendations ? 2.h : 4.h
            ),
            decoration: BoxDecoration(
              color: Colors.yellow.shade700,
              borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.3),
                  blurRadius: isInSmartRecommendations ? 2 : 4,
                  offset: Offset(0, isInSmartRecommendations ? 1 : 2),
                ),
              ],
            ),
            child: Text(
              isInSmartRecommendations ? 'NEG' : 'NEGOTIABLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: isInSmartRecommendations ? 7.sp : 9.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _addDeliveryBadge(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned(
          bottom: isInSmartRecommendations ? 4.h : 8.h,
          left: isInSmartRecommendations ? 4.w : 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isInSmartRecommendations ? 5.w : 8.w, 
              vertical: isInSmartRecommendations ? 2.h : 4.h
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: isInSmartRecommendations ? 2 : 4,
                  offset: Offset(0, isInSmartRecommendations ? 1 : 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isInSmartRecommendations) ...[
                  Icon(Icons.local_shipping, color: Colors.white, size: 12.sp),
                  SizedBox(width: 4.w),
                ],
                Text(
                  isInSmartRecommendations ? 'DEL' : 'DELIVERY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isInSmartRecommendations ? 7.sp : 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _addPopularBadge(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned(
          top: isInSmartRecommendations ? 4.h : 8.h,
          left: isInSmartRecommendations ? 4.w : 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isInSmartRecommendations ? 5.w : 8.w, 
              vertical: isInSmartRecommendations ? 2.h : 4.h
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade600,
              borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: isInSmartRecommendations ? 2 : 4,
                  offset: Offset(0, isInSmartRecommendations ? 1 : 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isInSmartRecommendations) ...[
                  Icon(Icons.local_fire_department, color: Colors.white, size: 12.sp),
                  SizedBox(width: 4.w),
                ],
                Text(
                  isInSmartRecommendations ? 'HOT' : 'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isInSmartRecommendations ? 7.sp : 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🟩 Border/Outline Effects
  static Widget _addColoredBorder(Widget child, bool isInSmartRecommendations) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue.shade400,
          width: isInSmartRecommendations ? 1.5.w : 2.w,
        ),
        borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
      ),
      child: child,
    );
  }

  static Widget _addAnimatedBorder(Widget child, bool isInSmartRecommendations) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(seconds: 2),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Color.lerp(Colors.blue.shade400, Colors.purple.shade400, value)!,
              width: isInSmartRecommendations ? 1.5.w : 2.w,
            ),
            borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget _addGlowEffect(Widget child, bool isInSmartRecommendations) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: isInSmartRecommendations ? 8 : 15,
            spreadRadius: isInSmartRecommendations ? 1 : 2,
          ),
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: isInSmartRecommendations ? 15 : 25,
            spreadRadius: isInSmartRecommendations ? 2 : 4,
          ),
        ],
      ),
      child: child,
    );
  }

  // ⚡ Dynamic/Impact Effects
  static Widget _addPulsingEffect(Widget child, bool isInSmartRecommendations) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.05),
      duration: Duration(seconds: 2),
      builder: (context, value, child) {
        return Transform.scale(
          scale: isInSmartRecommendations ? 
            (value * 0.5 + 0.5) : value, // Reduce pulsing effect for smart feed
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget _addShimmerLabel(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -1.0, end: 1.0),
            duration: Duration(seconds: 3),
            builder: (context, value, child) {
              return Container(
                width: isInSmartRecommendations ? 40.w : 60.w,
                height: isInSmartRecommendations ? 15.h : 20.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [
                      math.max(0.0, value - 0.3),
                      value,
                      math.min(1.0, value + 0.3),
                    ],
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(isInSmartRecommendations ? 0.4 : 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _addBounceEffect(Widget child, bool isInSmartRecommendations) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.bounceOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, isInSmartRecommendations ? 
            -5 * (1 - value) : -10 * (1 - value)), // Reduce bounce for smart feed
          child: child,
        );
      },
      child: child,
    );
  }

  // 🧩 Creative/Unique Effects
  static Widget _addTriangleCorner(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: ClipPath(
            clipper: TriangleClipper(),
            child: Container(
              width: isInSmartRecommendations ? 30.w : 40.w,
              height: isInSmartRecommendations ? 30.h : 40.h,
              color: Colors.red.shade600,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isInSmartRecommendations ? 6.h : 8.h, 
                    right: isInSmartRecommendations ? 6.w : 8.w
                  ),
                  child: Text(
                    'HOT!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isInSmartRecommendations ? 6.sp : 8.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _addOrbitalStar(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 2 * math.pi),
            duration: Duration(seconds: 6),
            builder: (context, value, child) {
              return CustomPaint(
                painter: OrbitalStarPainter(value, isInSmartRecommendations),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _addHologramEffect(Widget child, bool isInSmartRecommendations) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(seconds: 4),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * value, -1 + 2 * value),
              end: Alignment(1 - 2 * value, 1 - 2 * value),
              colors: [
                Colors.transparent,
                Colors.cyan.withOpacity(isInSmartRecommendations ? 0.05 : 0.1),
                Colors.purple.withOpacity(isInSmartRecommendations ? 0.05 : 0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget _addLightRay(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -1.0, end: 1.0),
            duration: Duration(seconds: 3),
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
                child: CustomPaint(
                  painter: LightRayPainter(value),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _addFloatingBadge(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned(
          top: isInSmartRecommendations ? -3.h : -5.h,
          right: isInSmartRecommendations ? -3.w : -5.w,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, isInSmartRecommendations ? 
                  1 * math.sin(value * 2 * math.pi) : 2 * math.sin(value * 2 * math.pi)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isInSmartRecommendations ? 6.w : 8.w, 
                    vertical: isInSmartRecommendations ? 2.h : 4.h
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(isInSmartRecommendations ? 8.r : 12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: isInSmartRecommendations ? 4 : 8,
                        offset: Offset(0, isInSmartRecommendations ? 2 : 4),
                      ),
                    ],
                  ),
                  child: Text(
                    isInSmartRecommendations ? 'PREM' : 'PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isInSmartRecommendations ? 7.sp : 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _addTornSticker(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          child: ClipPath(
            clipper: TornStickerClipper(),
            child: Container(
              width: isInSmartRecommendations ? 45.w : 60.w,
              height: isInSmartRecommendations ? 22.h : 30.h,
              color: Colors.yellow.shade600,
              child: Center(
                child: Text(
                  isInSmartRecommendations ? 'LTD' : 'LIMITED',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: isInSmartRecommendations ? 6.sp : 8.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _addHandwrittenSticker(Widget child, bool isInSmartRecommendations) {
    return Stack(
      children: [
        child,
        Positioned(
          bottom: isInSmartRecommendations ? 4.h : 8.h,
          right: isInSmartRecommendations ? 4.w : 8.w,
          child: Transform.rotate(
            angle: -0.1,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isInSmartRecommendations ? 6.w : 8.w, 
                vertical: isInSmartRecommendations ? 2.h : 4.h
              ),
              decoration: BoxDecoration(
                color: Colors.pink.shade100,
                borderRadius: BorderRadius.circular(isInSmartRecommendations ? 6.r : 8.r),
                border: Border.all(color: Colors.pink.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                'Special ✨',
                style: TextStyle(
                  color: Colors.pink.shade700,
                  fontSize: isInSmartRecommendations ? 7.sp : 9.sp,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom clippers and painters
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TornStickerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 5);
    path.lineTo(size.width - 10, 0);
    path.lineTo(size.width, 8);
    path.lineTo(size.width - 5, size.height);
    path.lineTo(5, size.height - 3);
    path.lineTo(0, size.height - 8);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class OrbitalStarPainter extends CustomPainter {
  final double angle;
  final bool isInSmartRecommendations;

  OrbitalStarPainter(this.angle, this.isInSmartRecommendations);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.shade600
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * (isInSmartRecommendations ? 0.3 : 0.4);
    
    final starX = center.dx + radius * math.cos(angle);
    final starY = center.dy + radius * math.sin(angle);

    // Draw star with adjusted size
    final starSize = isInSmartRecommendations ? 2.0 : 3.0;
    canvas.drawCircle(Offset(starX, starY), starSize, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class LightRayPainter extends CustomPainter {
  final double progress;

  LightRayPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final rayX = size.width * progress;
    
    path.moveTo(rayX - 20, 0);
    path.lineTo(rayX + 20, 0);
    path.lineTo(rayX + 30, size.height);
    path.lineTo(rayX - 10, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
