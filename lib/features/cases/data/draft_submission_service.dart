import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'draft_submission.dart';
import 'intake_auth.dart';
import 'supabase_project.dart';

/// Envía UN borrador a revisión con la función SQL `submit_draft_snapshot`.
///
/// Nunca reintenta por su cuenta: cada envío o reintento lo dispara una acción
/// explícita. No serializa llamadas concurrentes de la misma intención; el
/// servidor es idempotente por `submission_id`.
class DraftSubmissionService {
  DraftSubmissionService({
    required IntakeAuth auth,
    required http.Client client,
    this.timeout = kSupabaseNetworkTimeout,
  }) : _auth = auth,
       _client = client;

  final IntakeAuth _auth;
  final http.Client _client;
  final Duration timeout;

  Uri get _rpcUri =>
      Uri.parse('$supabaseUrl/rest/v1/rpc/submit_draft_snapshot');

  Future<DraftSubmissionReceipt> send(DraftSubmission submission) async {
    final token = await _auth.accessTokenForAccount(submission.accountId);
    if (token == null) throw const SubmissionSessionException();

    final http.Response response;
    try {
      response = await _client
          .post(
            _rpcUri,
            headers: {
              'apikey': supabasePublishableKey,
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'p_draft_id': submission.draftId,
              'p_submission_id': submission.submissionId,
              'p_payload': submission.payload,
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw SubmissionOutcomeUnknownException(submission);
    } on http.ClientException {
      throw SubmissionOutcomeUnknownException(submission);
    }

    return _interpret(response, submission);
  }

  DraftSubmissionReceipt _interpret(
    http.Response response,
    DraftSubmission submission,
  ) {
    final status = response.statusCode;
    final body = _decode(response);

    if (status == 200) {
      final parsed = body is Map<String, dynamic>
          ? DraftSubmissionStatus.parse(body['status'])
          : null;
      final submittedAt = body is Map<String, dynamic>
          ? DateTime.tryParse('${body['submitted_at']}')
          : null;
      if (parsed == null || submittedAt == null) {
        throw SubmissionOutcomeUnknownException(submission);
      }
      return DraftSubmissionReceipt(status: parsed, submittedAt: submittedAt);
    }

    // El código de PostgREST manda sobre el estado HTTP: un SQLSTATE 55000
    // puede llegar como 500.
    final code = body is Map<String, dynamic> && body['code'] is String
        ? body['code'] as String
        : null;
    switch (code) {
      case '42501':
        throw const SubmissionForbiddenException();
      case '22023':
        throw SubmissionRejectedException(statusCode: status, code: code);
      case '55000':
        throw const SubmissionAlreadyInReviewException();
      case 'PGRST301' || 'PGRST302' || 'PGRST303':
        throw const SubmissionSessionException();
    }

    if (status == 401) throw const SubmissionSessionException();
    if (status == 403) throw const SubmissionForbiddenException();
    if (status >= 400 && status < 500) {
      throw SubmissionRejectedException(statusCode: status, code: code);
    }
    throw SubmissionOutcomeUnknownException(submission);
  }

  static Object? _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }
}
