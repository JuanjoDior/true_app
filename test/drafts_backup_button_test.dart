import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/drafts_backup.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/data/drafts_file_transfer.dart';
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

/// Selector de ficheros falso: el del sistema no existe dentro de un test.
class _FakeFileTransfer implements DraftsFileTransfer {
  String? savedName;
  String? savedContents;

  /// Lo que devolverá el selector. `null` = la persona cancela.
  String? nextPick;
  var cancelSave = false;

  @override
  Future<bool> save({
    required String fileName,
    required String contents,
  }) async {
    if (cancelSave) {
      return false;
    }
    savedName = fileName;
    savedContents = contents;
    return true;
  }

  @override
  Future<String?> pickText() async => nextPick;
}

late _FakeFileTransfer _files;

Future<(ProviderContainer, _FakeStore)> _pumpButton(
  WidgetTester tester,
  List<CaseDraft> drafts,
) async {
  _interceptClipboard(tester);
  _files = _FakeFileTransfer();
  final store = _FakeStore(drafts);
  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(store),
      draftsFileTransferProvider.overrideWithValue(_files),
    ],
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

  group('por fichero, que es como trabajará Iván', () {
    testWidgets('saving writes every draft into the file', (tester) async {
      await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-a', title: 'A medias'),
        CaseDraft(draftId: 'draft-b'),
      ]);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-save-file')));
      await tester.pumpAndSettle();

      expect(decodeDraftsBackup(_files.savedContents!).drafts, hasLength(2));
    });

    testWidgets('the file is named with today\'s date', (tester) async {
      // Guardar dos días seguidos no puede sobrescribir lo de ayer: quien
      // descubre un error una semana después necesita la copia de entonces.
      await _pumpButton(tester, const [CaseDraft(draftId: 'draft-a')]);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-save-file')));
      await tester.pumpAndSettle();

      expect(_files.savedName, draftsBackupFileName(DateTime.now()));
    });

    testWidgets('loading a file brings its drafts in', (tester) async {
      final (_, store) = await _pumpButton(tester, const []);
      _files.nextPick = encodeDraftsBackup(const [
        CaseDraft(draftId: 'draft-de-ivan', title: 'Caso de Iván'),
      ]);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-load-file')));
      await tester.pumpAndSettle();

      expect(store.saved.single.title, 'Caso de Iván');
    });

    testWidgets('loading keeps the work already on this machine', (
      tester,
    ) async {
      final (_, store) = await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-mio', title: 'Lo mío'),
      ]);
      _files.nextPick = encodeDraftsBackup(const [
        CaseDraft(draftId: 'draft-de-ivan', title: 'Caso de Iván'),
      ]);

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-load-file')));
      await tester.pumpAndSettle();

      expect(
        store.saved.map((draft) => draft.draftId),
        containsAll(const ['draft-mio', 'draft-de-ivan']),
      );
    });

    testWidgets('cancelling the file picker changes nothing', (tester) async {
      final (_, store) = await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-mio', title: 'Lo mío'),
      ]);
      _files.nextPick = null;

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-load-file')));
      await tester.pumpAndSettle();

      expect(store.saved.single.title, 'Lo mío');
    });

    testWidgets('a file that is not a backup changes nothing', (tester) async {
      final (_, store) = await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-mio', title: 'Lo mío'),
      ]);
      _files.nextPick = 'esto es otra cosa';

      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-load-file')));
      await tester.pumpAndSettle();

      expect(store.saved.single.title, 'Lo mío');
    });

    testWidgets('the whole handover survives: save here, load there', (
      tester,
    ) async {
      // Iván guarda y te manda el fichero; vos lo abrís en tu equipo.
      await _pumpButton(tester, const [
        CaseDraft(draftId: 'draft-a', title: 'Investigación de Iván'),
      ]);
      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-save-file')));
      await tester.pumpAndSettle();
      final sent = _files.savedContents!;

      final (_, yourStore) = await _pumpButton(tester, const []);
      _files.nextPick = sent;
      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('drafts-backup-load-file')));
      await tester.pumpAndSettle();

      expect(yourStore.saved.single.title, 'Investigación de Iván');
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
