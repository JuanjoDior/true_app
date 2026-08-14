import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';

// La escritura de borradores se serializa: una edición vieja que termina tarde
// no puede pisar a una más nueva que ya terminó [diseño D4].
//
// LAS ASERCIONES MIRAN LO PERSISTIDO, NO EL ESTADO EN MEMORIA. El estado se
// publica de forma síncrona antes del `await`, así que la mitad en memoria ya
// es correcta hoy y acreditarle el rojo sería falsear la evidencia. Lo que se
// pierde en la carrera es el disco.

/// Store cuya PRIMERA escritura es lenta y la segunda instantánea.
///
/// Ese desfase es el escenario adversario: sin serializar, las dos salen a la
/// vez y la lenta aterriza la última, dejando escrito el estado viejo. Con la
/// cola, la segunda ni siquiera empieza hasta que la primera termina, así que
/// el orden de llegada manda. El banco funciona con las dos implementaciones,
/// que es lo que lo hace una prueba y no una trampa.
class _StaggeredStore implements CaseDraftsStore {
  _StaggeredStore({List<CaseDraft> initial = const []}) : _initial = initial;

  final List<CaseDraft> _initial;

  /// Retardo por índice de llamada; el resto va sin retardo.
  final Map<int, Duration> delays = {
    0: const Duration(milliseconds: 60),
    1: const Duration(milliseconds: 1),
  };

  /// Instantáneas en el orden en que **terminaron**. La última es lo que queda
  /// escrito de verdad.
  final List<List<CaseDraft>> committed = [];

  /// Índices de llamada que deben fallar.
  final Set<int> failAt = {};

  int _started = 0;

  List<CaseDraft>? get lastCommitted =>
      committed.isEmpty ? null : committed.last;

  @override
  Future<List<CaseDraft>> loadDrafts() async => _initial;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    final index = _started++;
    await Future<void>.delayed(delays[index] ?? Duration.zero);
    if (failAt.contains(index)) {
      throw StateError('fallo simulado de escritura #$index');
    }
    committed.add(List.of(drafts));
  }
}

ProviderContainer _containerWith(_StaggeredStore store) {
  final container = ProviderContainer(
    overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('una escritura vieja no pisa a una nueva', () {
    test('the last write to land carries both edits', () async {
      final store = _StaggeredStore(
        initial: const [CaseDraft(draftId: 'draft-a')],
      );
      final container = _containerWith(store);
      final notifier = container.read(caseDraftsProvider.notifier);
      await container.read(caseDraftsProvider.future);

      // Dos ediciones seguidas, como al teclear dos campos antes de que
      // Flutter reconstruya el formulario.
      final first = notifier.editDraft(
        'draft-a',
        (current) => current.copyWith(title: 'Título'),
      );
      final second = notifier.editDraft(
        'draft-a',
        (current) => current.copyWith(year: 1970),
      );
      await Future.wait([first, second]);

      expect(store.lastCommitted!.single.year, 1970);
    });

    test('writes land in the order they were requested', () async {
      final store = _StaggeredStore(
        initial: const [CaseDraft(draftId: 'draft-a')],
      );
      final container = _containerWith(store);
      final notifier = container.read(caseDraftsProvider.notifier);
      await container.read(caseDraftsProvider.future);

      final first = notifier.editDraft(
        'draft-a',
        (current) => current.copyWith(title: 'Primero'),
      );
      final second = notifier.editDraft(
        'draft-a',
        (current) => current.copyWith(title: 'Segundo'),
      );
      await Future.wait([first, second]);

      // Distinta a la anterior: aquélla mira el contenido final, ésta mira la
      // secuencia. Una cola rota puede acertar el final por casualidad.
      expect(
        store.committed.map((snapshot) => snapshot.single.title),
        orderedEquals(const ['Primero', 'Segundo']),
      );
    });

    test('a delete that lands late does not resurrect the draft', () async {
      final store = _StaggeredStore(
        initial: const [
          CaseDraft(draftId: 'draft-a'),
          CaseDraft(draftId: 'draft-b'),
        ],
      );
      final container = _containerWith(store);
      final notifier = container.read(caseDraftsProvider.notifier);
      await container.read(caseDraftsProvider.future);

      final edit = notifier.editDraft(
        'draft-a',
        (current) => current.copyWith(title: 'Título'),
      );
      final removal = notifier.deleteDraft('draft-b');
      await Future.wait([edit, removal]);

      expect(
        store.lastCommitted!.map((draft) => draft.draftId),
        isNot(contains('draft-b')),
      );
    });

    test('a create that lands late does not lose the newer draft', () async {
      final store = _StaggeredStore();
      final container = _containerWith(store);
      final notifier = container.read(caseDraftsProvider.notifier);
      await container.read(caseDraftsProvider.future);

      final first = notifier.createDraft();
      final second = notifier.createDraft();
      await Future.wait([first, second]);

      expect(store.lastCommitted, hasLength(2));
    });
  });

  group('la cola sobrevive a un fallo', () {
    test('a failed save surfaces its error', () async {
      final store = _StaggeredStore(
        initial: const [CaseDraft(draftId: 'draft-a')],
      );
      store.failAt.add(0);
      final container = _containerWith(store);
      final notifier = container.read(caseDraftsProvider.notifier);
      await container.read(caseDraftsProvider.future);

      await expectLater(
        notifier.editDraft(
          'draft-a',
          (current) => current.copyWith(title: 'Título'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'a later mutation still persists after an earlier one failed',
      () async {
        final store = _StaggeredStore(
          initial: const [CaseDraft(draftId: 'draft-a')],
        );
        store.failAt.add(0);
        final container = _containerWith(store);
        final notifier = container.read(caseDraftsProvider.notifier);
        await container.read(caseDraftsProvider.future);

        final failing = notifier.editDraft(
          'draft-a',
          (current) => current.copyWith(title: 'Título'),
        );
        unawaited(failing.catchError((Object _) {}));

        // Se encola sin esperar a que la primera falle: la cola tiene que
        // seguir viva con el error todavía en vuelo.
        await notifier.editDraft(
          'draft-a',
          (current) => current.copyWith(year: 1970),
        );

        expect(store.lastCommitted!.single.year, 1970);
      },
    );
  });
}
