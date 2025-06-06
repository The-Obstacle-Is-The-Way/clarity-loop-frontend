# Implementation Plan: HealthKit Integration

This document outlines the steps to integrate HealthKit into the CLARITY Pulse app. It covers creating a dedicated service, handling permissions, and fetching required health data.

## 1. HealthKit Service Setup

A dedicated service will encapsulate all HealthKit logic, abstracting its complexity from the rest of the app.

- [x] **Create `HealthKitService.swift`:** Place this file in `Core/Services`.
- [x] **Create `HealthKitServiceProtocol.swift`:** Define the public interface for the service.
- [x] **Initialize `HKHealthStore`:** The service should hold a single, private instance of `HKHealthStore`.
- [x] **Check for Availability:** Add a method `isHealthDataAvailable()` that returns `HKHealthStore.isHealthDataAvailable()`. The UI should use this to determine if HealthKit-related features should be shown at all (e.g., on an iPad, which doesn't have the Health app).
- [x] **Define Data Types:** Create a private property to hold the set of `HKObjectType`s the app needs to read.
    ```swift
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        // Add other types as needed by the backend analysis
    ]
    ```

## 2. Permissions Flow

- [x] **Implement `requestAuthorization()` method:**
    - [ ] Create an `async throws` method in `HealthKitService` to request user permission.
    - [ ] Call `healthStore.requestAuthorization(toShare:read:)` with an empty `share` set and the `readTypes` set.
    - [ ] Wrap the completion handler-based API with an `async` continuation to return a `Bool` indicating success or throw an error.
- [x] **Trigger Authorization Request:**
    - [ ] The request should be triggered at an appropriate time in the user flow, for example:
        - During an initial onboarding sequence.
        - When the user first navigates to the Dashboard.
    - [ ] Create a ViewModel (e.g., `OnboardingViewModel` or `DashboardViewModel`) that calls `healthKitService.requestAuthorization()`.
- [ ] **Handle Authorization Status:**
    - [ ] After the request, check the authorization status for each data type using `healthStore.authorizationStatus(for:)`.
    - [ ] The UI should gracefully handle cases where the user denies permission. For example, the Dashboard could show an informative message guiding the user to the Settings app to enable permissions if they are `denied`.

## 3. Data Fetching Methods

Implement methods in `HealthKitService` to fetch the specific metrics required by the application. These methods should be `async throws` and return either custom domain models or the DTOs needed for the backend.

- [x] **Wrap HealthKit Queries:** Since many HealthKit queries are still completion-based, create a generic helper to wrap them in an `async` call using `withCheckedThrowingContinuation`.
- [x] **Fetch Daily Step Count:**
    - [ ] Implement `fetchDailySteps(for date: Date) async throws -> Int`.
    - [ ] Use an `HKStatisticsQuery` to get the `.cumulativeSum` of `stepCount` for the given day (from midnight to midnight).
- [x] **Fetch Resting Heart Rate:**
    - [ ] Implement `fetchRestingHeartRate(for date: Date) async throws -> Double?`.
    - [ ] Query for `restingHeartRate` samples. This is typically one sample per day. Find the most recent sample for the given day.
- [x] **Fetch Sleep Analysis:**
    - [ ] Implement `fetchSleepAnalysis(for date: Date) async throws -> SleepData`. (*`SleepData` would be a custom struct holding total time, efficiency, etc.*)
    - [ ] Use an `HKSampleQuery` to fetch `HKCategorySample`s with the type `.sleepAnalysis`.
    - [ ] The query's predicate should cover the previous night (e.g., from noon yesterday to noon today).
    - [ ] Process the returned samples to calculate:
        - Total time in bed.
        - Total time asleep (sum of `.asleepUnspecified`, `.asleepCore`, `.asleepDeep`, `.asleepREM`).
        - Breakdown of time in each stage.
- [x] **Create a Unified Fetch Method:**
    - [ ] Implement a method like `fetchLatestMetrics() async throws -> HealthDataBatch`.
    - [ ] This method will use `async let` or a `TaskGroup` to concurrently execute the individual fetch methods (steps, heart rate, sleep, etc.).
    - [ ] It will aggregate the results into a single, structured object (`HealthDataBatch`) that can be easily used by the ViewModel or sent to the backend.

## 4. Background Delivery and Synchronization

- [ ] **Enable Background Delivery:**
    - [ ] Implement `enableBackgroundDelivery()` in `HealthKitService`.
    - [ ] This method will call `healthStore.enableBackgroundDelivery(for:frequency:withCompletion:)` for each data type you want to monitor. A frequency of `.hourly` is a reasonable starting point.
- [ ] **Set up Observer Queries:**
    - [ ] Implement `setupObserverQueries()` in `HealthKitService`.
    - [ ] For each data type, create an `HKObserverQuery`.
    - [ ] The query's `updateHandler` will be called by HealthKit when new data is available.
- [ ] **Handle Background Updates:**
    - [ ] The `updateHandler` of the observer query should not perform heavy work directly. Instead, it should schedule a background task.
    - [ ] Use `BGTaskScheduler` to submit a `BGProcessingTaskRequest`. This task will be responsible for fetching the new data and uploading it to the backend.
- [ ] **Integrate with App Delegate/Lifecycle:**
    - [ ] The background delivery setup (`enableBackgroundDelivery` and `setupObserverQueries`) should be called once the user is authenticated and has granted HealthKit permission. This could be done from the main `App` struct or an `AppDelegate`.
    - [ ] The app's launch sequence must register the background task identifiers with `BGTaskScheduler`. 