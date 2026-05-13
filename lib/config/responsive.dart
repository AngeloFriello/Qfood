import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  final double width;
  final double height;
  final Orientation orientation;

  Responsive(this.context)
      : width = MediaQuery.of(context).size.width,
        height = MediaQuery.of(context).size.height,
        orientation = MediaQuery.of(context).orientation;

  // ============================
  // BREAKPOINTS
  // ============================

  static const double mobileBreakpoint = 800;
  static const double tabletBreakpoint = 1200;

  bool get isMobile => width < mobileBreakpoint;
  bool get isTablet =>
      width >= mobileBreakpoint && width < tabletBreakpoint;
  bool get isDesktop => width >= tabletBreakpoint;

  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  bool get isTabletPortrait => isTablet && isPortrait;
  bool get isTabletLandscape => isTablet && isLandscape;

  // ============================================================
  // LARGHEZZE STRUTTURALI
  // ============================================================

  double get contentWidth {
    if (isDesktop) return width * 0.9;
    if (isTabletLandscape) return width * 0.94;
    if (isTabletPortrait) return width * 0.98;
    return width;
  }

  double get sidebarWidth {
    if (isDesktop) return 240;
    if (isTabletLandscape) return 200;
    return 0; // mobile + tablet portrait -> drawer
  }

  double get cartWidth {
    if (isDesktop) return 380;
    if (isTabletLandscape) return 320;
    if (isTabletPortrait) return width * 0.9;
    return width; // mobile fullscreen
  }

  // ============================================================
  // GRID PRODOTTI (POS)
  // ============================================================

  int get gridColumns {
    if (isDesktop) return 5;

    if (isTabletLandscape) return 4;

    if (isTabletPortrait) return 3;

    return 2;
  }

  double get gridSpacing {
    if (isTabletPortrait) return 14;
    return isMobile ? 12 : 16;
  }

  double get productCardHeight {
    if (isDesktop) return 140;

    if (isTabletLandscape) return 135;

    if (isTabletPortrait) return 125;

    return 115;
  }

  // ============================================================
  // HEADER / FOOTER
  // ============================================================

  double get headerHeight {
    if (isTabletPortrait) return 65;
    return isMobile ? 60 : 70;
  }

  double get bottomBarHeight {
    if (isTabletPortrait) return 68;
    return isMobile ? 65 : 70;
  }

  // ============================================================
  // ICON SIZE
  // ============================================================

  double get iconSize {
    if (isDesktop) return 24;
    if (isTabletLandscape) return 22;
    if (isTabletPortrait) return 21;
    return 20;
  }

  // ============================================================
  // PADDING
  // ============================================================

  double get horizontalPadding {
    if (isDesktop) return 20;
    if (isTabletLandscape) return 16;
    if (isTabletPortrait) return 14;
    return 10;
  }

  EdgeInsets get pagePadding {
    if (isMobile) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
    }

    if (isTabletPortrait) {
      return const EdgeInsets.symmetric(horizontal: 18, vertical: 16);
    }

    return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
  }

  // ============================================================
  // FONT SCALE
  // ============================================================

  double get titleSize {
    if (isDesktop) return 22;
    if (isTabletLandscape) return 10;
    if (isTabletPortrait) return 19;
    return 18;
  }

  double get bodySize {
    if (isDesktop) return 16;
    if (isTabletLandscape) return 13;
    if (isTabletPortrait) return 14.5;
    return 14;
  }
}

extension ResponsiveExtension on BuildContext {
  Responsive get r => Responsive(this);
}