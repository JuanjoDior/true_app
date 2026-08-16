import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Guardar y abrir la copia de seguridad como FICHERO.
///
/// Existe como interfaz y no como llamada directa al plugin por dos razones: el
/// selector de ficheros no funciona en un test de widget, y el circuito que hay
/// que proteger —que lo guardado vuelva a entrar intacto— es demasiado
/// importante para quedarse sin pruebas.
abstract class DraftsFileTransfer {
  /// Ofrece guardar [contents] con el nombre [fileName].
  ///
  /// Devuelve `false` si la persona cancela.
  Future<bool> save({required String fileName, required String contents});

  /// Pide un fichero y devuelve su texto, o `null` si se cancela.
  Future<String?> pickText();
}

/// Implementación real, sobre `file_picker`.
class FilePickerDraftsFileTransfer implements DraftsFileTransfer {
  const FilePickerDraftsFileTransfer();

  @override
  Future<bool> save({
    required String fileName,
    required String contents,
  }) async {
    final saved = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      mimeType: 'application/json',
      dialogTitle: 'Guardar mi trabajo',
    );
    return saved != null;
  }

  @override
  Future<String?> pickText() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (picked == null) {
      return null;
    }
    // En web no hay rutas de fichero: se leen los bytes.
    final bytes = await picked.readAsBytes();
    // `allowMalformed` porque el fichero lo elige una persona y puede
    // equivocarse: mejor que el códec explique que no vale a que reviente aquí.
    return utf8.decode(bytes, allowMalformed: true);
  }
}

/// Nombre del fichero que se le ofrece a quien guarda.
///
/// Lleva la fecha para que guardar dos veces no sobrescriba lo anterior: quien
/// hace copias todos los días acaba con una por día, que es justo lo que salva
/// cuando se descubre un error una semana después.
String draftsBackupFileName(DateTime now) {
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return 'mis-casos-${now.year}-$month-$day.json';
}
