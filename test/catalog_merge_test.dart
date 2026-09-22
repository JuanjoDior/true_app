import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_exporter.dart';
import 'package:true_app/features/cases/data/local_cases_repository.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/case_timeline_event.dart';

/// Borrador mínimo publicable, con los campos que exige `validateDraft` en la
/// intención real, para ejercitar `mergeDraftsIntoCatalog` con datos creíbles.
CaseDraft publishableDraft({
  String title = 'El caso del faro',
  int? featuredRank,
  int? relevanceRank,
  List<DraftTimelineEvent> timeline = const <DraftTimelineEvent>[],
  List<DraftPhoto> photos = const <DraftPhoto>[],
  CaseChapters chapters = const CaseChapters(),
}) {
  return CaseDraft(
    draftId: 'draft-1',
    title: title,
    category: CaseCategory.unsolved,
    year: 1974,
    status: CaseStatus.open,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'Cuenca',
    latitude: 40.07,
    longitude: -2.13,
    summary: 'Un resumen editorial del caso.',
    featuredRank: featuredRank,
    relevanceRank: relevanceRank,
    timeline: timeline,
    photos: photos,
    chapters: chapters,
  );
}

/// Entrada de catálogo mínima pero completa: decodifica sin errores por
/// `TrueCrimeCase.fromJson`, como cualquier entrada real de `cases.json`.
Map<String, dynamic> catalogCase({
  required String slug,
  String? title,
  Map<String, dynamic> extra = const <String, dynamic>{},
}) {
  return {
    'id': slug,
    'slug': slug,
    'title': title ?? slug,
    'category': 'unsolved',
    'country': 'España',
    'countryCode': 'ES',
    'regionOrCity': 'Cuenca',
    'year': 1990,
    'latitude': 40.0,
    'longitude': -3.0,
    'summary': 'Resumen.',
    'tags': <String>[],
    'status': 'open',
    'sources': <Map<String, dynamic>>[],
    ...extra,
  };
}

void main() {
  group('mergeDraftsIntoCatalog — non-colliding append', () {
    test('appends a selected draft and leaves existing entries unchanged', () {
      final existing = catalogCase(slug: 'caso-existente', title: 'Caso existente');
      final draft = publishableDraft(title: 'El caso del faro');

      final result = mergeDraftsIntoCatalog(
        catalog: [existing],
        drafts: [draft],
      );

      expect(result.cases, hasLength(2));
      expect(identical(result.cases.first, existing), isTrue);
      expect(result.cases.last['slug'], 'el-caso-del-faro');
      expect(result.cases.last['title'], 'El caso del faro');
      expect(result.entries.single.outcome, CatalogMergeOutcome.added);
      expect(result.entries.single.slug, 'el-caso-del-faro');
    });
  });

  group('mergeDraftsIntoCatalog — droppedKeys reporting', () {
    test(
      'reports outcome, replacedTitle and droppedKeys when replacing a richer entry',
      () {
        final richEntry = catalogCase(
          slug: 'zodiac-like',
          title: 'Caso publicado',
          extra: const {'statusLabel': 'Sin resolver', 'featuredRank': 2},
        );
        final draft = publishableDraft(title: 'Zodiac Like');

        final result = mergeDraftsIntoCatalog(
          catalog: [richEntry],
          drafts: [draft],
        );

        final entry = result.entries.single;
        expect(entry.outcome, CatalogMergeOutcome.replaced);
        expect(entry.replacedTitle, 'Caso publicado');
        expect(entry.droppedKeys, containsAll(['statusLabel', 'featuredRank']));
      },
    );

    test('reports no droppedKeys when the replacement drops nothing', () {
      final entry = catalogCase(slug: 'known-case', title: 'Publicado');
      final draft = publishableDraft(title: 'Known Case');

      final result = mergeDraftsIntoCatalog(catalog: [entry], drafts: [draft]);

      expect(result.entries.single.droppedKeys, isEmpty);
    });
  });

  group('mergeDraftsIntoCatalog — round-trip safety', () {
    test(
      'round-trips preserved, replaced and merged entries through the published decoder',
      () {
        final catalog = [
          catalogCase(slug: 'case-a', title: 'Caso A'),
          catalogCase(slug: 'case-b', title: 'Caso B'),
          catalogCase(slug: 'known-case', title: 'Caso reemplazado'),
        ];
        final richDraft = publishableDraft(
          title: 'El caso del faro',
          featuredRank: 3,
          relevanceRank: 2,
          timeline: const [
            DraftTimelineEvent(
              date: '1990',
              title: 'Hito',
              kind: CaseTimelineKind.initial,
            ),
          ],
          photos: const [
            DraftPhoto(url: 'https://example.com/foto.jpg', caption: 'Pie'),
          ],
          chapters: const CaseChapters(background: 'Contexto editorial.'),
        );
        final replacingDraft = publishableDraft(title: 'Known Case');

        final result = mergeDraftsIntoCatalog(
          catalog: catalog,
          drafts: [richDraft, replacingDraft],
        );
        final decoded = LocalCasesRepository.parseCasesJson(
          encodeMergedCatalog(result),
        );

        expect(decoded, hasLength(4));

        final restoredNew = decoded.firstWhere(
          (c) => c.slug == 'el-caso-del-faro',
        );
        expect(restoredNew.timeline, hasLength(1));
        expect(restoredNew.photos, hasLength(1));
        expect(restoredNew.chapters.background, 'Contexto editorial.');
        expect(restoredNew.featuredRank, 3);
        expect(restoredNew.relevanceRank, 2);

        final restoredReplaced = decoded.firstWhere(
          (c) => c.slug == 'known-case',
        );
        expect(restoredReplaced.title, 'Known Case');

        final restoredPreserved = decoded.firstWhere((c) => c.slug == 'case-a');
        expect(restoredPreserved.title, 'Caso A');
      },
    );
  });

  group('encodeMergedCatalog', () {
    test('encodes with two-space indentation and unescaped accents', () {
      final catalog = [catalogCase(slug: 'anoranza', title: 'Añoranza')];

      final result = mergeDraftsIntoCatalog(catalog: catalog, drafts: const []);
      final text = encodeMergedCatalog(result);

      expect(text, contains('\n    "slug": "anoranza"'));
      // El acento viaja sin escapar: si `JsonEncoder` lo escapase, esta
      // cadena literal no aparecería en el texto producido.
      expect(text, contains('Añoranza'));
    });
  });

  group('decodeCatalogPayload — malformed payload guard', () {
    test('throws FormatException instead of returning an empty list', () {
      expect(
        () => decodeCatalogPayload('{"not": "a list"}'),
        throwsFormatException,
      );
      expect(
        () => decodeCatalogPayload('not json at all'),
        throwsFormatException,
      );
      expect(
        () => decodeCatalogPayload(jsonEncode([1, 2, 3])),
        throwsFormatException,
      );
    });
  });

  group('real-asset characterization (canary, not TDD evidence)', () {
    test('reproduces the real published asset unchanged when merging nothing', () async {
      final payload = await File('assets/data/cases.json').readAsString();

      final result = mergeDraftsIntoCatalog(
        catalog: decodeCatalogPayload(payload),
        drafts: const [],
      );

      expect(encodeMergedCatalog(result), payload);
    });
  });
}
