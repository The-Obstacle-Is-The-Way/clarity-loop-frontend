# 📜 SwiftUI & Related API Deprecations (Post‑2024)

> **Why this file exists** → Any AI assistant trained ≤ 2024 is blind to the deprecations below. We ship **iOS 17+** only, so these calls are strictly forbidden. Use the **✅ replacements**.

---

## 1. Navigation & Routing

| ❌ **Deprecated API**                               | Deprecated Since | ✅ Use Instead                                                                                   | Sources                                                                                                                             |
| -------------------------------------------------- | ---------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `NavigationView`                                   | iOS 16           | `NavigationStack` or `NavigationSplitView`                                                      | ([developer.apple.com](https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types?utm_source=chatgpt.com)) |
| `NavigationLink(destination:isActive:label:)`      | iOS 16           | Value‑driven `NavigationLink(value:label:)` + `navigationDestination(isPresented:destination:)` | ([discuss.codecademy.com](https://discuss.codecademy.com/t/navigationlink-deprecated-in-ios-16/699301?utm_source=chatgpt.com))      |
| `NavigationLink(destination:tag:selection:label:)` | iOS 16           | Same value‑based navigation pattern                                                             | ([discuss.codecademy.com](https://discuss.codecademy.com/t/navigationlink-deprecated-in-ios-16/699301?utm_source=chatgpt.com))      |

---

## 2. State & Event Observations

| ❌ Deprecated API                              | Deprecated Since | ✅ Replacement                                                                        | Sources                                                                                                                                                                  |
| --------------------------------------------- | ---------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `onChange(of:perform:)` *(one‑param closure)* | iOS 17           | Two‑param `onChange(of:) { old, new in … }` or zero‑param variant                    | ([medium.com](https://medium.com/%40shakhnoza.mirabzalova1/understanding-onchange-of-perform-deprecation-in-ios-17-8158ef1ad28b?utm_source=chatgpt.com))                 |
| `traitCollectionDidChange(_:)` *(UIKit)*      | iOS 17           | `registerForTraitChanges(_:handler:)` or `registerForTraitChanges(_:target:action:)` | ([stackoverflow.com](https://stackoverflow.com/questions/77475103/traitcollectiondidchange-was-deprecated-in-ios-17-0-how-do-i-use-the-replacem?utm_source=chatgpt.com)) |

---

## 3. MapKit for SwiftUI

| ❌ Deprecated API                                                                                             | Deprecated Since | ✅ Replacement                                              | Sources                                                                                                                                                                  |
| ------------------------------------------------------------------------------------------------------------ | ---------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `MapAnnotation`                                                                                              | iOS 17           | `Annotation` + `Map` initializers with `MapContentBuilder` | ([stackoverflow.com](https://stackoverflow.com/questions/77293611/mapannotation-was-deprecated-in-ios-17-0-use-annotation-along-with-map-initia?utm_source=chatgpt.com)) |
| `Map(coordinateRegion:interactionModes:showsUserLocation:userTrackingMode:)` and similar region initializers | iOS 17           | `Map` with `MapCameraPosition` or content‑builder closure  | ([forums.swift.org](https://forums.swift.org/t/init-coordinateregion-i-was-deprecated-in-ios-17-0/65852?utm_source=chatgpt.com))                                         |

---

## 4. User Notifications & Badges

| ❌ Deprecated API                                  | Deprecated Since | ✅ Replacement                                                                | Sources                                                                                                                              |
| ------------------------------------------------- | ---------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `UIApplication.shared.applicationIconBadgeNumber` | iOS 17           | `UNUserNotificationCenter.current().setBadgeCount(_:withCompletionHandler:)` | ([reddit.com](https://www.reddit.com/r/SwiftUI/comments/18q56as/how_do_i_reset_the_badge_number_in_swiftui/?utm_source=chatgpt.com)) |

---

## 5. Text Input

| ❌ Deprecated TextField Initializers          | Deprecated In | ✅ Replacement                                              | Sources                                                                                                                                                               |
| -------------------------------------------- | ------------- | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `init(_:text:onEditingChanged:onCommit:)`    | iOS 18 (beta) | `init(_:text:)` then `.submitLabel(_:)` & `onSubmit { … }` | ([developer.apple.com](https://developer.apple.com/documentation/swiftui/textfield/init%28_%3Atext%3Aoneditingchanged%3Aoncommit%3A%29-588cl?utm_source=chatgpt.com)) |
| `init(_:value:formatter:prompt:)` & siblings | iOS 18 (beta) | `init(_:value:format:prompt:)`                             | ([developer.apple.com](https://developer.apple.com/documentation/swiftui/textfield/init%28_%3Atext%3Aoneditingchanged%3Aoncommit%3A%29-588cl?utm_source=chatgpt.com)) |

---

## Enforcement Checklist

1. **Xcode Build Setting** `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`.
2. **SwiftLint** rule `avoid_deprecated_swiftui` (regex covers terms above).
3. CI fails on any `deprecated:` in the build log.

---

### Last Verified

**June 6 2025** with Xcode 15.3 (iOS 17.5 SDK) and Xcode 16.0 beta 1 (iOS 18 SDK). Maintainer @ray.
