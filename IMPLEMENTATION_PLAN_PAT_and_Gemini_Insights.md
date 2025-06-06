# Implementation Plan: PAT Analysis & Gemini Insights

This document details the implementation of the UI and logic for displaying PAT (Pretrained Actigraphy Transformer) analysis results and the interactive Gemini AI chat interface.

## 1. PAT Analysis Display

This feature will present the detailed results from a PAT analysis job.

- [ ] **Create `PATAnalysisView.swift` and `PATAnalysisViewModel.swift`:** Place in `Features/Insights` or a new `Features/Analysis` folder.
- [ ] **ViewModel (`PATAnalysisViewModel`):**
    - [ ] Adopt `@Observable`.
    - [ ] Inject `APIClientProtocol` via `@Environment`.
    - [ ] Define state properties: `analysisState: ViewState<PATAnalysisResponseDTO>` and `analysisId: String`.
    - [ ] Implement `loadAnalysis()`:
        1. Sets state to `.loading`.
        2. Calls `apiClient.getPATAnalysis(id: analysisId)`.
        3. Polls the endpoint if the status is `"processing"`. Use a timer or a recursive `async` call with `Task.sleep`.
        4. On success (`"completed"`), sets state to `.loaded(response)`.
        5. On failure (`"failed"`), sets state to `.error(message)`.
- [ ] **View (`PATAnalysisView`):**
    - [ ] Takes an `analysisId` as input.
    - [ ] Uses a `switch` on `viewModel.analysisState` to render UI.
    - **Loading State:** Display a `ProgressView` with a message like "Analyzing your sleep data... This may take a moment."
    - **Error State:** Display the error message with a retry button.
    - **Loaded State:**
        - [ ] **Metrics Summary:** Use a `Grid` or `VStack` to display key metrics from `response.patFeatures` (e.g., Sleep Efficiency, WASO, TST) using the reusable `HealthMetricCardView`.
        - [ ] **Confidence Score:** Display the confidence score, perhaps using a SwiftUI `Gauge` view.
        - [ ] **Sleep Stage Hypnogram:**
            - [ ] Use the `Charts` framework from SwiftUI.
            - [ ] Create a `BarMark` or `RectangleMark` chart.
            - [ ] The X-axis represents time throughout the night.
            - [ ] The Y-axis represents the sleep stage (a categorical axis).
            - [ ] Map each stage in the `response.analysis.sleepStages` array to a colored bar on the chart. Define distinct, accessible colors for each stage (Awake, REM, Light, Deep).
        - [ ] **Clinical Insights:** Display the `clinical_insights` list from the response in a clearly formatted `List` or `VStack` of text views.

## 2. Proactive Insights History

This feature displays a list of previously generated insights.

- [ ] **Create `InsightsListView.swift` and `InsightsListViewModel.swift`:** Place in `Features/Insights`.
- [ ] **ViewModel (`InsightsListViewModel`):**
    - [ ] Adopt `@Observable`.
    - [ ] Use `@Environment` to inject the `APIClientProtocol`.
    - [ ] Define state: `insightsState: ViewState<[InsightPreviewDTO]>`.
    - [ ] Implement `loadHistory()`: Fetches the list of insights from `apiClient.getInsightHistory(...)` and updates the state.
- [ ] **View (`InsightsListView`):**
    - [ ] Use `.task` and `.refreshable` to call `viewModel.loadHistory()`.
    - [ ] `switch` on the `viewModel.insightsState` to show loading, error, empty, or loaded states.
    - [ ] For the loaded state, use a `List` to iterate over the `[InsightPreviewDTO]`.
    - [ ] **Insight Row:** Create a reusable `InsightRowView` that displays the `narrative` preview and `generatedAt` date.
    - [ ] **Navigation:** Each row should be a `NavigationLink` that navigates to a detail view for that insight.

(Note: The "Insight of the Day" card, a component of this feature, has been implemented on the main dashboard.)

## 3. On-Demand Gemini Chat Interface

This feature provides a conversational UI for users to ask questions about their health data.

- [ ] **Create `ChatView.swift` and `ChatViewModel.swift`:** Place in `Features/Insights`.
- [ ] **Define `ChatMessage` struct:**
    ```swift
    struct ChatMessage: Identifiable, Equatable {
        let id = UUID()
        let sender: Sender
        var text: String
        var isError: Bool = false

        enum Sender {
            case user, assistant
        }
    }
    ```
- [ ] **ViewModel (`ChatViewModel`):**
    - [ ] Adopt `@Observable`.
    - [ ] Inject `APIClientProtocol`.
    - [ ] Define state properties:
        - `messages: [ChatMessage]`
        - `currentInput: String = ""`
        - `isSending: Bool = false`
    - [ ] Implement `sendMessage()`:
        1. Guard that `currentInput` is not empty and `isSending` is false.
        2. Set `isSending = true`.
        3. Append the user's message to the `messages` array: `messages.append(.init(sender: .user, text: currentInput))`.
        4. Clear `currentInput`.
        5. Append a temporary "typing indicator" message: `messages.append(.init(sender: .assistant, text: "..."))`.
        6. Call the backend: `apiClient.generateInsights(...)` with the user's message in the `context` field.
        7. On success, remove the typing indicator and append the AI's response message.
        8. On failure, update the typing indicator message to show an error: `lastMessage.text = "Error..."; lastMessage.isError = true`.
        9. Set `isSending = false`.
- [ ] **View (`ChatView`):**
    - [ ] Use a `ScrollView` and `ScrollViewReader` to display messages and automatically scroll to the bottom.
    - [ ] Iterate through `viewModel.messages` using `ForEach`.
    - [ ] **Message Bubble:** Use a reusable `MessageBubbleView` that styles the message based on the `sender` and `isError` properties (e.g., different alignment and colors).
    - [ ] **Input Area:**
        - At the bottom, create an `HStack` with a `TextField` bound to `viewModel.currentInput`.
        - Add a "Send" `Button`. The button should be disabled when `viewModel.isSending` is true or `currentInput` is empty.
        - The button's action calls `viewModel.sendMessage()`.
    - [ ] **Typing Indicator:** The `MessageBubbleView` for the assistant's temporary message should display an animated ellipsis or `ProgressView` if the text is `"..."`. 