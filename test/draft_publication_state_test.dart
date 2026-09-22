import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/draft_publication_state.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';

const _validDraft = CaseDraft(
  draftId: 'draft-1',
  title: 'El caso del faro',
  category: CaseCategory.unsolved,
  year: 1994,
  status: CaseStatus.open,
  country: 'España',
  countryCode: 'ES',
  regionOrCity: 'Cuenca',
  latitude: 40.07,
  longitude: -2.13,
);

void main() {
  test('an incomplete draft always reads incomplete, regardless of markers', () {
    const incompleteDraft = CaseDraft(draftId: 'draft-incompleto');

    expect(
      draftPublicationState(incompleteDraft, publishedSlugs: const {}),
      DraftPublicationState.incomplete,
    );
  });

  test('a valid draft never handed off and unpublished reads ready', () {
    expect(
      draftPublicationState(_validDraft, publishedSlugs: const {}),
      DraftPublicationState.ready,
    );
  });

  test(
    'a valid draft with a handoff marker whose slug is unpublished reads handedOff',
    () {
      final handedOff = _validDraft.markHandedOff(
        slug: 'el-caso-del-faro',
        at: DateTime.utc(2026, 9, 12),
      );

      expect(
        draftPublicationState(handedOff, publishedSlugs: const {}),
        DraftPublicationState.handedOff,
      );
    },
  );

  test(
    'a valid draft whose effective slug is in the published set reads published',
    () {
      expect(
        draftPublicationState(
          _validDraft,
          publishedSlugs: const {'el-caso-del-faro'},
        ),
        DraftPublicationState.published,
      );
    },
  );

  test(
    'handoffSlug wins over the title-derived slug when both are present',
    () {
      // El slug asignado en el lote puede llevar sufijo (-2) y no coincidir
      // con el que produciría el título; sólo el asignado importa aquí.
      final handedOff = _validDraft.markHandedOff(
        slug: 'el-caso-del-faro-2',
        at: DateTime.utc(2026, 9, 12),
      );

      expect(
        draftPublicationState(
          handedOff,
          publishedSlugs: const {'el-caso-del-faro-2'},
        ),
        DraftPublicationState.published,
      );
      expect(
        draftPublicationState(
          handedOff,
          publishedSlugs: const {'el-caso-del-faro'},
        ),
        DraftPublicationState.handedOff,
      );
    },
  );

  test(
    'a pre-change draft with a null marker behaves exactly like a never-handed-off draft',
    () {
      final preChange = CaseDraft.fromJson(_validDraft.toJson());

      expect(preChange.handoffSlug, isNull);
      expect(preChange.handoffAt, isNull);
      expect(
        draftPublicationState(preChange, publishedSlugs: const {}),
        DraftPublicationState.ready,
      );
    },
  );
}
