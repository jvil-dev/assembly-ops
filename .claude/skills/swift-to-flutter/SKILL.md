---
name: swift-to-flutter
description: Design patterns from the existing SwiftUI iOS app that must be followed when writing Flutter code. Covers architecture, state management, navigation, theming, networking, and file organization. Activates when writing Dart/Flutter code for AssemblyOps.
user-invocable: false
---

# SwiftUI → Flutter Pattern Guide

The AssemblyOps iOS app (604 Swift files) follows mature MVVM patterns. All Flutter code must mirror these patterns using Flutter equivalents.

## Architecture: MVVM

| SwiftUI                      | Flutter                                            |
| ---------------------------- | -------------------------------------------------- |
| View (.swift)                | Widget (.dart)                                     |
| ViewModel (ObservableObject) | ChangeNotifier / StateNotifier / Riverpod provider |
| Service (async/await)        | Repository class with GraphQL client               |
| Model (struct)               | Freezed / data class                               |

Every feature has three layers: **Widget** (UI only) → **ViewModel/Provider** (state + logic) → **Service/Repository** (API calls). Views never call GraphQL directly.

## State Management

| SwiftUI                       | Flutter                                           |
| ----------------------------- | ------------------------------------------------- |
| `@StateObject` (local VM)     | `ChangeNotifierProvider` or `ref.watch(provider)` |
| `@EnvironmentObject` (global) | `Provider` at app root or Riverpod `ref`          |
| `@Published var`              | `notifyListeners()` or Riverpod state             |
| `@State` (local UI)           | `useState` hook or `StatefulWidget`               |

### Global State Singletons (must exist in Flutter):

- **AppState** — auth state, current user, isLoggedIn, tokens
- **EventSessionState** — selected event, selected department, claimed department
- **MessageBadgeManager** — unread message counts
- **PendingBadgeManager** — pending assignment counts
- **PushNotificationManager** — FCM token, deep linking
- **LocalizationManager** — English/Spanish support
- **NetworkMonitor** — connectivity status

## Navigation

| SwiftUI            | Flutter                                  |
| ------------------ | ---------------------------------------- |
| NavigationStack    | GoRouter or Navigator 2.0                |
| NavigationLink     | `context.push()` / `context.go()`        |
| TabView            | BottomNavigationBar / NavigationBar      |
| .sheet()           | `showModalBottomSheet()`                 |
| .fullScreenCover() | `Navigator.push(MaterialPageRoute(...))` |
| .alert()           | `showDialog()` with AlertDialog          |

### Navigation Flow:

```
Splash → (not logged in) → Landing → Login/Register
       → (logged in) → EventsHub → EventTabView
                                     ├─ Home tab
                                     ├─ Department tab (role-specific)
                                     ├─ Schedule/Coverage tab
                                     └─ Messages tab
```

### Tab content varies by role:

- **Volunteer**: Schedule (assignments list) + Inbox
- **Overseer**: Coverage matrix + Full messaging + Department management

## CRITICAL: Department-Scoped Theming

**The app does NOT use a single global theme for department views.** Each department has its own color scheme based on lanyard colors.

### App Theme (AppTheme) — ONLY for non-department views:

Used in: Login, Registration, Landing, Event Hub, Settings, Profile

### Department Theme — for ALL views inside a department context:

Once a user enters a department (via EventTabView), the department's color becomes the accent/primary color for:

- Tab bar tint
- Card accents and borders
- Button colors
- Status indicators
- Background tints (department color at 15% opacity)

### Department Color Map (15 departments):

| Department   | Color Name   | Icon             |
| ------------ | ------------ | ---------------- |
| PARKING      | Yellow       | car              |
| ATTENDANT    | Orange       | shield_person    |
| AUDIO        | Blue-Green   | speaker          |
| VIDEO        | Teal         | videocam         |
| STAGE        | Purple       | lightbulb        |
| CLEANING     | Teal         | auto_awesome     |
| COMMITTEE    | White        | groups           |
| FIRST_AID    | Red          | medical_services |
| BAPTISM      | Light Blue   | water_drop       |
| INFORMATION  | Brown        | info             |
| ACCOUNTS     | Forest Green | attach_money     |
| INSTALLATION | Slate        | build            |
| LOST_FOUND   | Purple       | inventory_2      |
| ROOMING      | Indigo       | hotel            |
| TRUCKING     | Charcoal     | local_shipping   |
| DEFAULT      | Gray         | business         |

### Flutter Implementation:

```dart
// Department color should be passed down via Theme or InheritedWidget
// Use ThemeData.copyWith() to override primary/accent per department
ThemeData departmentTheme(DepartmentType type, Brightness brightness) {
  final color = departmentColor(type);
  return baseTheme(brightness).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: color, brightness: brightness),
  );
}
```

## Design Tokens

### Spacing

| Token       | Value |
| ----------- | ----- |
| xs          | 4     |
| s           | 8     |
| m           | 12    |
| l           | 16    |
| xl          | 24    |
| xxl         | 32    |
| screenEdge  | 20    |
| cardPadding | 20    |

### Typography (use Google Fonts or system)

| Style       | Size | Weight   |
| ----------- | ---- | -------- |
| largeTitle  | 28   | semibold |
| title       | 22   | semibold |
| headline    | 17   | semibold |
| body        | 17   | regular  |
| subheadline | 15   | regular  |
| caption     | 13   | regular  |

### Corner Radii

| Token  | Value       |
| ------ | ----------- |
| large  | 24 (modals) |
| medium | 16 (cards)  |
| button | 14          |
| small  | 12          |
| badge  | 8           |
| pill   | 100         |

### Shadows

| Token         | Radius | Opacity |
| ------------- | ------ | ------- |
| cardPrimary   | 20     | 0.06    |
| cardSecondary | 8      | 0.04    |
| subtle        | 4      | 0.05    |

### Animations

| Token    | Duration                    | Curve     |
| -------- | --------------------------- | --------- |
| entrance | 500ms                       | easeOut   |
| quick    | 200ms                       | easeInOut |
| spring   | 400ms response, 0.7 damping | spring    |

### Status Colors

| Status   | Color  |
| -------- | ------ |
| Pending  | Orange |
| Accepted | Green  |
| Declined | Red    |
| Info     | Blue   |

## GraphQL Networking

| SwiftUI (Apollo iOS)        | Flutter                               |
| --------------------------- | ------------------------------------- |
| NetworkClient (singleton)   | GraphQL client singleton              |
| AuthTokenInterceptor        | Link chain with auth link             |
| WebSocketTransport          | WebSocket link for subscriptions      |
| `client.fetch(query:)`      | `client.query(QueryOptions(...))`     |
| `client.perform(mutation:)` | `client.mutate(MutationOptions(...))` |

### Auth Token Flow:

1. Store tokens in secure storage (flutter_secure_storage)
2. Auth link injects Bearer token on every request
3. On 401/token expiry: refresh token automatically
4. On refresh failure: post auth expired event → logout

### Endpoints:

- Dev: `http://localhost:4000/graphql`
- Prod: `https://api.assemblyops.org/graphql`
- WebSocket: same host, `ws://` or `wss://` protocol

## File Organization

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp + router
│   ├── app_state.dart              # Global auth state
│   └── theme/
│       ├── app_theme.dart          # Base theme (non-department views)
│       ├── department_theme.dart   # Per-department theme overrides
│       ├── spacing.dart            # Spacing constants
│       └── typography.dart         # Text styles
├── core/
│   ├── models/                     # Data classes (freezed)
│   ├── network/                    # GraphQL client, auth link
│   ├── services/                   # API service classes
│   ├── storage/                    # Secure storage, caching
│   └── utils/                      # DateUtils, HapticUtils, etc.
├── features/
│   ├── auth/
│   │   ├── views/                  # LoginPage, RegisterPage
│   │   └── viewmodels/             # LoginViewModel, etc.
│   ├── home/
│   │   ├── views/                  # EventsHubPage, EventTabPage
│   │   └── viewmodels/             # EventsHomeViewModel, EventSessionState
│   ├── assignments/
│   │   ├── views/                  # AssignmentsList, AssignmentDetail
│   │   └── viewmodels/             # AssignmentsViewModel
│   ├── departments/
│   │   ├── attendant/              # Department-specific features
│   │   └── volunteer/
│   ├── messages/
│   │   ├── views/
│   │   └── viewmodels/
│   └── settings/
│       └── views/                  # ProfilePage, SettingsPage
├── shared/
│   └── widgets/                    # Reusable components
│       ├── loading_view.dart
│       ├── error_view.dart
│       ├── offline_banner.dart
│       └── assignment_card.dart
└── l10n/                           # Localization (en, es)
```

## Reusable Component Patterns

Every reusable widget should handle three states:

1. **Loading** — show shimmer or spinner
2. **Error** — show error message with retry button
3. **Empty** — show meaningful empty state

### View Extensions (Swift) → Widget Wrappers (Flutter):

| Swift                  | Flutter                                                    |
| ---------------------- | ---------------------------------------------------------- |
| `.themedBackground()`  | `ThemedBackground` widget or `Container` with gradient     |
| `.themedCard()`        | `ThemedCard` widget with shadow + radius                   |
| `.entranceAnimation()` | `AnimatedOpacity` + `SlideTransition`                      |
| `.cardPadding()`       | `Padding(padding: EdgeInsets.all(AppSpacing.cardPadding))` |

## Error Handling

- ViewModels expose `String? errorMessage` — widgets show `AlertDialog` when set
- Services throw typed exceptions (NetworkException, AuthException)
- Global auth errors trigger logout via event bus
- Network failures fall back to cached data with `isUsingCache` indicator
- `OfflineBanner` widget shown when NetworkMonitor detects no connectivity

## i18n

- Support English and Spanish
- Use Flutter's built-in `intl` package or `easy_localization`
- All user-facing strings must be localized — no hardcoded text

## Haptic Feedback

Integrate haptic feedback on key interactions:

- Light tap on button presses
- Success feedback on saves/submissions
- Error feedback on validation failures
