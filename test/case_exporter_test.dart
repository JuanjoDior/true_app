import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_exporter.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/case_timeline_event.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

CaseDraft publishableDraft({
  String title = 'El caso del faro',
  List<DraftLink> links = const <DraftLink>[],
  List<DraftPhoto> photos = const <DraftPhoto>[],
  String? summary = 'Un resumen editorial del caso.',
}) {
  return CaseDraft(
    draftId: 'draft-1',
    title: title,
    category: CaseCategory.unsolved,
    year: 1974,
    status: CaseStatus.open,
    country: 'España',
    countryCode: 'es',
    regionOrCity: 'Cuenca',
    latitude: 40.07,
    longitude: -2.13,
    summary: summary,
    links: links,
    photos: photos,
  );
}

void main() {
  group('caseSlug', () {
    test('turns an editorial title into a URL-safe slug', () {
      expect(caseSlug('El caso del faro'), 'el-caso-del-faro');
    });

    test('strips accents and diacritics', () {
      expect(caseSlug('La mujer de Isdal'), 'la-mujer-de-isdal');
      expect(caseSlug('Asesinato en Alcàsser'), 'asesinato-en-alcasser');
      expect(caseSlug('El Niño de la Mañana'), 'el-nino-de-la-manana');
    });

    test('collapses punctuation and surrounding whitespace', () {
      expect(caseSlug('  ¿Quién mató a  J.F.K.?  '), 'quien-mato-a-j-f-k');
      expect(caseSlug('Caso Borden — 1892'), 'caso-borden-1892');
    });

    test('falls back to a placeholder when nothing survives', () {
      expect(caseSlug('¿¡...!?'), 'caso-sin-titulo');
      expect(caseSlug(''), 'caso-sin-titulo');
    });
  });

  group('draftToCaseJson', () {
    test('maps every published field from the draft', () {
      final json = draftToCaseJson(publishableDraft());

      expect(json['id'], 'el-caso-del-faro');
      expect(json['slug'], 'el-caso-del-faro');
      expect(json['title'], 'El caso del faro');
      expect(json['category'], CaseCategory.unsolved.name);
      expect(json['country'], 'España');
      expect(json['regionOrCity'], 'Cuenca');
      expect(json['year'], 1974);
      expect(json['latitude'], 40.07);
      expect(json['longitude'], -2.13);
      expect(json['summary'], 'Un resumen editorial del caso.');
      expect(json['status'], CaseStatus.open.name);
      expect(json['tags'], isEmpty);
      expect(json['sources'], isEmpty);
      // Sin víctima descrita no se emite la clave.
      expect(json.containsKey('victim'), isFalse);
    });

    test('rounds the coordinates to a sane precision', () {
      // Marcar un punto en el mapa da quince decimales de precisión falsa, y
      // el catálogo se lee a mano. Cinco decimales ya es aproximadamente un
      // metro.
      final draft = publishableDraft().copyWith(
        latitude: 42.880641407613595,
        longitude: -8.54761356221817,
      );

      final json = draftToCaseJson(draft);

      expect(json['latitude'], 42.88064);
      expect(json['longitude'], -8.54761);
    });

    test('leaves already short coordinates untouched', () {
      final json = draftToCaseJson(publishableDraft());

      expect(json['latitude'], 40.07);
      expect(json['longitude'], -2.13);
    });

    test('normalises the country code to upper case', () {
      final json = draftToCaseJson(publishableDraft());

      expect(json['countryCode'], 'ES');
    });

    test('produces a case the app can actually load back', () {
      final draft = publishableDraft(
        links: const [
          DraftLink(
            title: 'Serial',
            url: 'https://example.com/serial',
            kind: DraftLinkKind.podcast,
          ),
        ],
      );

      // Contrato real: lo exportado debe volver a entrar por el mismo
      // `fromJson` que lee assets/data/cases.json.
      final restored = TrueCrimeCase.fromJson(draftToCaseJson(draft));

      expect(restored.slug, 'el-caso-del-faro');
      expect(restored.title, 'El caso del faro');
      expect(restored.category, CaseCategory.unsolved);
      expect(restored.latitude, 40.07);
      expect(restored.longitude, -2.13);
      expect(restored.status, CaseStatus.open);
      expect(restored.podcastSources, hasLength(1));
    });

    test('splits links into podcast and investigation sources', () {
      final draft = publishableDraft(
        links: const [
          DraftLink(
            title: 'Serial',
            url: 'https://example.com/serial',
            kind: DraftLinkKind.podcast,
          ),
          DraftLink(
            title: 'Informe forense',
            url: 'https://example.com/informe',
            kind: DraftLinkKind.document,
          ),
        ],
      );

      final restored = TrueCrimeCase.fromJson(draftToCaseJson(draft));

      expect(restored.podcastSources.single.title, 'Serial');
      expect(restored.investigationSources.single.title, 'Informe forense');
    });

    test('drops links without a usable URL', () {
      final draft = publishableDraft(
        links: const [
          DraftLink(title: 'Pendiente', kind: DraftLinkKind.document),
          DraftLink(url: '   ', kind: DraftLinkKind.document),
          DraftLink(url: 'https://example.com/ok', kind: DraftLinkKind.video),
        ],
      );

      final json = draftToCaseJson(draft);

      expect(json['sources'], hasLength(1));
    });

    test('titles a source with its URL when it has no title', () {
      final draft = publishableDraft(
        links: const [
          DraftLink(url: 'https://example.com/ok', kind: DraftLinkKind.video),
        ],
      );

      final restored = TrueCrimeCase.fromJson(draftToCaseJson(draft));

      expect(restored.sources.single.title, 'https://example.com/ok');
    });

    test('carries the photos so the work put into them is not lost', () {
      final draft = publishableDraft(
        photos: const [
          DraftPhoto(
            url: 'https://example.com/foto.jpg',
            caption: 'Fachada del faro',
          ),
          DraftPhoto(url: 'https://example.com/plano.png'),
          DraftPhoto(caption: 'Sin URL, se descarta'),
        ],
      );

      final photos = draftToCaseJson(draft)['photos'] as List<dynamic>;

      expect(photos, hasLength(2));
      expect((photos.first as Map)['url'], 'https://example.com/foto.jpg');
      expect((photos.first as Map)['caption'], 'Fachada del faro');
      // El pie es opcional: no se emite una clave vacía.
      expect((photos.last as Map).containsKey('caption'), isFalse);
    });

    test('carries the victim, tags and timeline of the draft', () {
      final draft = publishableDraft().copyWith(
        victim: 'Al menos 5 víctimas confirmadas',
        tags: const ['1960s', 'ee. uu.'],
        timeline: const [
          DraftTimelineEvent(
            date: '1968–69',
            title: 'Primeros ataques confirmados',
            kind: CaseTimelineKind.initial,
          ),
        ],
      );

      final restored = TrueCrimeCase.fromJson(draftToCaseJson(draft));

      expect(restored.victim, 'Al menos 5 víctimas confirmadas');
      expect(restored.tags, ['1960s', 'ee. uu.']);
      expect(restored.timeline, hasLength(1));
      expect(restored.timeline.single.title, 'Primeros ataques confirmados');
      expect(restored.timeline.single.date, '1968–69');
      expect(restored.timeline.single.kind, CaseTimelineKind.initial);
    });

    test('drops timeline entries that have no title or date', () {
      // Una fila a medio rellenar no debe llegar al catálogo.
      final draft = publishableDraft().copyWith(
        timeline: const [
          DraftTimelineEvent(kind: CaseTimelineKind.initial),
          DraftTimelineEvent(date: '  ', title: '  '),
          DraftTimelineEvent(date: '1969', title: 'Hito real'),
        ],
      );

      final timeline = draftToCaseJson(draft)['timeline'] as List<dynamic>;

      expect(timeline, hasLength(1));
      expect((timeline.single as Map)['title'], 'Hito real');
    });

    test('gives an untyped timeline entry a usable kind', () {
      // `CaseTimelineEvent.fromJson` exige el tipo, así que el export no
      // puede emitirlo vacío.
      final draft = publishableDraft().copyWith(
        timeline: const [DraftTimelineEvent(date: '1969', title: 'Hito')],
      );

      final restored = TrueCrimeCase.fromJson(draftToCaseJson(draft));

      expect(restored.timeline.single.kind, CaseTimelineKind.process);
    });

    test('omits the timeline key entirely when there are none', () {
      final json = draftToCaseJson(publishableDraft());

      expect(json.containsKey('timeline'), isFalse);
    });

    test('omits the photos key entirely when there are none', () {
      final json = draftToCaseJson(publishableDraft());

      expect(json.containsKey('photos'), isFalse);
    });

    test('emits an empty summary rather than null when it is missing', () {
      // `TrueCrimeCase.summary` no admite null.
      final json = draftToCaseJson(publishableDraft(summary: null));

      expect(json['summary'], '');
    });

    test('trims the editorial text fields', () {
      final draft = publishableDraft().copyWith(
        title: '  El caso del faro  ',
        country: '  España ',
        regionOrCity: ' Cuenca ',
        summary: '  Un resumen.  ',
      );

      final json = draftToCaseJson(draft);

      expect(json['title'], 'El caso del faro');
      expect(json['country'], 'España');
      expect(json['regionOrCity'], 'Cuenca');
      expect(json['summary'], 'Un resumen.');
    });
  });

  group('encodeDraftAsCaseJson', () {
    test('produces indented JSON ready to paste into cases.json', () {
      final text = encodeDraftAsCaseJson(publishableDraft());

      expect(text, contains('\n  "slug": "el-caso-del-faro"'));
      expect(jsonDecode(text), isA<Map<String, dynamic>>());
    });

    test('keeps non-ASCII characters readable instead of escaping them', () {
      final text = encodeDraftAsCaseJson(publishableDraft());

      expect(text, contains('España'));
    });
  });
}
