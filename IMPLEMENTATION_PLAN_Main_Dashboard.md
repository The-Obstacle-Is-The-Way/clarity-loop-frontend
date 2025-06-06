# Implementation Plan: Main Dashboard

This document details the implementation of the main Dashboard screen, which serves as the central hub for the user to view their health metrics and AI-generated insights.

## 1. Dashboard ViewModel (`DashboardViewModel`)

This ViewModel will orchestrate the data flow for the dashboard.

- [ ] **Create `DashboardViewModel.swift`:** Place in `Features/Dashboard`.
- [ ] **Adopt `@Observable`:** Use the iOS 17 Observation framework for state management.
- [ ] **Inject Dependencies:**
    - [ ] Access `HealthDataRepositoryProtocol` and `HealthKitServiceProtocol` via `@Environment`.
- [ ] **Define State Properties:**
    - [ ] `viewState: ViewState<DashboardData>`: Use an enum (`.idle`, `.loading`, `.loaded(DashboardData)`, `.error(String)`) to manage the UI state.
    - [ ] `DashboardData` will be a struct containing all the data needed for the view, e.g., `dailySummary: HealthSummary`, `insightOfTheDay: InsightEntity?`.
- [ ] **Implement `loadDashboard()` method:**
    - [ ] This `async` method is the primary entry point for fetching data. It should be called from the view's `.task` modifier.
    - [ ] **Execution Flow:**
        1. Set `viewState = .loading`.
        2. In parallel (using `async let` or a `TaskGroup`):
            - Fetch the latest health metrics summary from the `HealthDataRepository`.
            - Fetch the "Insight of the Day" from the `InsightsRepository`.
        3. Await the results.
        4. On success, create a `DashboardData` object and set `viewState = .loaded(dashboardData)`.
        5. If no data is available, set `viewState = .empty`.
        6. On failure, catch the error and set `viewState = .error("A user-friendly error message")`.
- [ ] **Implement `refreshDashboard()` method:**
    - [ ] This `async` method will be called by the view's `.refreshable` modifier (pull-to-refresh).
    - [ ] It can simply call `await loadDashboard()`.

## 2. Dashboard View (`DashboardView`)

This SwiftUI view will render the dashboard UI based on the ViewModel's state.

- [ ] **Create `DashboardView.swift`:** Place in `Features/Dashboard`.
- [ ] **Instantiate ViewModel:** Use `@State` to create and hold the `DashboardViewModel`.
    ```swift
    @State private var viewModel = DashboardViewModel()
    ```
- [ ] **Implement View Body:**
    - [ ] Use a `ScrollView` as the main container to allow for vertical scrolling.
    - [ ] Use a `switch` statement on `viewModel.viewState` to render the correct UI for each state:
        - **`.loading`:** Display a full-screen `ProgressView` or a skeleton view with redacted placeholders.
        - **`.error(let message)**:** Display a reusable `ErrorView` with the error message and a "Retry" button that calls `viewModel.loadDashboard()`.
        - **`.empty**:** Display a reusable `EmptyStateView` with a message like "No health data available yet."
        - **`.loaded(let data)**:** Display the main dashboard content.
- [ ] **Attach Modifiers:**
    - [ ] `.task { await viewModel.loadDashboard() }` to trigger the initial data load.
    - [ ] `.refreshable { await viewModel.refreshDashboard() }` to enable pull-to-refresh.
- [ ] **Dashboard Layout (for `.loaded` state):**
    - [ ] Use a `VStack` with appropriate spacing.
    - [ ] **"Insight of the Day" Card:** At the top, display the featured insight using a custom `InsightCardView`.
    - [ ] **Health Metrics Section:**
        - Use a `LazyVGrid` to display multiple health metrics in a grid layout.
        - For each metric in `data.dailySummary`, use the reusable `HealthMetricCardView`.

## 3. Reusable UI Components

Create these components in the `UI/Components` group to ensure a consistent look and feel.

- [ ] **`HealthMetricCardView.swift`:**
    - [ ] Takes parameters like `title: String`, `value: String`, `unit: String?`, and an optional icon name.
    - [ ] Designs a visually distinct card (e.g., rounded rectangle with a background color and shadow).
    - [ ] This component is purely presentational.
- [ ] **`InsightCardView.swift`:**
    - [ ] Takes an `InsightEntity` or a simplified `InsightViewModel` as input.
    - [ ] Displays the insight's title/summary and a short narrative preview.
    - [ ] Should be tappable, allowing navigation to a full detail view.
- [ ] **`ErrorView.swift` / `EmptyStateView.swift`:**
    - [ ] Reusable views that take a title, message, and an optional action button (e.g., "Retry").

## 4. Navigation

- [ ] **Set up Navigation:** Wrap the `DashboardView` in a `NavigationStack`.
- [ ] **Navigate to Insight Detail:**
    - [ ] Make the `InsightCardView` a `NavigationLink`.
    - [ ] The link's destination should be `InsightDetailView(insight: selectedInsight)`.
- [ ] **Navigate to Metric Detail (Future):**
    - [ ] `HealthMetricCardView` can also be a `NavigationLink` to a detail view showing trends for that specific metric. 