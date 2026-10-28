# Contributing

Thanks for helping improve `grpc_alice_interceptor`. This project is open to outside contributions via pull requests.

## Before you start

- **Small fixes** (docs, tests, typos): open a PR directly.
- **Larger changes** (new APIs, new dependencies, behavior changes): open an [issue](https://github.com/andreishemetov/grpc_alice_interceptor/issues) first so we agree on scope.

## Development setup

```bash
git clone git@github.com:andreishemetov/grpc_alice_interceptor.git
cd grpc_alice_interceptor
flutter pub get
dart analyze
cd example && flutter pub get && dart analyze && flutter test
```

### Example app

```bash
cd example && dart run bin/server.dart   # terminal 1
cd example && flutter run                # terminal 2
```

On the **Android emulator**, use gateway URL `http://10.0.2.2:50051` (not `127.0.0.1`).

## Pull requests

1. Fork the repo and create a branch from `main`.
2. Keep PRs **focused** — one logical change per PR; avoid drive-by refactors.
3. Match existing code style (see `analysis_options.yaml`).
4. Do **not** bump `version` in `pubspec.yaml` unless a maintainer asked — releases are cut by maintainers.
5. Update `CHANGELOG.md` only when a maintainer requests it for an upcoming release.

CI must pass before merge ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)). Branch protection requires the **CI / analyze** (or **analyze**) check.

Use the PR template and describe how you tested the change.

## Maintainer release process

Only [pub.dev uploaders](https://pub.dev/packages/grpc_alice_interceptor/admin) publish packages.

1. Merge approved PRs to `main`.
2. Bump `version` in `pubspec.yaml` and add a `CHANGELOG.md` entry (semver).
3. Commit, tag (e.g. `v0.1.1`), push tag.
4. Run `dart pub publish` from the repo root.

## Security

- Do not commit secrets (API keys, tokens, `.env` files).
- Dependency upgrades: explain why in the PR; CI must stay green.
- Changes under `.github/workflows/`: maintainers review carefully — workflows can access repository secrets if any are configured later.
- Report sensitive security issues privately to the maintainer (avoid public issues for exploitable details).

## Suggested GitHub labels

Create these on the repo if they are missing: `bug`, `enhancement`, `documentation`, `good first issue`, `help wanted`.
