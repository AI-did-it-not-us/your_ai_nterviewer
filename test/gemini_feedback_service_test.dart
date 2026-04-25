import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:your_ai_nterviewer/models/applicant_info.dart';
import 'package:your_ai_nterviewer/models/interview_feedback.dart';
import 'package:your_ai_nterviewer/services/gemini_feedback_service.dart';

void main() {
  test(
    'generateFeedback sends interview context and parses feedback',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), contains('gemini-2.5-flash'));
        expect(request.url.queryParameters['key'], 'test-key');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final prompt = body['contents'][0]['parts'][0]['text'] as String;
        expect(prompt, contains('질문: 자기소개를 해주세요.'));
        expect(prompt, contains('답변: 안녕하세요.'));
        expect(prompt, contains('지원 직무/주제: Flutter 개발자'));

        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'summary': '답변 구조가 안정적입니다.',
                          'score': 82,
                          'strengths': ['핵심 경험을 언급했습니다.'],
                          'improvements': ['성과 수치를 더하세요.'],
                          'questionFeedback': [
                            {
                              'question': '자기소개를 해주세요.',
                              'answer': '안녕하세요.',
                              'feedback': '간결합니다.',
                              'suggestion': '대표 프로젝트를 덧붙이세요.',
                            },
                          ],
                          'nextPracticeGoal': '성과 중심으로 답변하기',
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service = GeminiFeedbackService(client: client, apiKey: 'test-key');

      final result = await service.generateFeedback(_payload);

      expect(result.summary, '답변 구조가 안정적입니다.');
      expect(result.score, 82);
      expect(result.strengths, contains('핵심 경험을 언급했습니다.'));
      expect(result.questionFeedback.single.suggestion, '대표 프로젝트를 덧붙이세요.');
    },
  );

  test('generateFeedback throws typed exception for malformed response', () {
    final client = MockClient((request) async {
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'not json'},
                  ],
                },
              },
            ],
          }),
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = GeminiFeedbackService(client: client, apiKey: 'test-key');

    expect(
      service.generateFeedback(_payload),
      throwsA(isA<GeminiFeedbackException>()),
    );
  });
}

const _payload = InterviewFeedbackPayload(
  applicantInfo: ApplicantInfo(
    companyName: '기술 면접',
    position: 'Flutter 개발자',
    interviewerName: '지혜',
    interviewerRivePath: 'assets/rives/jihye_anchor.riv',
    interviewerStyle: '실무형',
    interviewGoal: '프로젝트 설명',
  ),
  exchanges: [InterviewExchange(question: '자기소개를 해주세요.', answer: '안녕하세요.')],
);
