import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/drafts_backup.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/presentation/intake/drafts_backup_button.dart';

/// El circuito completo de copia de seguridad, tal y como lo usa una persona:
/// copiar al portapapeles y volver a meterlo pegándolo.
///
/// Se prueba el circuito ENTERO y no las piezas por separado porque lo que
/// puede fallar es el cable: un códec perfecto y un notifier perfecto no sirven
/// de nada si el botón no los une.

class _FakeStore implements CaseDraftsStore {
  _FakeStore(this._drafts);

  List<CaseDraft> _drafts;

  @override
  Future<List<CaseDraft>> loadDrafts() async => _drafts;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async => _drafts = drafts;

  List<CaseDraft> get saved => _drafts;
}

/// Portapapeles falso: el real no existe en tests.
String? _clipboard;

void _interceptClipboard(WidgetTester tester) {
  _clipboard = null;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        _clipboard = (call.arguments as Map)['text'] as String;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

Future<(ProviderContainer, _FakeStore)> _pumpButton(
  WidgetTester tester,
  List<CaseDraft> drafts,
) async {
  _interceptClipboard(tester);
  final store = _FakeStore(drafts);
  final container = ProviderContainer(
    overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  await container.read(caseDraftsProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: Center(child: DraftsBackupButton())),
      ),
    ),
  );
  await tester.pump();
  return (container, store);
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('drafts-backup-button')));
  await tester.pumpAndSettle();
}

void main() {
  group('copiar', () {
    testWidgets('the backup is available even for an unfinished draft', (
      tester,
    ) async {
      // El caso de uso entero: un caso recién empezado, sin nada obligatorio
      // relleno. El botón de exportar caso estaría deshabilitado aquí.
      await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-a', title: 'A medias'),
      ]);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-copy')));
      await tester.pumpAndSettle();

      expect(decodeDraftsBackup(_clipboard!).drafts.single.title, 'A medias');
    });

    testWidgets('every draft goes into the backup', (tester) async {
      await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-a'),
        CaseDraft(draftId: 'draft-b'),
        CaseDraft(draftId: 'draft-c'),
      ]);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-copy')));
      await tester.pumpAndSettle();

      expect(decodeDraftsBackup(_clipboard!).drafts, hasLength(3));
    });
  });

  group('restaurar', () {
    testWidgets('pasting a backup brings its drafts back', (tester) async {
      final backup = encodeDraftsBackup(const [
        CaseDraft(draftId: 'draft-rescued', title: 'Rescatado'),
      ]);
      final (_, store) = await _pumpButton(tester, const []);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-restore')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('drafts-restore-field')),
        backup,
      );
      await tester.tap(find.byKey(const Key('drafts-restore-confirm')));
      await tester.pumpAndSettle();

      // Persistido, no sólo en pantalla: si no llega al disco, restaurar y
      // cerrar el navegador pierde justo lo que se acaba de recuperar.
      expect(store.saved.single.title, 'Rescatado');
    });

    testWidgets('restoring keeps what was already there', (tester) async {
      final backup = encodeDraftsBackup(const [
        CaseDraft(draftId: 'draft-rescued', title: 'Rescatado'),
      ]);
      final (_, store) = await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-local', title: 'Hecho después'),
      ]);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-restore')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('drafts-restore-field')),
        backup,
      );
      await tester.tap(find.byKey(const Key('drafts-restore-confirm')));
      await tester.pumpAndSettle();

      expect(
        store.saved.map((draft) => draft.draftId),
        containsAll(const ['draft-local', 'draft-rescued']),
      );
    });

    testWidgets('pasting nonsense changes nothing', (tester) async {
      final (_, store) = await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-local', title: 'Local'),
      ]);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-restore')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('drafts-restore-field')),
        'esto no es una copia',
      );
      await tester.tap(find.byKey(const Key('drafts-restore-confirm')));
      await tester.pumpAndSettle();

      expect(store.saved.single.title, 'Local');
    });

    testWidgets('pasting nonsense says why', (tester) async {
      await _pumpButton(tester, const []);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-restore')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('drafts-restore-field')),
        'esto no es una copia',
      );
      await tester.tap(find.byKey(const Key('drafts-restore-confirm')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('cancelling changes nothing', (tester) async {
      final (_, store) = await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-local', title: 'Local'),
      ]);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-restore')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(store.saved.single.title, 'Local');
    });
  });

  group('el circuito entero', () {
    testWidgets('a draft copied out and pasted back survives intact', (
      tester,
    ) async {
      // La prueba que de verdad importa: sacar el trabajo y volver a meterlo
      // en un equipo vacío, que es lo que hará Iván al cambiar de ordenador.
      await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-a', title: 'Investigación en curso'),
      ]);
      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-copy')));
      await tester.pumpAndSettle();
      final exported = _clipboard!;

      final (_, freshStore) = await _pumpButton(tester, const []);
      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-restore')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('drafts-restore-field')),
        exported,
      );
      await tester.tap(find.byKey(const Key('drafts-restore-confirm')));
      await tester.pumpAndSettle();

      expect(freshStore.saved.single.title, 'Investigación en curso');
    });
  });
}
