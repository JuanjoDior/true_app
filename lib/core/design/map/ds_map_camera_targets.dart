import 'dart:math' as math;
import 'dart:ui';

import 'ds_map_camera.dart';

enum DsMapLayout { desktop, mobile }

enum DsMapWorldView { desktop, mobileBand, mobileMap }

const double _worldScaleMobileBand = 0.42;
const Offset _worldCenterMobileBand = Offset(680, 190);
const Offset _worldTargetMobileBand = Offset(195, 230);
const double _worldScaleMobileMap = 0.62;
const Offset _worldCenterMobileMap = Offset(560, 180);
const Offset _worldTargetMobileMap = Offset(195, 330);

const double _caseScaleDesktop = 3.4;
const Offset _caseTargetDesktop = Offset(900, 310);
const double _caseScaleMobile = 2.2;
const Offset _caseTargetMobile = Offset(195, 230);

const double _connectionsDesktopFitWidth = 820;
const double _connectionsDesktopFitHeight = 420;
const double _connectionsDesktopPadWidth = 240;
const double _connectionsDesktopPadHeight = 220;
const double _connectionsDesktopScaleMin = 1.2;
const double _connectionsDesktopScaleMax = 3.0;
const Offset _connectionsDesktopTarget = Offset(860, 310);

const double _connectionsMobileFitWidth = 340;
const double _connectionsMobileFitHeight = 200;
const double _connectionsMobilePadWidth = 120;
const double _connectionsMobilePadHeight = 100;
const double _connectionsMobileScaleMin = 0.5;
const double _connectionsMobileScaleMax = 2.2;
const Offset _connectionsMobileTarget = Offset(195, 210);

const double _exploreDesktopFitWidth = 900;
const double _exploreDesktopFitHeight = 560;
const double _exploreDesktopPad = 260;
const double _exploreDesktopScaleMin = 1.4;
const double _exploreDesktopScaleMax = 3.2;
const Offset _exploreDesktopTarget = Offset(520, 470);

const double _exploreMobileFitWidth = 340;
const double _exploreMobileFitHeight = 260;
const double _exploreMobilePad = 120;
const double _exploreMobileScaleMin = 0.6;
const double _exploreMobileScaleMax = 2.4;
const Offset _exploreMobileTarget = Offset(195, 235);

abstract final class DsMapCameraTargets {
  static DsMapCamera world({required DsMapWorldView view}) => switch (view) {
    DsMapWorldView.desktop => const DsMapCamera.world(),
    DsMapWorldView.mobileBand => DsMapCamera.fromFocus(
      sceneCenter: _worldCenterMobileBand,
      viewportTarget: _worldTargetMobileBand,
      scale: _worldScaleMobileBand,
    ),
    DsMapWorldView.mobileMap => DsMapCamera.fromFocus(
      sceneCenter: _worldCenterMobileMap,
      viewportTarget: _worldTargetMobileMap,
      scale: _worldScaleMobileMap,
    ),
  };

  static DsMapCamera focusCase({
    required Offset casePoint,
    required DsMapLayout layout,
  }) => switch (layout) {
    DsMapLayout.desktop => DsMapCamera.fromFocus(
      sceneCenter: casePoint,
      viewportTarget: _caseTargetDesktop,
      scale: _caseScaleDesktop,
    ),
    DsMapLayout.mobile => DsMapCamera.fromFocus(
      sceneCenter: casePoint,
      viewportTarget: _caseTargetMobile,
      scale: _caseScaleMobile,
    ),
  };

  static DsMapCamera connections({
    required Iterable<Offset> points,
    required DsMapLayout layout,
  }) => switch (layout) {
    DsMapLayout.desktop => _fitBounds(
      points,
      fitWidth: _connectionsDesktopFitWidth,
      fitHeight: _connectionsDesktopFitHeight,
      padWidth: _connectionsDesktopPadWidth,
      padHeight: _connectionsDesktopPadHeight,
      scaleMin: _connectionsDesktopScaleMin,
      scaleMax: _connectionsDesktopScaleMax,
      target: _connectionsDesktopTarget,
    ),
    DsMapLayout.mobile => _fitBounds(
      points,
      fitWidth: _connectionsMobileFitWidth,
      fitHeight: _connectionsMobileFitHeight,
      padWidth: _connectionsMobilePadWidth,
      padHeight: _connectionsMobilePadHeight,
      scaleMin: _connectionsMobileScaleMin,
      scaleMax: _connectionsMobileScaleMax,
      target: _connectionsMobileTarget,
    ),
  };

  static DsMapCamera exploreDesktop({required Iterable<Offset> points}) =>
      _fitBounds(
        points,
        fitWidth: _exploreDesktopFitWidth,
        fitHeight: _exploreDesktopFitHeight,
        padWidth: _exploreDesktopPad,
        padHeight: _exploreDesktopPad,
        scaleMin: _exploreDesktopScaleMin,
        scaleMax: _exploreDesktopScaleMax,
        target: _exploreDesktopTarget,
      );

  static DsMapCamera exploreMobile({required Iterable<Offset> points}) =>
      _fitBounds(
        points,
        fitWidth: _exploreMobileFitWidth,
        fitHeight: _exploreMobileFitHeight,
        padWidth: _exploreMobilePad,
        padHeight: _exploreMobilePad,
        scaleMin: _exploreMobileScaleMin,
        scaleMax: _exploreMobileScaleMax,
        target: _exploreMobileTarget,
      );

  // Con comas decimales, `clamp(lo ; hi ; a, b)` es lo, hi y el menor de los ajustes a y b
  static DsMapCamera _fitBounds(
    Iterable<Offset> points, {
    required double fitWidth,
    required double fitHeight,
    required double padWidth,
    required double padHeight,
    required double scaleMin,
    required double scaleMax,
    required Offset target,
  }) {
    final iterator = points.iterator;
    if (!iterator.moveNext()) {
      throw ArgumentError.value(points, 'points', 'must not be empty');
    }
    var minX = iterator.current.dx;
    var maxX = minX;
    var minY = iterator.current.dy;
    var maxY = minY;
    while (iterator.moveNext()) {
      final p = iterator.current;
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    final fit = math.min(
      fitWidth / (maxX - minX + padWidth),
      fitHeight / (maxY - minY + padHeight),
    );
    return DsMapCamera.fromFocus(
      sceneCenter: Offset((minX + maxX) / 2, (minY + maxY) / 2),
      viewportTarget: target,
      scale: fit.clamp(scaleMin, scaleMax),
    );
  }
}
