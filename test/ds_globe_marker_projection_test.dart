import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_globe_scene_test_support.dart';

// Calculados a mano con R' = 403, P = 2200 y la cámara de portada (centro 1010, 520).
const Offset _facingScreen = Offset(1010, 520);
const Offset _eastScreen = Offset(1249.4932322417164, 520);
const double _facingPerspective = 1.2242626599888704;
const double _normalDiameter = 12;
const double _selectedDiameter = 18;

List<DsGlobePlacedMarker> _place({
  List<DsMapMarker> markers = sampleMarkers,
  DsGlobeCamera? camera,
  String? selectedId,
  Set<String> relatedIds = const {},
  Set<String>? matchingIds,
  int? timelineYear,
}) => DsGlobeMarkerProjection.place(
  markers: markers,
  camera: camera ?? coverCamera,
  selectedId: selectedId,
  relatedIds: relatedIds,
  matchingIds: matchingIds,
  timelineYear: timelineYear,
);

DsMapMarkerPlacement _placement(List<DsGlobePlacedMarker> placed, String id) =>
    placed.firstWhere((p) => p.placement.marker.id == id).placement;

List<String> _ids(List<DsGlobePlacedMarker> placed) => [
  for (final p in placed) p.placement.marker.id,
];

void main() {
  group('position', () {
    test('matches DsGlobeMath.project of the R+3 surface point', () {
      for (final marker in sampleMarkers.where((m) => m.id != 'back')) {
        final expected = projectMarker(marker, coverCamera).screen;
        final center = _placement(_place(), marker.id).center;
        expect((center - expected).distance, lessThan(tolerance));
      }
    });

    test('is hand-computed for known coordinates', () {
      final placed = _place();
      expect(_placement(placed, 'facing').center, _facingScreen);
      expect(
        (_placement(placed, 'east').center - _eastScreen).distance,
        lessThan(tolerance),
      );
    });

    test('the targeted marker sits at the camera center when facing it', () {
      for (final (lat, lon) in [(0.0, 0.0), (40.0, -74.0), (-33.0, 151.0)]) {
        final marker = DsMapMarker(
          id: 'target',
          label: 'Target',
          latitude: lat,
          longitude: lon,
          color: const Color(0xFFE5484D),
          year: 2000,
        );
        for (final camera in [
          DsGlobeCameraTargets.cover(
            latitude: lat,
            longitude: lon,
            currentGy: 0,
          ),
          DsGlobeCameraTargets.explore(
            latitude: lat,
            longitude: lon,
            currentGy: 0,
          ),
        ]) {
          final center = _placement(
            _place(markers: [marker], camera: camera),
            'target',
          ).center;
          expect((center - camera.center).distance, lessThan(tolerance));
        }
      }
    });

    test('follows the camera orientation', () {
      final turned = coverCamera.copyWith(gy: -30);
      final center = _placement(_place(camera: turned), 'east').center;
      expect((center - _facingScreen).distance, lessThan(tolerance));
    });
  });

  group('back faces', () {
    test('a back-facing marker is not placed', () {
      expect(_ids(_place()), isNot(contains('back')));
      expect(projectMarker(back, coverCamera).isFront, isFalse);
    });

    test('a marker comes back when the globe turns toward it', () {
      final turned = DsGlobeCameraTargets.cover(
        latitude: back.latitude,
        longitude: back.longitude,
        currentGy: 0,
      );
      expect(_ids(_place(camera: turned)), contains('back'));
      expect(_ids(_place(camera: turned)), isNot(contains('facing')));
    });
  });

  group('diameter', () {
    test('is scaled by camera.scale and the perspective factor', () {
      final placed = _place();
      expect(
        _placement(placed, 'facing').visual.diameter,
        closeTo(_normalDiameter * _facingPerspective, tolerance),
      );
      final facingExplore = DsGlobeCameraTargets.explore(
        latitude: 0,
        longitude: 0,
        currentGy: 0,
      );
      final factor = projectMarker(facing, facingExplore).perspectiveFactor;
      expect(factor, lessThan(_facingPerspective));
      expect(
        _placement(_place(camera: facingExplore), 'facing').visual.diameter,
        closeTo(_normalDiameter * facingExplore.scale * factor, tolerance),
      );
    });

    test('the selected marker keeps its 18 / 12 ratio', () {
      final placed = _place(selectedId: 'facing');
      expect(
        _placement(placed, 'facing').visual.diameter,
        closeTo(_selectedDiameter * _facingPerspective, tolerance),
      );
    });

    test('is smaller toward the limb than at the center', () {
      final placed = _place();
      expect(
        _placement(placed, 'facing').visual.diameter,
        greaterThan(_placement(placed, 'near-limb').visual.diameter),
      );
    });
  });

  group('state rules (same as the flat layout)', () {
    test('without selection every placed marker is fully visible', () {
      for (final p in _place()) {
        expect(p.placement.visual.opacity, 1);
        expect(p.placement.selected, isFalse);
        expect(p.placement.related, isFalse);
      }
    });

    test('selection dims the rest and related keeps the gold border', () {
      final placed = _place(selectedId: 'facing', relatedIds: const {'east'});
      expect(_placement(placed, 'facing').selected, isTrue);
      expect(_placement(placed, 'facing').visual.opacity, 1);
      expect(_placement(placed, 'east').related, isTrue);
      expect(_placement(placed, 'east').visual.goldBorder, isTrue);
      expect(_placement(placed, 'east').visual.showLabel, isTrue);
      expect(_placement(placed, 'east').visual.opacity, 1);
      expect(_placement(placed, 'near-limb').visual.opacity, 0.4);
    });

    test('a selected marker is never related', () {
      final placed = _place(selectedId: 'facing', relatedIds: const {'facing'});
      expect(_placement(placed, 'facing').related, isFalse);
      expect(_placement(placed, 'facing').visual.goldBorder, isFalse);
    });

    test('markers outside the filter are nearly transparent', () {
      final placed = _place(matchingIds: const {'facing'});
      expect(_placement(placed, 'facing').visual.opacity, 1);
      expect(_placement(placed, 'east').visual.opacity, 0.12);
    });

    test('a null matchingIds matches everything', () {
      expect(_placement(_place(), 'east').visual.opacity, 1);
    });

    test('markers after the timeline year are not placed', () {
      expect(_ids(_place(timelineYear: 1990)), ['facing', 'east']);
      expect(_ids(_place(timelineYear: 1900)), isEmpty);
      expect(_ids(_place(timelineYear: null)), hasLength(4));
    });

    test('visuals equal the flat resolver except for the diameter', () {
      final placed = _place(
        selectedId: 'east',
        relatedIds: const {'facing'},
        matchingIds: const {'east', 'facing'},
      );
      for (final p in placed) {
        final id = p.placement.marker.id;
        final flat = DsMapMarkerStates.resolve(
          selected: id == 'east',
          related: id == 'facing',
          matchesFilter: id == 'east' || id == 'facing',
          shownByYear: true,
          hasSelection: true,
          mobile: false,
        );
        final visual = p.placement.visual;
        expect(visual.opacity, flat.opacity);
        expect(visual.glowRadius, flat.glowRadius);
        expect(visual.showLabel, flat.showLabel);
        expect(visual.goldBorder, flat.goldBorder);
        expect(visual.pulsing, flat.pulsing);
        expect(visual.interactive, flat.interactive);
      }
    });
  });

  group('paint order', () {
    test('keeps list order when nothing is selected', () {
      expect(_ids(_place()), ['facing', 'east', 'near-limb', 'limb']);
    });

    test('plain, then related, then selected', () {
      final placed = _place(selectedId: 'facing', relatedIds: const {'east'});
      expect(_ids(placed), ['near-limb', 'limb', 'east', 'facing']);
    });
  });

  group('label visibility', () {
    test('requires z2 above 40, not just a front face', () {
      final placed = _place();
      bool visible(String id) =>
          placed.firstWhere((p) => p.placement.marker.id == id).labelVisible;
      expect(visible('facing'), isTrue);
      expect(visible('near-limb'), isTrue);
      expect(visible('limb'), isFalse);
      expect(projectMarker(limb, coverCamera).isFront, isTrue);
    });
  });

  test('an empty marker list yields nothing', () {
    expect(_place(markers: const []), isEmpty);
  });
}
