import 'dart:math' as math;

/// One splash beat: their incoming line + Kehlo’s suggested reply.
class SplashChatPair {
  const SplashChatPair({
    required this.incoming,
    required this.suggestion,
  });

  final String incoming;
  final String suggestion;
}

const splashChatPairs = <SplashChatPair>[
  SplashChatPair(
    incoming: 'wanna hangout with me today?',
    suggestion: 'maybe — coffee later?',
  ),
  SplashChatPair(
    incoming: 'you still up?',
    suggestion: 'barely 😅 what’re you thinking?',
  ),
  SplashChatPair(
    incoming: 'that date was actually fun',
    suggestion: 'right? we should do round two',
  ),
  SplashChatPair(
    incoming: 'i had a rough day tbh',
    suggestion: 'damn that sucks — want company?',
  ),
  SplashChatPair(
    incoming: 'send me a song that feels like you',
    suggestion: 'okay but no judging my taste lol',
  ),
  SplashChatPair(
    incoming: 'are we still on for saturday?',
    suggestion: 'yeah — 7 work for you?',
  ),
  SplashChatPair(
    incoming: 'you’re kinda hard to read',
    suggestion: 'fair. i’m interested — just chill about it',
  ),
  SplashChatPair(
    incoming: 'miss talking to you',
    suggestion: 'same… what’ve you been up to?',
  ),
  SplashChatPair(
    incoming: 'be honest — was that too much?',
    suggestion: 'nah, i liked it. say more',
  ),
  SplashChatPair(
    incoming: 'i’m bored. entertain me',
    suggestion: 'dangerous ask 😏 what’s your vibe tonight?',
  ),
  SplashChatPair(
    incoming: 'left you on read earlier sorry',
    suggestion: 'all good — life happens. what’s up now?',
  ),
  SplashChatPair(
    incoming: 'your profile is kinda cute',
    suggestion: 'appreciate that — yours got me curious',
  ),
  SplashChatPair(
    incoming: 'do you actually cook or was that a flex?',
    suggestion: 'both. prove me wrong over dinner?',
  ),
  SplashChatPair(
    incoming: 'i’m bad at texting first',
    suggestion: 'lucky i’m not. hi again 👋',
  ),
  SplashChatPair(
    incoming: 'that photo from japan is unreal',
    suggestion: 'right? bucket list trip. you travel much?',
  ),
  SplashChatPair(
    incoming: 'so… what are we?',
    suggestion: 'figuring it out — but i like where this is going',
  ),
  SplashChatPair(
    incoming: 'ok but hear me out — tacos at midnight',
    suggestion: 'say less. i’m already putting shoes on',
  ),
  SplashChatPair(
    incoming: 'you free this weekend or nah',
    suggestion: 'saturday’s open — drinks?',
  ),
  SplashChatPair(
    incoming: 'i keep thinking about that conversation',
    suggestion: 'same. unfinished business?',
  ),
  SplashChatPair(
    incoming: 'good morning you',
    suggestion: 'morning ☀️ sleep okay?',
  ),
];

SplashChatPair randomSplashChatPair([math.Random? random]) {
  final rng = random ?? math.Random();
  return splashChatPairs[rng.nextInt(splashChatPairs.length)];
}
