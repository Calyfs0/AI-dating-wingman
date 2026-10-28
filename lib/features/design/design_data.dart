import 'package:flutter/material.dart';

import 'bloom.dart';

enum BloomTone { sweet, playful, confident, thoughtful }

enum Boldness { subtle, balanced, bold }

class ToneStyle {
  const ToneStyle({
    required this.tone,
    required this.label,
    required this.blurb,
    required this.asset,
    required this.fg,
    required this.bg,
    required this.icon,
  });

  final BloomTone tone;
  final String label;
  final String blurb;
  final String asset;
  final Color fg;
  final Color bg;
  final IconData icon;
}

const toneStyles = <ToneStyle>[
  ToneStyle(
    tone: BloomTone.sweet,
    label: 'Sweet',
    blurb: 'Warm and genuine',
    asset: 'assets/design/tone_sweet.jpg',
    fg: Bloom.sweetFg,
    bg: Bloom.sweetBg,
    icon: Icons.favorite_rounded,
  ),
  ToneStyle(
    tone: BloomTone.playful,
    label: 'Playful',
    blurb: 'Fun and flirty',
    asset: 'assets/design/tone_playful.jpg',
    fg: Bloom.playfulFg,
    bg: Bloom.playfulBg,
    icon: Icons.mood_rounded,
  ),
  ToneStyle(
    tone: BloomTone.confident,
    label: 'Confident',
    blurb: 'Bold and direct',
    asset: 'assets/design/tone_confident.jpg',
    fg: Bloom.confidentFg,
    bg: Bloom.confidentBg,
    icon: Icons.auto_awesome_rounded,
  ),
  ToneStyle(
    tone: BloomTone.thoughtful,
    label: 'Thoughtful',
    blurb: 'Deep and meaningful',
    asset: 'assets/design/tone_thoughtful.jpg',
    fg: Bloom.thoughtfulFg,
    bg: Bloom.thoughtfulBg,
    icon: Icons.spa_rounded,
  ),
];

ToneStyle toneStyle(BloomTone tone) =>
    toneStyles.firstWhere((style) => style.tone == tone);

class BloomCategory {
  const BloomCategory({
    required this.id,
    required this.label,
    required this.image,
    this.filtersApps = false,
  });

  final String id;
  final String label;
  final String image;
  final bool filtersApps;
}

const homeCategories = <BloomCategory>[
  BloomCategory(
    id: 'first_message',
    label: 'First Message',
    image: 'assets/design/woman_portrait.jpg',
  ),
  BloomCategory(
    id: 'dating',
    label: 'Dating Apps',
    image: 'assets/design/card_phone.jpg',
    filtersApps: true,
  ),
  BloomCategory(
    id: 'in_person',
    label: 'In Person',
    image: 'assets/design/card_coffee.jpg',
  ),
  BloomCategory(
    id: 'replies',
    label: 'Replies',
    image: 'assets/design/card_replies.jpg',
  ),
  BloomCategory(
    id: 'compliments',
    label: 'Compliments',
    image: 'assets/design/tone_sweet.jpg',
  ),
  BloomCategory(
    id: 'keep_going',
    label: 'Keep it going',
    image: 'assets/design/card_people.jpg',
  ),
];

class IntroCard {
  const IntroCard({required this.label, required this.image});

  final String label;
  final String image;
}

const introCards = <IntroCard>[
  IntroCard(label: 'Dating Apps', image: 'assets/design/card_phone.jpg'),
  IntroCard(label: 'In Person', image: 'assets/design/card_coffee.jpg'),
  IntroCard(label: 'Replies', image: 'assets/design/card_replies.jpg'),
  IntroCard(label: 'Special Moments', image: 'assets/design/card_gift.jpg'),
];

typedef LineBank = Map<BloomTone, Map<Boldness, List<String>>>;

LineBank _pack({
  required String sweet,
  required String playful,
  required String confident,
  required String thoughtful,
  String? sweetMore,
  String? playfulMore,
  String? confidentMore,
  String? thoughtfulMore,
  String? sweetSoft,
  String? playfulSoft,
  String? confidentSoft,
  String? thoughtfulSoft,
  String? sweetBold,
  String? playfulBold,
  String? confidentBold,
  String? thoughtfulBold,
}) {
  Map<Boldness, List<String>> column({
    required String main,
    String? more,
    String? soft,
    String? bold,
  }) {
    return {
      Boldness.subtle: [soft ?? main, if (more != null) more],
      Boldness.balanced: [main, if (more != null) more],
      Boldness.bold: [bold ?? more ?? main, main],
    };
  }

  return {
    BloomTone.sweet: column(
      main: sweet,
      more: sweetMore,
      soft: sweetSoft,
      bold: sweetBold,
    ),
    BloomTone.playful: column(
      main: playful,
      more: playfulMore,
      soft: playfulSoft,
      bold: playfulBold,
    ),
    BloomTone.confident: column(
      main: confident,
      more: confidentMore,
      soft: confidentSoft,
      bold: confidentBold,
    ),
    BloomTone.thoughtful: column(
      main: thoughtful,
      more: thoughtfulMore,
      soft: thoughtfulSoft,
      bold: thoughtfulBold,
    ),
  };
}

class Situation {
  const Situation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.hero,
    required this.categories,
    required this.badge,
    required this.headline,
    required this.blurb,
    required this.tip,
    required this.lineFor,
    required this.sampleContext,
    required this.tag,
    required this.folderId,
    required this.apps,
    required this.lines,
  });

  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String hero;
  final List<String> categories;
  final String badge;
  final String headline;
  final String blurb;
  final String tip;
  final String lineFor;
  final String sampleContext;
  final String tag;
  final String folderId;
  final List<String> apps;
  final LineBank lines;
}

const popularIds = ['travel', 'hobbies', 'food', 'pets'];

final situations = <Situation>[
  Situation(
    id: 'travel',
    title: 'Profile prompt “Travel”',
    subtitle: 'Turn their travel photo into a great opener.',
    image: 'assets/design/thumb_travel.jpg',
    hero: 'assets/design/woman_portrait.jpg',
    categories: ['dating', 'first_message'],
    badge: 'First Message',
    headline: 'She has a travel photo in her profile.',
    blurb: 'Create a fun and natural opener based on her travel photo.',
    tip: 'Keep it light, be genuine and show interest in the place.',
    lineFor: 'Her travel photo from Korea',
    sampleContext:
        'We both love travel and café culture. I want to keep it fun and natural.',
    tag: 'Travel',
    folderId: 'travel',
    apps: ['Tinder', 'Bumble', 'Hinge'],
    lines: _pack(
      sweet:
          'That photo from Seoul looks amazing! Any hidden cafés there that you’d recommend for a first-timer?',
      sweetSoft:
          'That Seoul photo is lovely. Any quiet cafés you’d recommend for a first visit?',
      sweetBold:
          'Seoul looks incredible in your photo. Take me to the café you’d actually go back to.',
      sweetMore:
          'If I landed in Seoul with one free afternoon, where would you send me first?',
      playful:
          'So... are you collecting passport stamps or just trying to make the rest of us jealous?',
      playfulSoft:
          'Okay, that Seoul photo is unfair. Any cafés worth the jet lag?',
      playfulBold:
          'Be honest — are you collecting passport stamps, or just showing off a little?',
      playfulMore:
          'I was doing fine until your Seoul photo showed up. What was the best bite?',
      confident:
          'Korea looks even better with you in it. What was your favourite part of the trip?',
      confidentSoft: 'Korea suits you. What was the part you’d go back for?',
      confidentBold:
          'That trip looks like a story. I want the version you’d tell over coffee.',
      confidentMore:
          'You clearly know how to pick a city. Korea next, or somewhere quieter?',
      thoughtful:
          'Your photo just convinced me to add Korea to my travel list. What was the highlight?',
      thoughtfulSoft:
          'That photo made me slow down for a second. What stayed with you after Seoul?',
      thoughtfulBold:
          'I keep thinking about that photo. What moment from the trip would you relive?',
      thoughtfulMore:
          'There’s a calm in that picture. Was the trip more wandering or more planned?',
    ),
  ),
  Situation(
    id: 'hobbies',
    title: 'Profile prompt “Hobbies”',
    subtitle: 'Find a line based on their interests.',
    image: 'assets/design/thumb_camera.jpg',
    hero: 'assets/design/thumb_camera.jpg',
    categories: ['dating', 'first_message'],
    badge: 'First Message',
    headline: 'Their hobbies are right there in the prompt.',
    blurb: 'Turn a camera, a playlist, or a weekend hobby into a first message.',
    tip: 'Pick one detail and ask something they can answer with a story.',
    lineFor: 'A hobbies prompt',
    sampleContext: 'They listed film cameras and weekend markets.',
    tag: 'Hobbies',
    folderId: 'first',
    apps: ['Bumble', 'Hinge'],
    lines: _pack(
      sweet:
          'A film camera and weekend markets is a very charming combination. Which one came first?',
      playful:
          'Be honest — is the camera for the photos, or for the mysterious-artist aesthetic?',
      confident:
          'I’m calling the markets. You show me the stall worth waking up early for.',
      thoughtful:
          'Hobbies say a lot. What do you notice when you’re shooting that you’d otherwise walk past?',
      sweetMore: 'If I tagged along to the market, what would you put in my hands first?',
      playfulMore: 'Film cameras are a commitment. What’s the photo you’re still chasing?',
      confidentMore: 'Teach me one thing about that camera and I’ll bring the coffee.',
      thoughtfulMore:
          'There’s usually a reason someone picks up a camera. What was yours?',
    ),
  ),
  Situation(
    id: 'food',
    title: 'Profile prompt “Food & Coffee”',
    subtitle: 'For foodies and café lovers.',
    image: 'assets/design/thumb_food.jpg',
    hero: 'assets/design/thumb_food.jpg',
    categories: ['dating'],
    badge: 'Dating Apps',
    headline: 'They care about coffee and a good table.',
    blurb: 'Write an opener for someone who lights up around food.',
    tip: 'Ask for a recommendation. It gives them an easy, happy reply.',
    lineFor: 'A food and coffee prompt',
    sampleContext: 'They posted a pastry and a latte. Keep it warm, not cheesy.',
    tag: 'Food',
    folderId: 'cafe',
    apps: ['Tinder', 'Hinge'],
    lines: _pack(
      sweet:
          'That latte looks like it has a regular order behind it. What do you actually ask for?',
      playful:
          'I’m deciding if you’re a pastry-before-coffee person or a dangerously disciplined one.',
      confident:
          'You pick the café. I’ll pretend I know the menu and then copy you.',
      thoughtful:
          'Food photos are easy. The good question is which meal feels like your city.',
      sweetMore: 'If we split one thing, what should it be — sweet, salty, or both?',
      playfulMore: 'Rank this honestly: coffee, dessert, or the excuse to sit still.',
      confidentMore: 'Take me to the place you’d send a friend who just moved here.',
      thoughtfulMore: 'What’s the meal you still think about after the plates are gone?',
    ),
  ),
  Situation(
    id: 'pets',
    title: 'Profile prompt “Pets”',
    subtitle: 'Because cute pet photos deserve a reply.',
    image: 'assets/design/thumb_dog.jpg',
    hero: 'assets/design/thumb_dog.jpg',
    categories: ['dating'],
    badge: 'Dating Apps',
    headline: 'There is a very cute dog in the profile.',
    blurb: 'A light opener that notices the pet and still talks to the person.',
    tip: 'Compliment the pet, then ask something about their routine together.',
    lineFor: 'A pet photo',
    sampleContext: 'Small white dog. I want to be charming, not just “cute dog.”',
    tag: 'Pets',
    folderId: 'first',
    apps: ['Tinder', 'Others'],
    lines: _pack(
      sweet:
          'That face is unfair. Are they the greeter of the house or the one who pretends not to care?',
      playful:
          'I need to know who picked whom — you, or the dog who clearly runs the place?',
      confident:
          'I’ll win the dog over first. What’s the treat that actually works?',
      thoughtful:
          'Pets change a day. What’s the little routine the two of you never skip?',
      sweetMore: 'Do they have a walk that always turns into a longer one?',
      playfulMore: 'Be honest: who has more friends at the park, you or them?',
      confidentMore: 'Introduce me properly. I have a feeling they make the final call.',
      thoughtfulMore: 'What did life look like the week they came home?',
    ),
  ),
  Situation(
    id: 'hike',
    title: 'A trail in their photo',
    subtitle: 'Ask about the view they posted.',
    image: 'assets/design/thumb_hike.jpg',
    hero: 'assets/design/thumb_hike.jpg',
    categories: ['in_person', 'first_message'],
    badge: 'In Person',
    headline: 'They shared a trail and a wide view.',
    blurb: 'A line for someone who clearly likes being outside.',
    tip: 'Show you’d actually go, not just that the photo looks nice.',
    lineFor: 'Their hiking photo',
    sampleContext: 'We matched after a trail photo. Keep it easy.',
    tag: 'Travel',
    folderId: 'travel',
    apps: ['Hinge', 'Bumble'],
    lines: _pack(
      sweet:
          'That trail in your photo looks amazing! I’m always looking for new hiking spots — where is this?',
      playful:
          'You clearly have great taste in views and coffee. I’m still exploring the city — got any favourite spots?',
      confident:
          'Are you more of a weekend trekker or a city café explorer? I’m trying to build my list.',
      thoughtful:
          'That view looks like it earned the walk. Was it a quiet trail or a popular one?',
      sweetMore: 'If I had a free morning, would you send me there or somewhere closer?',
      playfulMore: 'How many wrong turns does a first-timer get on that trail?',
      confidentMore: 'Save me a spot on the next easy-looking ridge. I’ll bring snacks.',
      thoughtfulMore: 'What do you notice up there that the photo can’t catch?',
    ),
  ),
  Situation(
    id: 'cafe',
    title: 'Coffee, in person',
    subtitle: 'A light line for someone you just met.',
    image: 'assets/design/thumb_cafe.jpg',
    hero: 'assets/design/thumb_cafe.jpg',
    categories: ['in_person'],
    badge: 'In Person',
    headline: 'You just met, and the coffee is still warm.',
    blurb: 'Something you could actually say across a small table.',
    tip: 'Short is better in person. Leave a pause for them to answer.',
    lineFor: 'An in-person coffee',
    sampleContext: 'We started talking in line. I want a follow-up that isn’t awkward.',
    tag: 'Café',
    folderId: 'cafe',
    apps: const [],
    lines: _pack(
      sweet: 'I’m glad we ended up in the same line. What’s your usual here?',
      playful: 'You had me at the coffee order. Morning person, or a late one in disguise?',
      confident: 'Sit for one more cup. I want the recommendation you’d actually defend.',
      thoughtful: 'It’s rare a line turns into a real conversation. What were you on your way to?',
      sweetMore: 'If this place closed, where would you take a first coffee?',
      playfulMore: 'Quick verdict: is this café charming, or just well lit?',
      confidentMore: 'Walk with me to the next good cup. I trust your order more than the map.',
      thoughtfulMore: 'What made you stop here today instead of somewhere easier?',
    ),
  ),
  Situation(
    id: 'plans',
    title: 'They suggested plans',
    subtitle: 'Keep the momentum and pick a time.',
    image: 'assets/design/card_replies.jpg',
    hero: 'assets/design/card_replies.jpg',
    categories: ['replies'],
    badge: 'Replies',
    headline: 'They opened the door to actual plans.',
    blurb: 'Reply in a way that chooses a time without sounding stiff.',
    tip: 'Offer one clear option, and a little warmth around it.',
    lineFor: 'A reply when they suggest meeting',
    sampleContext: 'They said we should grab coffee this week.',
    tag: 'Reply',
    folderId: 'first',
    apps: const [],
    lines: _pack(
      sweet: 'This week works. Thursday after six, or is another evening kinder?',
      playful: 'I’m in. Don’t make me be the organised one alone — Thursday or Saturday?',
      confident: 'Let’s do it. Thursday, that little place near the station. I’ll get there first.',
      thoughtful: 'I’d like that. A quieter evening suits me — does Thursday feel right?',
      sweetMore: 'Coffee this week sounds perfect. You pick the day, I’ll pick the table.',
      playfulMore: 'Say the night and I’ll pretend I didn’t already clear it.',
      confidentMore: 'Lock Thursday. If the café is full, we walk until we find a better one.',
      thoughtfulMore: 'Yes. I’d rather one unhurried hour than a rushed hello.',
    ),
  ),
  Situation(
    id: 'compliment',
    title: 'Her main photo',
    subtitle: 'A sincere compliment that isn’t generic.',
    image: 'assets/design/woman_portrait.jpg',
    hero: 'assets/design/woman_portrait.jpg',
    categories: ['compliments', 'first_message'],
    badge: 'Compliments',
    headline: 'The photo is warm. The line should be too.',
    blurb: 'Notice something specific, then give them a way to reply.',
    tip: 'Skip “you’re hot.” Name the feeling the photo gives you.',
    lineFor: 'A compliment on her photo',
    sampleContext: 'Soft smile, cream sweater, I want it genuine.',
    tag: 'Compliment',
    folderId: 'first',
    apps: ['Hinge', 'Bumble'],
    lines: _pack(
      sweet: 'That smile looks like you were in the middle of a good day. What was happening?',
      playful: 'This photo has “I know a great bakery” energy. Am I close?',
      confident: 'You look like good company. What’s the story behind this one?',
      thoughtful: 'There’s an ease in this photo. Do you feel like that on an ordinary Tuesday too?',
      sweetMore: 'I like how unforced this looks. Is that your real off-duty face?',
      playfulMore: 'I’m going to guess music was playing. What was it?',
      confidentMore: 'This is the photo that made me stop. Tell me where you were.',
      thoughtfulMore: 'It feels kind, not posed. Is that how your friends would describe you?',
    ),
  ),
  Situation(
    id: 'after',
    title: 'After a good date',
    subtitle: 'A note that feels warm, not needy.',
    image: 'assets/design/thumb_couple.jpg',
    hero: 'assets/design/thumb_couple.jpg',
    categories: ['keep_going'],
    badge: 'Keep it going',
    headline: 'The date went well. Say so simply.',
    blurb: 'A follow-up that keeps the door open for the next plan.',
    tip: 'Mention one real moment, then suggest seeing them again.',
    lineFor: 'A note after a good date',
    sampleContext: 'We laughed a lot. I want to see them again without overdoing it.',
    tag: 'Follow-up',
    folderId: 'cafe',
    apps: const [],
    lines: _pack(
      sweet: 'I got home still smiling. That hour went by too easily — want to do it again?',
      playful: 'Leaving was a mistake. Same place next week, or do we risk a new menu?',
      confident: 'I had a really good time with you. Let’s pick another night before the week fills up.',
      thoughtful: 'I liked how easy it was to actually talk. I’d like another evening if you would.',
      sweetMore: 'Thank you for tonight. The walk after was my favourite part.',
      playfulMore: 'Still thinking about that story you told. I need the sequel in person.',
      confidentMore: 'I’m not playing it cool. I want to see you again this week.',
      thoughtfulMore: 'Tonight felt unhurried in the best way. Can we make time for that again?',
    ),
  ),
];

Situation situationById(String id) =>
    situations.firstWhere((item) => item.id == id, orElse: () => situations.first);

BloomCategory? categoryById(String id) {
  for (final category in homeCategories) {
    if (category.id == id) return category;
  }
  return null;
}

List<Situation> situationsFor(String categoryId) => situations
    .where((item) => item.categories.contains(categoryId))
    .toList(growable: false);

class LineFolder {
  const LineFolder({
    required this.id,
    required this.name,
    required this.detail,
  });

  final String id;
  final String name;
  final String detail;
}

const lineFolders = <LineFolder>[
  LineFolder(
    id: 'travel',
    name: 'Travel',
    detail: 'Photos, cities, and trails',
  ),
  LineFolder(
    id: 'first',
    name: 'First messages',
    detail: 'Openers worth keeping',
  ),
  LineFolder(
    id: 'cafe',
    name: 'Café dates',
    detail: 'Coffee, tables, and follow-ups',
  ),
];

class SavedLine {
  const SavedLine({
    required this.id,
    required this.text,
    required this.tone,
    required this.mood,
    required this.tag,
    required this.image,
    required this.folderId,
  });

  final String id;
  final String text;
  final BloomTone tone;
  final String mood;
  final String tag;
  final String image;
  final String folderId;
}

const seededLines = <SavedLine>[
  SavedLine(
    id: 'seed-hike',
    text:
        'That trail in your photo looks amazing! I’m always looking for new hiking spots — where is this?',
    tone: BloomTone.sweet,
    mood: 'Warm',
    tag: 'Travel',
    image: 'assets/design/thumb_hike.jpg',
    folderId: 'travel',
  ),
  SavedLine(
    id: 'seed-coffee',
    text:
        'You clearly have great taste in views and coffee. I’m still exploring the city — got any favourite spots?',
    tone: BloomTone.playful,
    mood: 'Playful',
    tag: 'Travel',
    image: 'assets/design/thumb_cafe.jpg',
    folderId: 'travel',
  ),
  SavedLine(
    id: 'seed-couple',
    text:
        'Are you more of a weekend trekker or a city café explorer? I’m trying to build my list.',
    tone: BloomTone.playful,
    mood: 'Playful',
    tag: 'Travel',
    image: 'assets/design/thumb_couple.jpg',
    folderId: 'travel',
  ),
  SavedLine(
    id: 'seed-korea',
    text:
        'Your photo just convinced me to add Korea to my travel list. What was the highlight?',
    tone: BloomTone.thoughtful,
    mood: 'Thoughtful',
    tag: 'Travel',
    image: 'assets/design/thumb_travel.jpg',
    folderId: 'travel',
  ),
  SavedLine(
    id: 'seed-hobby',
    text:
        'A film camera and weekend markets is a very charming combination. Which one came first?',
    tone: BloomTone.sweet,
    mood: 'Sweet',
    tag: 'Hobbies',
    image: 'assets/design/thumb_camera.jpg',
    folderId: 'first',
  ),
  SavedLine(
    id: 'seed-cafe',
    text: 'I’m glad we ended up in the same line. What’s your usual here?',
    tone: BloomTone.sweet,
    mood: 'Sweet',
    tag: 'Café',
    image: 'assets/design/thumb_food.jpg',
    folderId: 'cafe',
  ),
];

class GeneratedLine {
  const GeneratedLine({required this.tone, required this.text});

  final BloomTone tone;
  final String text;
}
