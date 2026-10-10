import 'package:flutter_test/flutter_test.dart';
import 'package:wingman/features/screenshot_reply/models/reply_generation_result.dart';
import 'package:wingman/features/screenshot_reply/parsers/reply_response_parser.dart';

void main() {
  const parser = ReplyResponseParser();

  test('parses valid replies payload', () {
    final result = parser.parse({
      'readable': true,
      'latestIncoming': 'Want to grab coffee?',
      'replies': {
        'natural': 'Yeah, I’d be down. When works for you?',
        'playful': 'Coffee sounds dangerous — I’m in. Tomorrow?',
        'confident': 'Let’s do it. Are you free Thursday evening?',
      },
    });

    expect(result, isA<RepliesReady>());
    final replies = (result as RepliesReady).replies;
    expect(replies.natural, contains('down'));
    expect(replies.playful, contains('Coffee'));
    expect(replies.confident, contains('Thursday'));
    expect(replies.latestIncoming, 'Want to grab coffee?');
  });

  test('strips wrapping quotes from replies', () {
    final result = parser.parse({
      'readable': true,
      'replies': {
        'natural': '"Sounds good to me."',
        'playful': "'Careful, that smile is illegal.'",
        'confident': '“I’m free Friday.”',
      },
    });

    expect(result, isA<RepliesReady>());
    final replies = (result as RepliesReady).replies;
    expect(replies.natural, 'Sounds good to me.');
    expect(replies.playful, 'Careful, that smile is illegal.');
    expect(replies.confident, 'I’m free Friday.');
  });

  test('parses no-reply-needed outcome', () {
    final result = parser.parse({
      'readable': true,
      'needsReply': false,
      'title': "You're all set",
      'message': 'You already said goodnight — let them reply first.',
      'latestOutgoing': 'goodnight 🌙',
    });

    expect(result, isA<NoReplyNeeded>());
    final notice = result as NoReplyNeeded;
    expect(notice.title, "You're all set");
    expect(notice.message, contains('goodnight'));
    expect(notice.latestOutgoing, 'goodnight 🌙');
  });

  test('rejects missing tone', () {
    expect(
      () => parser.parse({
        'readable': true,
        'replies': {
          'natural': 'Hi',
          'playful': 'Hey',
          'confident': '',
        },
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects duplicate replies', () {
    expect(
      () => parser.parse({
        'readable': true,
        'replies': {
          'natural': 'I feel the same way about you.',
          'playful': 'I feel the same way about you!',
          'confident': 'Let’s meet this weekend instead.',
        },
      }),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('distinct'),
        ),
      ),
    );
  });

  test('accepts distinct Tamil replies', () {
    final result = parser.parse({
      'readable': true,
      'latestIncoming': 'நான் உன்னை காதலிக்கிறேன்',
      'replies': {
        'natural': 'அட… இப்படி சொன்னது ரொம்ப இதமா இருக்கு.',
        'playful': 'டேய் மெதுவா போ — இதயத்தையே கொண்டுட்டாரு 😏',
        'confident': 'கேட்டுட்டேன். நம்ம பேசிக்கலாம் — நீ எப்போ free?',
      },
    });

    expect(result, isA<RepliesReady>());
    final replies = (result as RepliesReady).replies;
    expect(replies.natural, contains('இதமா'));
    expect(replies.playful, contains('மெதுவா'));
    expect(replies.confident, contains('கேட்டுட்டேன்'));
    expect(replies.latestIncoming, 'நான் உன்னை காதலிக்கிறேன்');
  });

  test('surfaces unreadable error message', () {
    expect(
      () => parser.parse({
        'readable': false,
        'error': 'Try a clearer chat screenshot.',
      }),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Try a clearer chat screenshot.',
        ),
      ),
    );
  });

  test('maps top-level error without replies', () {
    expect(
      () => parser.parse({'error': 'Unauthorized', 'code': 'auth'}),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Unauthorized',
        ),
      ),
    );
  });
}
