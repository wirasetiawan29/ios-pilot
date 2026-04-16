# Pattern: project.yml (XcodeGen)

Apply this pattern whenever creating or modifying `project.yml`.

---

## sources vs resources

xcodegen does NOT have a `resources:` key for targets. It is silently ignored.
All files — `.swift`, `.xcassets`, fonts, plists — must go in `sources:`.
xcodegen routes each file to the correct build phase based on file extension.

```yaml
# ✅ CORRECT
sources:
  - path: CoffeeShopApp.swift   # → Compile Sources
  - path: Theme                 # → Compile Sources
  - path: Models                # → Compile Sources
  - path: Features              # → Compile Sources
  - path: Assets.xcassets       # → Copy Bundle Resources (auto-detected)

# ❌ WRONG — resources: is not a valid key, silently ignored
sources:
  - path: Features
resources:
  - path: Assets.xcassets       # will NOT appear in .xcodeproj
```

After running `xcodegen generate`, always verify the file appeared in the project:
```bash
grep "Assets.xcassets" CoffeeShop.xcodeproj/project.pbxproj \
  || echo "BLOCKER: asset catalog missing from project"
```

---

## AppIcon.appiconset is required

Every `Assets.xcassets` must contain an `AppIcon.appiconset/`. Without it,
actool fails at build time:
> `None of the input catalogs contained a matching stickers icon set or app icon set named "AppIcon"`

Create a minimal placeholder when generating a new asset catalog:

```
Assets.xcassets/
└── AppIcon.appiconset/
    └── Contents.json
```

```json
{
  "images" : [
    { "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

---

## Post-build: verify Assets.car

BUILD SUCCEEDED does not guarantee the asset catalog was compiled in.
After xcodebuild, confirm `Assets.car` exists in the app bundle:

```bash
ls "$BUILD_PRODUCTS_DIR/CoffeeShop.app/Assets.car" \
  || echo "BLOCKER: Assets.car missing — check project.yml sources"
```

If missing: check `sources:` in `project.yml`, re-run `xcodegen generate`, clean build.

---

## Minimal project.yml template

```yaml
name: MyApp

options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "17.0"

targets:
  MyApp:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: MyAppApp.swift
      - path: Theme
      - path: Models
      - path: Features
      - path: Assets.xcassets       # required: include asset catalog here
    info:
      path: MyApp/Info.plist
      properties:
        CFBundleDisplayName: My App
        UILaunchScreen: {}
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
    settings:
      base:
        SWIFT_VERSION: "5.0"
        PRODUCT_BUNDLE_IDENTIFIER: com.example.myapp
        DEVELOPMENT_TEAM: ""
    dependencies:
      - framework: MapKit.framework  # only if MapKit is used
        embed: false

  MyAppTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: ../04-tests
    settings:
      base:
        SWIFT_VERSION: "5.0"
    dependencies:
      - target: MyApp
```
