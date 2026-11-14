# Contributing

How the five of us change this repo without breaking each other's work.
Every rule here applies to people and to AI coding agents equally.

## 1. One-time setup

```bash
git clone https://github.com/sameera-ekanayaka/AquaGrow_Connect.git
cd AquaGrow_Connect
git config core.hooksPath tool/hooks     # turns on the commit message check
flutter pub get
```

Then open the folder in **Android Studio** (File > Open > the `AquaGrow_Connect` folder),
pick **AquaGrow (simulation)** from the run menu, choose an emulator or phone, and press Run.

## 2. Branches

- `main` is protected in spirit: **never commit or push to `main` directly.**
- One branch per feature, named `feature/<your-name>-<what>`, for example
  `feature/osanda-alert-engine`, `feature/udeshika-crop-detail`.
- Fix branches: `fix/<your-name>-<what>`. Docs only: `docs/<your-name>-<what>`.
- Start every branch from the latest `main`:

```bash
git switch main
git pull
git switch -c feature/<your-name>-<what>
```

## 3. Commits: small and atomic

A commit is **one logical change that leaves the app working**. Commit every time one
step works, not once at the end of the day.

Good sizes:

- the model plus its unit test
- one widget
- one screen wired to its provider
- one bug fix with the test that proves it

Bad: "day 2 work" with 30 files across 4 features.

Before each commit:

```bash
dart format lib test            # format the files you changed
flutter analyze                 # zero errors and warnings, and no new infos in your files
flutter test                    # everything green
git add -p                      # stage only what belongs to THIS commit
git commit
```

### Commit messages

Format: [Conventional Commits](https://www.conventionalcommits.org).

```
<type>(<scope>): <summary in the imperative, lower case, no full stop>

<body: WHY the change was needed and anything a reviewer must know.
Wrap at about 72 characters. Optional for tiny changes.>
```

- **type**: `feat` (new behaviour), `fix` (bug), `refactor` (no behaviour change), `test`,
  `docs`, `style` (formatting only), `perf`, `build` (pubspec, Gradle), `ci`, `chore`.
- **scope**: the feature or folder: `dashboard`, `alerts`, `crops`, `insights`, `care`,
  `auth`, `sync`, `simulator`, `theme`, `router`, `android`, `supabase`.
- **summary**: what the commit does, under 72 characters (100 is the hard limit).

Examples:

```
feat(alerts): raise a critical alert when pH leaves its safe range
fix(dashboard): keep the pod switcher selection after rotation
test(crops): cover days-to-harvest for a harvested batch
refactor(auth): move login screen to the Figma theme
```

### Never mention AI tools in commits

Commit messages, PR titles and PR descriptions must **never** name an AI tool, model,
assistant or agent, and must not carry an AI `Co-authored-by` trailer. Write the message
as the engineer responsible for the change. The `commit-msg` hook and CI reject commits
that break this rule. If your agent adds such a line, remove it before committing.

## 4. Pull requests

1. Push your branch: `git push -u origin feature/<your-name>-<what>`.
2. Open a PR into `main` on GitHub. Fill in the template.
3. CI must be green before anyone merges. At minimum the **Commit messages** and
   **Analyze and test** checks must pass (the APK build may still be running for docs-only PRs).
4. Who merges, in this order (we have little time, so nobody waits long):
   1. **Sameera** reviews and merges.
   2. If Sameera has not merged within about **30 minutes**, **any other teammate** (not the
      author) may review and merge.
   3. If the PR blocks someone else, or it is close to a deadline (for example the Sunday 9 PM
      freeze), the **author may merge their own PR**, and posts "self-merged #N" in the group so
      Sameera can review it afterwards.
   Never merge with a red check. Use **Rebase and merge** to keep the atomic commits;
   "Squash" only if the commits are messy.
5. If `main` moved on, update your branch: `git fetch && git rebase origin/main`, then
   `git push --force-with-lease`.

Keep PRs small: one feature, ideally under 400 changed lines. Several small PRs a day is right.

## 5. Ownership: whose files are whose

Each person owns folders, listed in their task file under `docs/tasks/`. You may:

- edit any file in **your** folders,
- **add** new files in `lib/shared/widgets/` (do not change existing ones without asking),
- add tests anywhere under `test/` for your own code.

You must **ask in the group first** before editing:

- `pubspec.yaml` (Sameera or Tharindu adds packages),
- anything in `lib/core/` (models, interfaces, theme, simulator),
- `lib/data/data_providers.dart`, `lib/app/` (router, shell),
- `android/`, `supabase/migrations/`,
- another member's feature folder.

## 6. Code standards

- Follow [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [DESIGN.md](DESIGN.md).
- Imports: `package:aquagrow_mobile/...` only, never relative.
- No `print`: use `AppLogger`. No hex colours or raw sizes in features: use tokens.
- Every public class and method gets a `///` doc comment saying what it is for.
- Prefer `const` widgets, `final` locals, small widgets (split anything over ~150 lines).
- No secrets in code or Git. Keys go in `env/dev.json` (copy `env/example.json`).
- Handle errors: catch in repositories, show `AppFailure.message` in the UI.

## 7. Testing

| What | Test type | Where |
| --- | --- | --- |
| Calculations, rules, parsers (`domain/`) | Unit test | `test/features/<feature>/domain/...` |
| Providers and controllers | Unit test with `ProviderContainer` and overrides | `test/features/<feature>/application/...` |
| Screens | Widget test using `testApp()` from `test/helpers/test_app.dart` | `test/features/<feature>/presentation/...` |

Rules:

- Every feature PR includes tests for its logic. Target: every `domain/` file covered.
- Tests never hit the network, a real clock or a real plugin. Use `PodSimulator(clock: ...)`
  and call `sim.tick()` yourself. Override plugin providers (see `testApp`).
- Name tests as sentences: `test('locks dosing after five pulses with no change', ...)`.
- Run one file in Android Studio with the green arrow next to `main()`, or
  `flutter test test/path/to/file_test.dart`.

## 8. Definition of done

A task is done when:

- [ ] It matches the Figma design and the rules in DESIGN.md, in light and dark mode.
- [ ] It handles loading, error, empty and offline states.
- [ ] It survives rotation without losing typed text.
- [ ] `flutter analyze` shows no errors or warnings, and `flutter test` passes.
- [ ] It has tests for its logic.
- [ ] It ran on an emulator or phone.
- [ ] It is merged into `main` through a reviewed PR with green CI.
- [ ] The checkbox in your `docs/tasks/<name>.md` is ticked in the same PR.
