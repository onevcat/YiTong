# YiTong Web Wrapper Plan

**Goal:** Build a native Apple wrapper around `diffs.com` that exposes a small, stable API for SwiftUI, UIKit, and AppKit, while keeping all rendering inside `WKWebView`.

**Scope:**
- In: Swift package or Xcode package layout, `WKWebView`-backed renderer, SwiftUI/UIKit/AppKit adapters, local bundled web assets, patch-based rendering, basic host-to-web events.
- Out: Native diff parsing/rendering engine, side-by-side native layout, editing, source control integration, syntax highlighting beyond what `diffs.com` already provides.

**Why This Project Exists:**
- Apple platforms do not have a clear, modern, embeddable Git diff UI library.
- `diffs.com` already solves the hard rendering problem.
- A wrapper can turn a web renderer into a native-feeling component with a much smaller maintenance surface than a full native reimplementation.

**Product Shape:**
- `YiTongDiffView` for SwiftUI.
- `YiTongDiffViewController` for UIKit/AppKit.
- One internal renderer core that owns `WKWebView`, asset loading, message bridging, and lifecycle.
- A data model centered on `patch` input first, with room for richer file-based APIs later.

**Non-Goals for v1:**
- Re-implementing `diffs.com` in Swift.
- Supporting every patch variant from day one.
- Building a code review product.
- Exposing raw JavaScript concepts directly in the public Swift API.

**Recommended Public API Direction:**
- Keep the public API declarative and platform-native.
- Accept a unified diff `String` as the first supported input.
- Allow configuration through Swift structs/enums instead of JS snippets.
- Expose common callbacks such as file selection, line click, and load/error state.

```swift
public struct YiTongDiffConfiguration: Sendable {
  public var theme: YiTongTheme
  public var showsFileList: Bool
  public var allowsSelection: Bool
}

public struct YiTongPatchDocument: Sendable {
  public var patch: String
  public var title: String?
}

public struct YiTongDiffView: View {
  public init(
    document: YiTongPatchDocument,
    configuration: YiTongDiffConfiguration = .default,
    onEvent: ((YiTongDiffEvent) -> Void)? = nil
  )
}
```

**Architecture:**
- `YiTongCore`
  Responsible for `WKWebView`, local asset bootstrap, JS bridge, navigation policy, load state, and renderer versioning.
- `YiTongBridge`
  Translates Swift models into JSON payloads and translates JS messages back into typed Swift events.
- `YiTongUI`
  Hosts SwiftUI, UIKit, and AppKit adapters on top of the same core controller.
- `WebAssets`
  Bundled static HTML/CSS/JS built from `diffs.com` and loaded locally without a runtime Node dependency.

**Packaging Notes:**
- Prefer one repository with a Swift package for native code plus a small web asset build pipeline.
- Keep generated web assets checked in for deterministic Xcode builds unless asset churn becomes too noisy.
- Treat the bundled renderer version as an explicit compatibility boundary.

**Phase Plan:**

## Phase 0: Feasibility
- Verify `diffs.com` can be bundled as static local assets.
- Confirm the minimum JS API needed to render a patch and receive interaction events.
- Validate dark/light appearance, text selection, and scrolling behavior inside `WKWebView`.

## Phase 1: Core Wrapper
- Create a minimal internal web host that loads bundled assets.
- Inject a unified diff patch into the page and render it.
- Add typed load/error reporting.
- Add a native event bridge for basic interactions.

## Phase 2: Platform Surfaces
- Expose one SwiftUI component.
- Expose one UIKit view controller.
- Expose one AppKit view controller or view wrapper.
- Keep the three surfaces behaviorally aligned through shared tests where possible.

## Phase 3: Native Experience Layer
- Add native configuration types for theme, behavior, and future extensibility.
- Improve selection, copy, focus, keyboard behavior, and resizing.
- Define a stable API naming scheme before any public release.

## Phase 4: Distribution Readiness
- Add examples for SwiftUI, UIKit, and AppKit.
- Document asset update workflow for new `diffs.com` versions.
- Define semantic versioning policy and renderer compatibility policy.

**Key Risks:**
- `diffs.com` API churn may force wrapper changes.
- `WKWebView` behavior for keyboard, focus, and text selection may differ across SwiftUI/UIKit/AppKit hosts.
- Large patches may require explicit loading and memory guardrails.
- The wrapper can become a thin leak of web concepts unless the Swift API is curated carefully.

**Mitigations:**
- Keep the bridge payload small and versioned.
- Start with patch-only input to limit API surface.
- Treat asset updates as an explicit maintenance task, not an implicit dependency bump.
- Design public types around user intent, not renderer internals.

**Verification:**
- Manual sample app for SwiftUI, UIKit, and AppKit.
- Snapshot or smoke tests for view creation and loading state.
- Bridge tests for Swift-to-JS payload encoding and JS-to-Swift event decoding.
- Performance checks with small, medium, and large patches.

**First Decisions to Lock Down Next:**
- Repository layout: single package vs example workspace plus package.
- Asset strategy: checked-in built assets vs build-time generation.
- Event scope for v1: render only vs render plus interaction callbacks.
- Minimum supported OS versions.

**Suggested v1 Success Criteria:**
- A developer can render a unified diff in SwiftUI with fewer than ten lines of setup.
- The same renderer core can be hosted from UIKit and AppKit.
- No Node runtime is required at app runtime.
- Public API stays small enough to rewrite internals later without breaking adopters.
