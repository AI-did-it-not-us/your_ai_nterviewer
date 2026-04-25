import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/interview_feedback.dart';

abstract class InterviewFeedbackGenerator {
  bool get hasApiKey;

  Future<InterviewFeedbackResult> generateFeedback(
    InterviewFeedbackPayload payload,
  );

  void dispose();
}

class GeminiFeedbackService implements InterviewFeedbackGenerator {
  GeminiFeedbackService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _apiKey = apiKey ?? _defaultApiKey;

  static const String _defaultApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _host = 'generativelanguage.googleapis.com';
  static const String _model = 'gemini-2.5-flash';

  final http.Client _client;
  final bool _ownsClient;
  final String _apiKey;

  @override
  bool get hasApiKey => _apiKey.isNotEmpty;

  @override
  Future<InterviewFeedbackResult> generateFeedback(
    InterviewFeedbackPayload payload,
  ) async {
    if (!hasApiKey) {
      throw const GeminiFeedbackException(
        'GEMINI_API_KEY가 설정되지 않았습니다. --dart-define으로 API 키를 전달해주세요.',
      );
    }

    final response = await _client.post(
      Uri.https(_host, '/v1beta/models/$_model:generateContent', {
        'key': _apiKey,
      }),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_requestBody(payload)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeminiFeedbackException(_extractErrorMessage(response.body));
    }

    try {
      final outputText = _extractText(response.body);
      final feedbackJson = _decodeFeedbackJson(outputText);
      return InterviewFeedbackResult.fromJson(feedbackJson);
    } on GeminiFeedbackException {
      rethrow;
    } catch (_) {
      throw const GeminiFeedbackException('Gemini 피드백 응답을 해석하지 못했습니다.');
    }
  }

  Map<String, dynamic> _requestBody(InterviewFeedbackPayload payload) {
    return {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': _buildPrompt(payload)},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'responseMimeType': 'application/json',
      },
    };
  }

  String _buildPrompt(InterviewFeedbackPayload payload) {
    final applicantInfo = payload.applicantInfo;
    final contextLines = [
      if (applicantInfo?.companyName.trim().isNotEmpty == true)
        '면접 유형: ${applicantInfo!.companyName}',
      if (applicantInfo?.position.trim().isNotEmpty == true)
        '지원 직무/주제: ${applicantInfo!.position}',
      if (applicantInfo?.interviewerStyle.trim().isNotEmpty == true)
        '면접관 스타일: ${applicantInfo!.interviewerStyle}',
      if (applicantInfo?.interviewGoal.trim().isNotEmpty == true)
        '면접 목표: ${applicantInfo!.interviewGoal}',
    ];

    final exchangeLines = payload.exchanges
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key + 1;
          final exchange = entry.value;
          return [
            '[$index]',
            '질문: ${exchange.question}',
            '답변: ${exchange.answer}',
          ].join('\n');
        })
        .join('\n\n');

    return [
      '당신은 한국어 면접 코치입니다.',
      '아래 면접 질문과 지원자 답변을 평가해 한국어 JSON만 반환하세요.',
      '내부 사고 과정, 영어 설명, 마크다운 코드블록을 포함하지 마세요.',
      'score는 0부터 100 사이의 정수입니다.',
      'questionFeedback은 입력된 각 질문/답변 쌍마다 하나씩 작성하세요.',
      '반환 JSON 형식:',
      '{"summary":"...","score":80,"strengths":["..."],"improvements":["..."],"questionFeedback":[{"question":"...","answer":"...","feedback":"...","suggestion":"..."}],"nextPracticeGoal":"..."}',
      if (contextLines.isNotEmpty) ...['', '면접 정보:', ...contextLines],
      '',
      '면접 기록:',
      exchangeLines,
    ].join('\n');
  }

  String _extractText(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const GeminiFeedbackException('Gemini 응답 형식이 올바르지 않습니다.');
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiFeedbackException('Gemini 피드백 응답이 비어 있습니다.');
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) {
      throw const GeminiFeedbackException('Gemini 후보 응답 형식이 올바르지 않습니다.');
    }

    final content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) {
      throw const GeminiFeedbackException('Gemini 응답 본문이 비어 있습니다.');
    }

    final parts = content['parts'];
    if (parts is! List) {
      throw const GeminiFeedbackException('Gemini 응답 텍스트가 없습니다.');
    }

    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text']?.toString() ?? '')
        .where((part) => part.trim().isNotEmpty)
        .join('\n')
        .trim();

    if (text.isEmpty) {
      throw const GeminiFeedbackException('Gemini 응답 텍스트가 없습니다.');
    }

    return text;
  }

  Map<String, dynamic> _decodeFeedbackJson(String text) {
    final normalized = text
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
        .trim();

    final decoded = jsonDecode(normalized);
    if (decoded is! Map<String, dynamic>) {
      throw const GeminiFeedbackException('피드백 JSON 형식이 올바르지 않습니다.');
    }

    return decoded;
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message']?.toString().trim();
          if (message != null && message.isNotEmpty) {
            return 'Gemini 피드백 생성 실패: $message';
          }
        }
      }
    } catch (_) {
      // Use a stable fallback below when the error body is not JSON.
    }

    return 'Gemini 피드백 생성에 실패했습니다.';
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class GeminiFeedbackException implements Exception {
  const GeminiFeedbackException(this.message);

  final String message;

  @override
  String toString() => message;
}
