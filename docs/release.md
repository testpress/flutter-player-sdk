# Release Guidelines

Internal guide for releasing `tpstreams_player_sdk` to **pub.dev** and creating **GitHub Releases**.

---

## 1. Release Architecture & CI Automation

Releases are automated via GitHub Actions on the `main` branch:

* **[publish.yml](.github/workflows/publish.yml)** (*Publish to pub.dev*):
  * Triggers on push to `main` modifying `pubspec.yaml` or `CHANGELOG.md` (or manual `workflow_dispatch`).
  * Reads `VERSION` from `pubspec.yaml`.
  * Runs `dart pub publish --force` using the repository secret `PUB_CREDENTIALS`.
  * Creates and pushes the annotated Git tag (e.g. `2.2.37`).

* **[release.yml](.github/workflows/release.yml)** (*Create GitHub Release*):
  * Triggers automatically once `Publish to pub.dev` completes successfully (or manual `workflow_dispatch`).
  * Extracts release notes matching `## <VERSION>` from `CHANGELOG.md`.
  * Publishes a GitHub Release under that Git tag with the extracted notes.

---

## 2. Release Checklist

### Step 1: Bump the Version
Update `version` in `pubspec.yaml`:
```yaml
version: x.y.z
```

### Step 2: Update CHANGELOG.md
Add an entry for the version. The header format `## x.y.z` is required by the CI release script:
```markdown
## x.y.z
- Description of feature or fix
- Another change description
```

### Step 3: Verify Locally
Ensure tests pass and dry-run pub publishing:
```bash
# Verify tests
flutter test

# Verify pub package validity
dart pub publish --dry-run
```

### Step 4: Submit & Merge PR
1. Commit changes to a release branch:
   ```bash
   git checkout -b release/x.y.z
   git commit -am "chore: prepare for release x.y.z"
   git push origin release/x.y.z
   ```
2. Open a Pull Request targeting `main`.
3. Once approved and checks pass, merge the PR into `main`.

### Step 5: Monitor Automated Workflows
Both workflows trigger and run automatically upon merging to `main`. Check the GitHub **Actions** tab to ensure they complete with green checkmarks:
1. **Publish to pub.dev**: Confirms the package is published to pub.dev and Git tag `x.y.z` is created.
2. **Create GitHub Release**: Confirms release notes are extracted from `CHANGELOG.md` and the GitHub Release is published.

---

## 3. Manual Fallback

If CI fails or needs to be re-run manually:
* **Publish to pub.dev**: Go to **Actions** > **Publish to pub.dev** > click **Run workflow** on `main`.
* **Create GitHub Release**: Go to **Actions** > **Create GitHub Release** > click **Run workflow** on `main` (you can enter the specific version if needed).
