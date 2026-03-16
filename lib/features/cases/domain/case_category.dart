enum CaseCategory {
  isolatedMurder,
  serialKiller,
  kidnapping,
  unsolved;

  factory CaseCategory.fromJson(String value) {
    return switch (value) {
      'isolatedMurder' => CaseCategory.isolatedMurder,
      'serialKiller' => CaseCategory.serialKiller,
      'kidnapping' => CaseCategory.kidnapping,
      'unsolved' => CaseCategory.unsolved,
      _ => throw ArgumentError.value(value, 'value', 'Unknown case category'),
    };
  }

  String get label {
    return switch (this) {
      CaseCategory.isolatedMurder => 'Asesinatos aislados',
      CaseCategory.serialKiller => 'Asesinos en serie',
      CaseCategory.kidnapping => 'Secuestros',
      CaseCategory.unsolved => 'Casos sin resolver',
    };
  }

  String get shortLabel {
    return switch (this) {
      CaseCategory.isolatedMurder => 'Aislados',
      CaseCategory.serialKiller => 'Serie',
      CaseCategory.kidnapping => 'Secuestros',
      CaseCategory.unsolved => 'Sin resolver',
    };
  }

  String get description {
    return switch (this) {
      CaseCategory.isolatedMurder =>
        'Homicidios aislados con alto impacto social o judicial.',
      CaseCategory.serialKiller =>
        'Series criminales atribuidas a un mismo autor o patrón.',
      CaseCategory.kidnapping =>
        'Desapariciones y secuestros con investigación abierta o cerrada.',
      CaseCategory.unsolved =>
        'Expedientes emblemáticos sin resolución definitiva.',
    };
  }

  List<String> get searchTerms {
    return switch (this) {
      CaseCategory.isolatedMurder => const [
        'asesinatos aislados',
        'asesinato aislado',
        'homicidio',
        'homicidios',
        'isolated murder',
      ],
      CaseCategory.serialKiller => const [
        'asesinos en serie',
        'asesino en serie',
        'serial killer',
        'serial killers',
      ],
      CaseCategory.kidnapping => const [
        'secuestros',
        'secuestro',
        'kidnapping',
        'kidnappings',
      ],
      CaseCategory.unsolved => const [
        'casos sin resolver',
        'sin resolver',
        'unsolved',
        'cold case',
      ],
    };
  }
}
