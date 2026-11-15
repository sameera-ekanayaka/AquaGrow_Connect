/// What sits on top of a slide's round photo, as in the Figma frames.
enum SlideBadge {
  /// Just the photo (slide 1).
  none,

  /// A pH sensor tile (slide 2).
  sensorTile,

  /// A "Water needs attention" alert row (slide 3).
  alertRow,
}

/// One page of the first-launch walkthrough.
class OnboardingSlide {
  /// Creates a slide.
  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.imageAsset,
    this.badge = SlideBadge.none,
  });

  /// Big heading, for example "Grow fresh food at home".
  final String title;

  /// One sentence under the heading.
  final String body;

  /// Bundled photo shown in the circle.
  final String imageAsset;

  /// What floats over the photo.
  final SlideBadge badge;
}

/// The three slides from the Figma "Onboarding" frames, in order.
const onboardingSlides = [
  OnboardingSlide(
    title: 'Grow fresh food at home',
    body: 'Basil, spinach and herbs, growing in a pod on your counter.',
    imageAsset: 'assets/images/crops/basil.png',
  ),
  OnboardingSlide(
    title: 'Know your plants live',
    body: 'pH, nutrients and water, updated every few seconds.',
    imageAsset: 'assets/images/crops/spinach.png',
    badge: SlideBadge.sensorTile,
  ),
  OnboardingSlide(
    title: "Get alerted before it's too late",
    body: 'AquaGrow tells you what needs doing, and asks before it changes '
        'anything.',
    imageAsset: 'assets/images/crops/basil-plants.webp',
    badge: SlideBadge.alertRow,
  ),
];
