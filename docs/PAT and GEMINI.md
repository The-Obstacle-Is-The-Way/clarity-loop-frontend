# Integrating PAT and Gemini AI Services into CLARITY Pulse (iOS)

## PAT Analysis Display

**UI/UX Visualization:** The PAT (Pretrained Actigraphy Transformer) analysis results should be presented in a clear, insightful manner. Key metrics like **sleep efficiency**, **sleep latency**, **WASO** (wake after sleep onset), **total sleep time**, **circadian rhythm score**, and **depression risk score** should be highlighted in the UI. Display these metrics in a concise summary section – for example, as labeled values or small cards – so users can quickly grasp their sleep quality. Visualize the **sleep stages** timeline using a chart or graph: a **sleep stage hypnogram** can show stages (e.g. Awake, Light, Deep, REM) over the course of the night, using distinct colors for each stage. Apple’s Human Interface Guidelines recommend using charts to communicate data clearly; an effective chart highlights key information and helps users gain insights at a glance. Leverage **SwiftUI Charts** (iOS 16+) with a custom Y-axis domain for categorical sleep stages and a time-based X-axis (hours of night) to recreate a chart similar to Apple’s Health app. For example, use a `LineMark` or `RectangleMark` for each sleep stage segment, and fill underneath to distinguish stages visually. Accompany the chart with a legend or labels for each stage to ensure clarity for the user.

**Confidence Score & Insights:** Prominently display the model’s **confidence score** (0–1 from the PAT output) to indicate how reliable the prediction is. This could be shown as a percentage (e.g. *“Model Confidence: 85%”*) or as a small circular **Gauge** in SwiftUI (with the needle or ring indicating confidence level). Use color or iconography (for example, a checkmark or warning symbol) to emphasize high vs. low confidence in a subtle, HIG-compliant way (e.g. green for high confidence, yellow for moderate). Below the main metrics, provide **Key Insights** derived from the analysis. The PAT model returns a list of `clinical_insights` which are human-readable interpretations of the data – present these as a bulleted list or as separate info cards. For instance, if an insight says *“Sleep efficiency is below ideal range”*, show that as a bullet with a small lightbulb icon to highlight it as an insight. Keep insight text short and clear, using plain language. Ensure this section is visually separate (e.g. a **“Insights”** header) and uses a readable text style (dynamic type for accessibility). Users should be able to scan these insights easily, so use concise sentences and consider bolding key terms (like *“sleep efficiency”*) for quick identification.

**Data Flow (Fetching & Rendering):** The PAT analysis data will flow from the backend API to SwiftUI views using modern async/await patterns. On app startup or when the user navigates to the **PAT Analysis screen**, initiate an asynchronous fetch of the analysis results. For example, use an `async` method in a view model (or directly in a SwiftUI `.task` modifier) to call the PAT analysis endpoint. The request might be a GET to `/pat/analysis/{id}` if an analysis was previously initiated, or a POST to start a new analysis. Using Swift’s `URLSession`, perform `try await` on the data task to retrieve a JSON payload. Decode the JSON into Swift model types using `JSONDecoder` (with `.keyDecodingStrategy = .convertFromSnakeCase` to map Pydantic snake\_case to Swift camelCase). **Swift Concurrency** makes it easy to update UI after fetching: for example, in `AnalysisViewModel`, you might have:

```swift
@Observable class AnalysisViewModel {
    var analysis: PATAnalysis?    // model to hold analysis results
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func loadAnalysis(id: String) async {
        do {
            DispatchQueue.main.async { self.isLoading = true }
            let (data, _) = try await URLSession.shared.data(from: analysisURL(for: id))
            let result = try JSONDecoder().decode(PATAnalysisResponse.self, from: data)
            DispatchQueue.main.async {
                self.isLoading = false
                if result.status == "completed", let analysisData = result.analysis {
                    self.analysis = analysisData
                } else if result.status == "failed" {
                    self.errorMessage = result.message ?? "Analysis failed."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Network error: \(error.localizedDescription)"
            }
        }
    }
}
```

In SwiftUI, the view can use an `@StateObject` or the new **Observation** framework (iOS 17+) to watch this view model. For example, mark `AnalysisViewModel` as `@Observable` (from the Observation framework) so that changes to `analysis` or `isLoading` automatically trigger view updates. The view might call `viewModel.loadAnalysis()` inside a `.task` when it appears. Once the data arrives, the SwiftUI view binds to `viewModel.analysis` to populate UI components (text fields, charts, etc.). This **unidirectional data flow** ensures the UI always reflects the latest analysis state. If the PAT analysis must be initiated by the user (say by tapping a “Analyze” button), perform the above async call on button press, then render the results.

**Swift Data Models:** Define Swift data transfer objects (DTOs) mirroring the backend’s Pydantic models so decoding is straightforward. For instance, based on the backend’s `ActigraphyAnalysis` model, you can create Swift structs:

```swift
struct ActigraphyAnalysis: Codable {
    let userId: String
    let analysisTimestamp: String
    let sleepEfficiency: Double       // 0-100
    let sleepOnsetLatency: Double     // minutes
    let wakeAfterSleepOnset: Double   // minutes
    let totalSleepTime: Double        // hours
    let circadianRhythmScore: Double  // 0-1
    let activityFragmentation: Double
    let depressionRiskScore: Double   // 0-1
    let sleepStages: [String]         // e.g. ["Awake","Light",...]
    let confidenceScore: Double       // 0-1
    let clinicalInsights: [String]    // interpretations
    // (embedding vector omitted for UI)
}
```

Additionally, the API’s response wrapper can be represented. The POST analysis endpoint returns an `AnalysisResponse` with status and possibly the analysis embedded, while the GET endpoint returns a `PATAnalysisResponse` with similar fields. You might define:

```swift
struct PATAnalysisResponse: Codable {
    let processingId: String
    let status: String              // "completed", "processing", "failed", etc.
    let message: String?
    let analysisDate: String?
    let patFeatures: [String: Double]?
    let activityEmbedding: [Double]?
    let metadata: [String: CodableValue]?  // if various nested data
    let analysis: ActigraphyAnalysis?      // include if using direct analysis result
}
```

In practice, if you use the **OpenAPI schema or Pydantic models** as reference, ensure the Swift model’s property names match the JSON keys (using CodingKeys or convertFromSnakeCase strategy). Having these models allows you to use `JSONDecoder` to decode directly into Swift structures, enabling type-safe access to fields like `sleepStages` and `clinicalInsights`. This way, the SwiftUI views can easily bind to properties (for example, iterate over `analysis.sleepStages` to plot the chart, or show `analysis.sleepEfficiency` in a Text view).

For visualization, once `analysis` is non-nil, construct the UI: e.g. a `Chart` view for sleep stages (with time on X-axis and stage on Y-axis), `Text` views for each key metric (perhaps using **`Gauge`** or progress bars for percent metrics), and a `ForEach` over `analysis.clinicalInsights` to display each insight. Make sure to follow HIG by using clear labels (e.g. "Sleep Efficiency") and units (minutes, hours, %). The overall layout might be a scrollable `VStack` containing a card or section for the chart, a grid or horizontal stack of metric summaries, and an insights list below.

## Gemini AI Insights Presentation

### Proactive “Insight of the Day” Display

**UI/UX for Insight Cards:** Introduce a section in the app (perhaps on a Dashboard or a dedicated **Insights tab**) that features AI-generated health insights from the **Gemini** service. A recommended approach is to have an **“Insight of the Day” card** – a prominent, visually highlighted card showing the latest or most relevant insight. This card could show a brief summary or title of the insight and a short description. For example, if Gemini has identified a notable trend (e.g. *“Your average sleep duration increased this week”*), the card’s title might be *“Insight of the Day: Sleep Duration”* with a one-sentence summary. Use a **SwiftUI Card-style** design: a rounded rectangle container with a subtle shadow, following HIG principles for content cards. Inside, use a combination of Text (for the insight summary) and perhaps an icon or illustration that represents the category (sleep, activity, etc.) to add visual appeal. Ensure the card design uses **accessible color contrast** and is not overly cluttered – one or two sentences maximum, so it’s glanceable.

**Scrollable Insights List:** Below the featured card, provide a scrollable list of recent insights (the **insight history**). Each insight in the list can be a smaller row or card showing a preview. For instance, display the insight’s date (or relative time, like *“2 days ago”*), a short snippet of the narrative or the key takeaway, and maybe a small icon indicating its category (e.g., a moon icon for sleep-related insight). The backend’s history API returns a list with each insight’s `id`, a truncated `narrative` preview, timestamp, and even counts of key insights/recommendations. You can use this to populate the list. In SwiftUI, this might be a `List` or a `ScrollView` with `VStack` of custom row views. For example:

* **Insight Row:** Show the insight’s title or a highlight of the content (if the narrative is long, you might take the first sentence or a “key insight” phrase). Possibly bold the most important keyword (e.g., *“sleep efficiency improved”*). Show the date and maybe the confidence score if it’s meaningful to the user (perhaps as a small meter or percentage in the corner).
* **Navigation:** Make each insight row tappable. On tap, navigate to a detail view that shows the full **Insight Detail** (the full narrative and any recommendations). Using SwiftUI’s `NavigationStack`, tapping a row can push a `InsightDetailView` which calls `GET /insights/{id}` to fetch the full content if not already available. The detail view will display the complete **narrative** (the AI-generated explanation) and possibly list the **key\_insights** and **recommendations** separately in a structured way (e.g., bullet points for key insights and another section for actionable recommendations, if provided by Gemini). This separation helps users digest the AI output: narrative gives context, and bullet points give succinct points.

The design should align with Apple’s guidelines for readability: use a comfortable font size (support Dynamic Type), and spacing between list items. Keep the list background plain or grouped style for a clean look. Users should be able to scroll through past insights easily, so ensure performance by using identifiers (the insight `id` as `List` row identifiers).

**Fetching Insights Data:** The app will use the Gemini Insights API to populate these views. On app launch (or when the Insights tab is shown), you might call the **GET `/insights/history/{user}`** endpoint to retrieve recent insights. This will return a list of insight summaries which you decode into an array of Swift model objects. Define a Swift model to match the response structure. For example:

```swift
struct InsightSummary: Codable, Identifiable {
    let id: String
    let narrative: String    // truncated narrative or summary
    let generatedAt: Date    // or String, representing timestamp
    let confidenceScore: Double
    // Optionally, counts or flags for insights/recommendations
}
struct InsightHistoryResponse: Codable {
    let success: Bool
    let data: InsightHistoryData
}
struct InsightHistoryData: Codable {
    let insights: [InsightSummary]
    // pagination fields like totalCount, etc., can be included if needed
}
```

When the history API responds, decode it and store the `[InsightSummary]` in an observable view model (e.g., `InsightsViewModel`). The featured “Insight of the Day” can simply be the first item of this list (if sorted by date) – i.e., the most recent insight. Use that to populate the featured card view. (If the list is empty or the call fails, the card can show a placeholder or a friendly message like “No insights available yet.”)

**Interaction Design:** Users can interact with the insight card and list in intuitive ways. Tapping the **Insight of the Day card** could navigate to the same detail view as tapping a list item, showing the full context of that insight. Alternatively, the card might flip or expand to show more (though a simple navigation is easier and aligns with standard patterns). For the list, standard **pull-to-refresh** can be enabled (SwiftUI provides `.refreshable` on List) to allow users to manually fetch the latest insights on demand. The UI should also guide users if no insights exist: for instance, if the user hasn’t generated any insights yet, show an empty state (maybe a message like *“No insights yet – your AI insights will appear here after you connect your health data.”*). This ensures the section is not confusing when blank.

### On-Demand Chat Interface (MVP)

**Architecture & State Management:** For a more interactive experience, implement a basic **chat interface** where users can ask questions about their health data and receive AI answers from Gemini. The chat UI will consist of a scrollable conversation view and an input text field. Create a view model such as `ChatViewModel` marked with `@Observable` (iOS 17’s Observation API) or as an `ObservableObject` (for earlier iOS versions) to manage the state of the conversation. The view model holds an array of `Message` objects, where a `Message` might be a struct like:

```swift
struct Message: Identifiable {
    enum Sender { case user, assistant }
    let id = UUID()
    let sender: Sender
    let text: String
}
```

The `ChatViewModel` will have a `messages: [Message]` property and methods to send a new query. Using the Observation API, changes to `messages` will automatically update the SwiftUI view. This avoids the need for Redux-style or Combine publishers – we rely on SwiftUI’s state management for simplicity.

**SwiftUI Chat UI:** Construct the chat interface using a `VStack` or `List` that iterates through `viewModel.messages`. Each message can be displayed in a bubble style: use a `HStack` alignment based on sender (e.g., user messages aligned to trailing right side in a blue bubble, assistant messages aligned to leading left side in a gray bubble – similar to iMessage style, but tweak colors to match the app’s design language). SwiftUI makes it easy to style bubbles: for example, a Text with `.padding(10)` and `.background(Color.blue)` with `.cornerRadius(16)` could represent a user bubble (and use `.foregroundColor(.white)` for text color), whereas the assistant’s bubble could be a different color (e.g. gray or secondary system fill). Ensure that these color choices meet accessibility contrast standards and consider using system colors (which adapt to dark mode automatically).

Place an input field at the bottom of the screen for user text entry. In SwiftUI, you might use a `TextField` or `TextEditor` bound to a @State string (e.g., `@State private var inputText = ""`). Also include a **Send** button (or use the return key on the keyboard) to submit the query. The input area can be anchored above the keyboard using `.padding` with `.safeAreaInset` if needed, so it’s not obscured.

**Async Message Handling:** When the user sends a question, update the UI optimistically and call the Gemini API. For example:

1. User taps send (or presses return) – take the `inputText`, append a new `Message(id: UUID(), sender: .user, text: inputText)` to `viewModel.messages`, and clear the input field.

2. Immediately also append a temporary placeholder `Message` for the assistant with something like `"..."` or an empty text to indicate a response is coming (this can be used to show a typing indicator).

3. In `ChatViewModel.sendQuery(_ question: String)`, perform the network call to Gemini in an async task. You will call the POST `insights/generate` endpoint with a **InsightGenerationRequest**. This request needs the user’s analysis data and the question context. The `analysis_results` could be the latest PAT analysis results formatted as a dictionary (or you may send references/IDs depending on backend support). Include the user’s question as the `context` field in the request. For `insight_type`, perhaps use `"comprehensive"` or `"brief"` depending on how detailed you want the answer (for a single question, “brief” might suffice, whereas “comprehensive” might return a full report).

4. Await the API response. On success, you’ll get an `InsightGenerationResponse` containing `data` which is a `HealthInsightResponse`. This includes a `narrative` (likely the answer text) and possibly lists of `key_insights` or `recommendations` if the model returns them. For a direct Q\&A, the narrative itself might contain the answer to the question. Decode this JSON into a Swift model, e.g.:

```swift
struct InsightGenerationResponse: Codable {
    let success: Bool
    let data: Insight
}
struct Insight: Codable {
    let narrative: String
    let keyInsights: [String]
    let recommendations: [String]
    let confidenceScore: Double
    let generatedAt: String
}
```

Now, back on the main thread, remove the placeholder message (or update it in place) and append a new `Message(sender: .assistant, text: insight.narrative)` to `messages`. This will display the AI’s answer in the chat bubble UI. The entire send-and-receive logic can be done within an `async` Task initiated in the send button action.

Because we are using `async/await`, the code is straightforward and avoids callback hell. For instance:

```swift
func sendQuery(_ question: String) {
    let userMsg = Message(sender: .user, text: question)
    messages.append(userMsg)
    messages.append(Message(sender: .assistant, text: "…"))  // placeholder
    Task {
       // Prepare request body
       let req = InsightGenerationRequest(analysisResults: latestAnalysisDict,
                                         context: question, insightType: "brief")
       if let data = try? JSONEncoder().encode(req),
          let url = URL(string: baseURL + "/insights/generate") {
           var request = URLRequest(url: url)
           request.method = .post
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           request.httpBody = data
           if let (responseData, _) = try? await URLSession.shared.data(for: request) {
               if let insightResp = try? JSONDecoder().decode(InsightGenerationResponse.self, from: responseData),
                  insightResp.success {
                   let answerText = insightResp.data.narrative
                   DispatchQueue.main.async {
                       // Remove placeholder
                       if let placeholderIndex = messages.firstIndex(where: { $0.text == "…" }) {
                           messages.remove(at: placeholderIndex)
                       }
                       messages.append(Message(sender: .assistant, text: answerText))
                   }
               } else {
                   handleInsightError()
               }
           } else {
               handleInsightError()
           }
       }
    }
}
```

This pseudocode shows the flow: append user message, placeholder, then call API and update. By using an `@Observable` view model or an `@StateObject` with `@Published` properties, the SwiftUI view will automatically refresh when `messages` changes. The chat interface remains responsive and aligned with iOS design paradigms. **Observation** (iOS 17+) in particular allows state changes without manually sending objectWillChange events – marking the class with `@Observable` is enough for SwiftUI to track changes.

**User Experience:** The chat should resemble a conversation with a health assistant. Keep the experience simple: the user asks in natural language, and the answer appears. You could optionally prefix the assistant’s answer with a persona name or icon (e.g., a small avatar icon in the bubble) to make it clear it’s coming from an AI assistant. Allow the user to scroll up to review past Q\&A in the session. Each new session could start fresh or optionally persist history between app launches (depending on product decisions). For MVP, it’s fine to keep it in-memory per session.

## Data Models for AI Insights

To integrate with the Gemini service, define Swift data models that mirror the backend’s insight response structures. This ensures type-safe decoding and easy usage of the data in SwiftUI. Key models include:

* **Insight Generation Request:** (for sending queries or generation requests) – This might include the analysis results and context. You can define it if needed for encoding the request JSON:

  ```swift
  struct InsightGenerationRequest: Encodable {
      let analysisResults: [String: Codable]   // or more specific type if known
      let context: String?                    // user question or additional context
      let insightType: String                 // e.g., "comprehensive" or "brief"
      let includeRecommendations: Bool        // if toggling recommendations
      let language: String                    // e.g., "en"
  }
  ```

  This corresponds to the Pydantic model on the backend. Often, `analysisResults` can be a dictionary of the PAT metrics; in Swift, you might use `[String: Any]` with a custom encoder or define a proper Codable structure that encompasses possible fields (for example, reuse `ActigraphyAnalysis` or a subset as the analysisResults content). For simplicity, you might send the latest `ActigraphyAnalysis` converted to a dictionary.

* **Insight (Detailed):** Represents a full AI-generated insight (matching **HealthInsightResponse** from backend). For decoding responses:

  ```swift
  struct Insight: Codable {
      let narrative: String            // full narrative text explaining the insight
      let keyInsights: [String]        // bullet-point key insights
      let recommendations: [String]    // bullet-point recommendations for user
      let confidenceScore: Double      // 0-1 confidence from the model
      let generatedAt: Date            // timestamp of generation
  }
  ```

  This aligns with the backend’s `HealthInsightResponse` which includes narrative, key\_insights, recommendations, etc.. You can parse `generated_at` into a `Date` using an ISO8601 date decoder for convenience in Swift.

* **InsightGenerationResponse:** The wrapper returned by the `/insights/generate` endpoint. Define it to capture the success flag and the embedded insight:

  ```swift
  struct InsightGenerationResponse: Codable {
      let success: Bool
      let data: Insight    // the generated insight content
      let metadata: InsightMetadata?   // optional, if you want to capture request_id, etc.
  }
  struct InsightMetadata: Codable {
      let requestId: String
      let timestamp: Date
      let service: String
      // ... any other fields from metadata (processing_time_ms, version, etc.)
  }
  ```

  The `metadata` isn’t strictly needed for UI, but it could be logged or used for debugging. The `success` flag helps decide error handling.

* **Insight Summary (for History):** As defined earlier, for list displays:

  ```swift
  struct InsightSummary: Codable, Identifiable {
      let id: String
      let narrative: String       // possibly truncated preview
      let generatedAt: Date
      let confidenceScore: Double
      let keyInsightsCount: Int?  // number of key insights (if provided by API)
      let recommendationsCount: Int?
  }
  ```

  The backend history returns each insight summary with fields like `id`, `narrative` (truncated), `generated_at`, etc.. We include counts of insights and recommendations if needed (this could be used to e.g. display a small badge like “3 insights, 2 recs” in a detail view, or simply ignored in the list).

  Additionally, a wrapper for the history response:

  ```swift
  struct InsightHistoryResponse: Codable {
      let success: Bool
      let data: InsightHistoryData
  }
  struct InsightHistoryData: Codable {
      let insights: [InsightSummary]
      let totalCount: Int
      let hasMore: Bool
      let pagination: Pagination
  }
  struct Pagination: Codable {
      let limit: Int
      let offset: Int
      let currentPage: Int
      let totalPages: Int
  }
  ```

  This helps decode the `/insights/history` output. The app can use this to display all insights and implement paging if needed (for a first version, simply showing the first page of results might be enough, with the option to load more if `hasMore` is true).

By defining these DTOs, the integration with the backend becomes easier. The app’s networking layer can decode JSON directly into these structs. For instance, when the user opens the Insights tab, you fetch the history and decode into `InsightHistoryResponse`. If `response.success` is true, you take `response.data.insights` to populate the list. When the user requests a new insight or asks a question, decode the `InsightGenerationResponse` to get the `Insight` (narrative and other details) for display. These Swift models ensure the app stays in sync with the backend contract; if the backend changes (e.g., adds a field), updating the Swift model will handle it.

## User Interaction Design

**Proactive Insights (Daily Card & List):** Users encounter the AI insights in a digestible, non-intrusive way. The **Insight of the Day** card appears at a prominent location (e.g., top of Insights screen or on the home dashboard). It should invite interaction – for example, label it “Insight of the Day” to cue the user, and allow a tap to see more details. Consider adding a small chevron or “Learn more” link on the card to indicate it’s actionable. Swiping the card left/right could be utilized in future (e.g., to dismiss or flip through multiple insights), but for MVP a simple tap is sufficient. The **insights list** allows users to explore historical insights at their own pace. They can scroll vertically through past insights – ensure the scrolling is smooth. Each insight entry can be tapped to navigate to a detail page. This detail page might show the full narrative with a richer layout (multi-line text, separators between narrative, key points, and recommendations for clarity). Provide a **Back** button (via NavigationStack) to return to the list or main screen.

For the list items, you might implement swipe actions for secondary interactions. For instance, a swipe-left on an insight row could reveal a “Delete” action if users want to remove an insight from history. However, be cautious with destructive actions – unless there is a clear need to allow deletion, you might omit it initially. Another idea is swipe-right to “share” an insight – iOS allows a ShareSheet to share text. This could be valuable if a user wants to share an insight (e.g., *“My app told me: \[insight]”*) with a healthcare provider or friend. These interactions should follow iOS conventions (e.g., use SF Symbols like trash or square.and.arrow\.up for icons). Implement them only if they add value; otherwise, keep the UI simple to start.

**On-Demand Chat:** The chat interface offers a conversational interaction. To access it, provide a clear entry point – for example, a button labeled “Ask AI” or an icon (perhaps a chat bubble or assistant icon) on the Insights screen or main screen. Tapping this opens the chat screen modally or pushes it in navigation. In the chat, users type questions. Support standard text editing interactions: the text field should auto-capitalize sentences, provide spell-check, and have a **Send** button (which can be the return key configured via `submitLabel(.send)`). Once sent, the user’s question appears immediately in the transcript. If the user changes their mind while typing, they can cancel (just navigate back, or you could add a “Cancel” button if presented modally).

During the waiting time for the AI’s answer, provide feedback. A common pattern is to show a **typing indicator**. You can implement a simple one by replacing the placeholder message’s `"..."` with an animated ellipsis or a small `ProgressView` (a spinning indicator) inline in the chat. This assures the user that a response is in progress. If the response takes a while, consider showing a subtle prompt like *“Analyzing your data…”* in the placeholder message. This is analogous to how Siri or iMessage might show *“Thinking…”*. As soon as the answer arrives, the placeholder is replaced with the actual message text.

**Gestures and Navigation in Chat:** Within the chat, not many custom gestures are needed beyond scroll and tap. Users should be able to scroll back to read previous answers. Make sure long messages wrap properly and consider using `ScrollViewReader` to automatically scroll the view to the latest message when a new one is appended (to keep the conversation view pinned to bottom). If the conversation becomes long, you might also implement an option to clear or reset it (perhaps a toolbar button “New Conversation” that clears the messages array). For now, a single session can just accumulate messages.

**Combining Proactive and On-Demand:** It’s important to delineate the proactive insights vs. chat in the UI flow so users don’t get confused. For example, the Insights tab could have two segments: one for *Insights* (the proactive cards/list) and one for *Chat*. Alternatively, the chat could be accessed via a floating action button with a chat icon on the Insights screen. However you expose it, make sure the user knows what to expect. A short description or title in the chat screen like “**Gemini – Ask about your health**” can set context that this is an AI chat based on their data. The user’s interactions in chat are on-demand and user-initiated, whereas the insights cards are passive and generated automatically – making this distinction clear through UI labeling and placement will align with user expectations.

## Loading and Error States

**Loading States (PAT Analysis):** PAT analysis can take a noticeable amount of time (several seconds, especially if processing a week of data). The UI should handle this gracefully by showing a loading state. Use a **skeleton screen** or placeholder content for the analysis display while data is being fetched or computed. For example, before the real data is available, you might show grey boxes or shapeless bars in place of the sleep stage chart and metrics (indicating “something will be here”). SwiftUI doesn’t have a built-in skeleton component, but you can simulate one with `redacted(reason:)` modifier – for instance, `Text("Loading...").redacted(reason: .placeholder)` which gives a shimmering placeholder effect for text. For the sleep stages chart area, you might show a static image or a rectangle with a striped fill as a placeholder. Alternatively, a simple **ProgressView** (spinner) centered in the screen can be used, with a label like “Analyzing your sleep data…”. This spinner could sit above a dimmed background of the view to indicate content is coming. Aim to reassure the user that processing is underway without overwhelming them.

If the analysis is **in progress on the backend** (status “processing”), you can poll periodically (perhaps using `Timer.publish` or a recursive async delay) and continue showing a loading indicator. Provide a way for the user to cancel if it’s a manual action (e.g., a Cancel button if they initiated analysis and don’t want to wait, which would simply stop polling and navigate away).

**Loading States (Insights & Chat):** For retrieving insights history or the Insight of the Day, use a spinner or pull-to-refresh indicator at the top of the list while loading. If the card is loading, you can show a placeholder card with a shimmering effect or an italic text “Fetching today’s insight…”. Keep these interim states brief and remove them as soon as data is ready. In the chat interface, the loading state is the typing indicator as described – maintain that until the AI response arrives.

**Error Handling (PAT Analysis):** Despite best efforts, the backend may return errors (e.g., network issues, or analysis fails). The PAT API indicates failures via an HTTP error or a `status: "failed"` in the response with a message. The app should detect this and inform the user in a friendly manner. If the analysis request fails entirely (e.g., no response), present an **alert** using `alert()` in SwiftUI with a message like “Unable to retrieve analysis. Please check your internet connection and try again.” If the response comes back with `status == "failed"`, you might use the provided `message` field (if it’s user-friendly) or a generic fallback. For example, if `PATAnalysisResponse.message` is “Analysis not found” or “Analysis failed due to X”, you could show that. However, avoid exposing technical jargon – map common errors to simple terms. You can say *“Analysis failed – please try again later.”* and log the technical detail for debugging.

In the UI, an error state for PAT could be represented by a message in place of the content. For instance, instead of the chart and metrics, show a `VStack` with a system image (like an exclamation mark icon) and a text like “We couldn’t load your analysis.” Possibly add a **Retry** button that calls the API again. This aligns with HIG by being clear and offering a next step.

**Error Handling (Gemini Insights):** If fetching the insight history fails (say the network call times out), inform the user with a non-intrusive message. You could use a `Toast` or snack-bar style notification at the bottom, or simply an alert. For example, *“Unable to load insights right now.”* The Insights list view can also show an overlay message if it’s empty due to error (differentiating from the “no insights” state). A retry mechanism is helpful – e.g., pull-to-refresh or a retry button on the error message overlay.

For the **Insight of the Day** card, if the content fails to load, you might replace the card with a smaller error placeholder (like a gray card with “—” or an error icon). Or simply hide the card section and show a brief notice. Ensure that the UI doesn’t crash if data is missing; always handle optional data safely (e.g., if no insight is available today, either don’t show the card or show a default message like “No new insight yet.”).

**Error Handling (Chat):** When the user asks a question in chat and the API call fails or returns an error (e.g., a 500 or a validation error), handle it gracefully in the conversation flow. One approach is to insert an **assistant message** in the chat saying something like *“Oops, I’m having trouble fetching that insight. Please try again.”* This keeps the error contextual in the chat (like the assistant replying with an apology) rather than a popup. You can style that message differently (maybe in red or with a warning icon) to denote it’s an error, but ensure it’s still readable. If the error is recoverable, allow the user to resend the question – e.g., show a small “Retry” button in that error message bubble or let them copy the question text to re-ask. Since the chat is conversational, maintaining flow is better than showing a disruptive alert. Of course, if the error is due to authentication (token expired, etc.), you might need to bubble up a login prompt instead.

**General UI/UX for Errors:** Follow Apple’s guidance to keep error messages **clear and concise**. Use polite tone and avoid blame. For example, prefer *“Couldn’t load insights”* over *“Insight API call failed”*. Also, do not expose raw error details to users (especially anything technical or sensitive). That said, logging the error (to console or analytics) is useful for developers. If an error is due to user action (like no internet), suggest a fix: *“Check your connection.”* If it’s on our side, a generic *“Please try again later.”* suffices. Use SF Symbols (exclamation mark triangle for warnings, etc.) sparingly to draw attention to error messages in the UI.

**Accessibility Considerations:** All loading and error states should be accessible. For example, the ProgressView should be announced by VoiceOver (it is by default, as a "In progress" announcement). If you use custom skeleton views, ensure they are labeled appropriately for VoiceOver users (you might temporarily mark content as hidden from accessibility while loading, or provide a polite announcement like "Loading analysis results"). Error messages presented on screen should be readable by VoiceOver as well – if using alert, iOS handles it, but if placing an error in the view, consider using `AccessibilityLabel` to ensure it’s spoken. Also, ensure that color is not the only indicator of an error – pair it with an icon or text so color-blind users can recognize it.

Finally, embrace simplicity: Apple’s HIG emphasizes **clarity** and **consistency**. The loading indicators and error messages should appear in consistent locations and styles throughout the app. For example, if you use a centered spinner for PAT analysis loading, do similar for any heavy loading tasks elsewhere. This consistency makes the app feel more polished and user-friendly.

**Summary:** By integrating these UI/UX strategies, the CLARITY Pulse iOS app will seamlessly incorporate the PAT analysis results and Gemini AI insights. Users will be presented with rich health insights (both passively via daily cards and actively via chat) in a way that is intuitive and aligned with Apple’s design principles. The use of SwiftUI’s modern features (async/await, charts, observation) will keep the codebase clean and responsive, while careful attention to loading/error states and interactions ensures a smooth experience even when things go wrong. The end result is an engaging **digital health assistant** that provides value through clear visuals and insightful feedback, without overwhelming the user.

**References:**

* PAT model output fields (sleep stages, confidence, insights, etc.)
* Gemini insight response structure (narrative, key insights, recommendations)
* Apple HIG on using charts for data visualization
* Backend responses for PAT analysis status and errors

