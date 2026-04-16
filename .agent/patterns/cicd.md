# Pattern: CI/CD

**Apply when:** User requests CI/CD setup, GitHub Actions workflow, Fastlane lanes,
or deployment to TestFlight / App Store.

Generates: GitHub Actions workflow + Fastlane Fastfile + Matchfile for signing.

---

## Output Files

```
<ProjectRoot>/
├── .github/
│   └── workflows/
│       ├── ci.yml          ← PR checks: build + test
│       └── deploy.yml      ← Manual trigger: TestFlight upload
├── fastlane/
│   ├── Fastfile
│   ├── Matchfile
│   └── Appfile
└── .env.ci.example         ← Required secrets (never commit actual values)
```

---

## GitHub Actions — CI (PR Checks)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-and-test:
    name: Build & Test
    runs-on: macos-14
    timeout-minutes: 30

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Install xcodegen
        run: brew install xcodegen

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Build & Test
        run: |
          xcodebuild test \
            -scheme ${{ env.SCHEME }} \
            -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.4' \
            -resultBundlePath TestResults.xcresult \
            CODE_SIGNING_ALLOWED=NO \
            | xcpretty --report junit --output test-results.xml

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: test-results.xml

env:
  SCHEME: <AppName>
```

---

## GitHub Actions — Deploy (TestFlight)

```yaml
# .github/workflows/deploy.yml
name: Deploy to TestFlight

on:
  workflow_dispatch:
    inputs:
      release_notes:
        description: "What's new in this build"
        required: true

jobs:
  deploy:
    name: TestFlight Upload
    runs-on: macos-14
    timeout-minutes: 60

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Install xcodegen
        run: brew install xcodegen

      - name: Install Fastlane
        run: gem install fastlane --no-document

      - name: Setup signing certificates
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
        run: fastlane match appstore --readonly

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Increment build number
        run: fastlane run increment_build_number

      - name: Build and upload
        env:
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.ASC_PRIVATE_KEY }}
        run: fastlane beta release_notes:"${{ github.event.inputs.release_notes }}"
```

---

## Fastfile

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do

  desc "Run all unit tests"
  lane :test do
    run_tests(
      scheme: ENV["SCHEME"] || "<AppName>",
      devices: ["iPhone 15"],
      code_coverage: true,
      output_directory: "fastlane/test_output",
      output_types: "html,junit"
    )
  end

  desc "Build and upload to TestFlight"
  lane :beta do |options|
    # Ensure clean working tree
    ensure_git_status_clean

    # Sync signing certificates
    match(type: "appstore", readonly: is_ci)

    # Increment build number using latest TestFlight build + 1
    increment_build_number(
      build_number: latest_testflight_build_number + 1
    )

    # Build
    build_app(
      scheme: ENV["SCHEME"] || "<AppName>",
      export_method: "app-store",
      export_options: {
        provisioningProfiles: {
          ENV["BUNDLE_ID"] => "match AppStore #{ENV['BUNDLE_ID']}"
        }
      }
    )

    # Upload
    upload_to_testflight(
      changelog: options[:release_notes] || "Bug fixes and improvements",
      skip_waiting_for_build_processing: true
    )

    # Tag the release
    version = get_version_number
    build = get_build_number
    add_git_tag(tag: "v#{version}(#{build})")
    push_git_tags
  end

  desc "Submit to App Store for review"
  lane :release do
    match(type: "appstore", readonly: true)
    build_app(scheme: ENV["SCHEME"] || "<AppName>", export_method: "app-store")
    upload_to_app_store(
      submit_for_review: true,
      automatic_release: false,
      force: true
    )
  end

  error do |lane, exception|
    # Notify on failure (add Slack/webhook if needed)
    UI.error("Lane #{lane} failed: #{exception.message}")
  end

end
```

---

## Matchfile (Code Signing)

```ruby
# fastlane/Matchfile
git_url(ENV["MATCH_GIT_URL"])          # Private repo for certificates
storage_mode("git")
type("appstore")
app_identifier(ENV["BUNDLE_ID"])
username(ENV["APPLE_ID"])
```

---

## Appfile

```ruby
# fastlane/Appfile
app_identifier(ENV["BUNDLE_ID"])
apple_id(ENV["APPLE_ID"])
team_id(ENV["TEAM_ID"])
```

---

## Required Secrets

Document in `.env.ci.example` — never commit actual values.

```bash
# .env.ci.example
# Copy to .env.ci and fill in values. Never commit .env.ci

# App Store Connect API Key (for uploading builds)
ASC_KEY_ID=
ASC_ISSUER_ID=
ASC_PRIVATE_KEY=          # Full content of .p8 file, including header/footer

# Match (code signing certificates)
MATCH_GIT_URL=            # Private git repo URL for certificates
MATCH_PASSWORD=           # Encryption password for certificates
MATCH_GIT_BASIC_AUTHORIZATION= # Base64 of username:token

# App identity
BUNDLE_ID=com.company.appname
APPLE_ID=developer@company.com
TEAM_ID=XXXXXXXXXX
SCHEME=<AppName>
```

---

## project.yml — UITests target (needed for CI)

Add UITests target to support CI screenshot capture:

```yaml
targets:
  <AppName>UITests:
    type: bundle.ui-testing
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: UITests
    dependencies:
      - target: <AppName>
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.wiraagent.<AppName>UITests
```

---

## Gitignore additions

Add to `.gitignore` when CI/CD is set up:

```
# Fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/
fastlane/test_output/
fastlane/*.ipa
fastlane/*.dSYM.zip

# Env
.env.ci

# Certificates (managed by match)
*.p12
*.cer
*.mobileprovision
```

---

## Code Gen Rules

When generating CI/CD:

1. Replace all `<AppName>` with the actual app name from `project.yml`
2. Replace `com.wiraagent.<AppName>` with the actual bundle ID
3. Add `.env.ci.example` to repo root — committed, with empty values
4. Add CI/CD files to the PR description under `## Setup Required`
5. Never commit actual secrets — only `.example` files

---

## Self-check

- [ ] `.env.ci.example` created with all required keys (no values)
- [ ] `ci.yml` uses correct scheme name matching `project.yml`
- [ ] `deploy.yml` is manual trigger only (`workflow_dispatch`) — no auto-deploy on push
- [ ] `Fastfile` has `ensure_git_status_clean` in beta lane
- [ ] `Matchfile` uses environment variables, no hardcoded credentials
- [ ] UITests target added to `project.yml` if visual verification is enabled
