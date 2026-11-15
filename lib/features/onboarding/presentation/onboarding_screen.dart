import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/onboarding/application/onboarding_store.dart';
import 'package:aquagrow_mobile/features/onboarding/domain/onboarding_slide.dart';
import 'package:aquagrow_mobile/features/onboarding/presentation/widgets/slide_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Time for one page turn.
const _pageTurn = Duration(milliseconds: 300);

/// Width of the current page's dot; the others are square.
const double _activeDot = AgSpace.s24;

/// The first-launch walkthrough from the Figma "Onboarding" frames: three
/// slides, Skip at the top, dots and Next at the bottom, and "Get started"
/// on the last slide.
///
/// Skip and Get started both save [OnboardingStore.markSeen], so the
/// walkthrough shows only once, then call [onFinished]. Without
/// [onFinished] it goes to Home, and the router sends a signed-out user on
/// to Sign in.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the walkthrough.
  const OnboardingScreen({this.onFinished, super.key});

  /// Runs after the walkthrough is saved as seen. Defaults to going Home.
  final VoidCallback? onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  bool get _isLast => _page == onboardingSlides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingStoreProvider).markSeen();
    if (!mounted) return;
    final done = widget.onFinished;
    if (done != null) {
      done();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _pages.nextPage(duration: _pageTurn, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ag;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AgSpace.screen),
          child: Column(
            children: [
              SizedBox(
                height: kMinTouchTarget + AgSpace.s8,
                child: Align(
                  alignment: Alignment.centerRight,
                  // Hidden, but kept in the layout, on the last slide.
                  child: Visibility(
                    visible: !_isLast,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: _finish,
                      child: const Text('Skip'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: onboardingSlides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => SlideView(slide: onboardingSlides[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AgSpace.s16),
                child: Row(
                  children: [
                    _PageDots(count: onboardingSlides.length, current: _page),
                    const Spacer(),
                    FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, kMinTouchTarget),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AgSpace.s24,
                        ),
                      ),
                      child: Text(_isLast ? 'Get started' : 'Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The row of dots under the slides. The current page is a wider pill.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    return Semantics(
      label: 'Page ${current + 1} of $count',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: _pageTurn,
              margin: const EdgeInsets.only(right: AgSpace.s4 + 2),
              width: i == current ? _activeDot : AgSpace.s8,
              height: AgSpace.s8,
              decoration: BoxDecoration(
                color: i == current ? c.text : c.border,
                borderRadius: AgRadius.all(AgRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}
