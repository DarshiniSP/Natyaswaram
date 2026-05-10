# Sanchana: A Practice Companion for Bharatanatyam
Sanchana is a self-initiated iOS system designed for Bharatanatyam students and practitioners that tracks practice sessions, monitors learning patterns, and surfaces insights about how you practise, not to judge, but to understand.

## Problem
Bharatanatyam is not a skill you acquire. It is one you accumulate. The difference between a student who plateaus and one who grows is awareness: knowing not just how much you practise, but how, when, and in what state of mind.
Most students have no system for this. Progress is felt but rarely examined. And the tools that exist, generic habit trackers, fitness apps, basic timers, were never built for a practice tradition with its own vocabulary, pedagogy, and emotional texture. They treat dance like going to the gym.
Bharatanatyam students deserve a tool that understands the practice from the inside.

## Solution
A practice companion that speaks Bharatanatyam. One that understands the difference between drilling an Adavu and learning a Varnam, that treats practice notes as meaningful data, and that offers insight without prescription.
Sanchana lets students log sessions by composition, rate quality, write remarks, and set goals. Under the hood, it runs an analytics engine called Viveka that detects patterns across streaks, quality trends, burnout signals, and gap-length effects, then surfaces them as reflective observations, not instructions.

## Demo (from left to right)
<p align="center">
  <img src="https://github.com/user-attachments/assets/3ec7df6e-41ef-4f60-9186-8e1d86e5d64f" width="22%"/>
  <img src="https://github.com/user-attachments/assets/908f23af-925e-4266-bcbf-821bd7cdb6d8" width="22%"/>
  <img src="https://github.com/user-attachments/assets/49e5bca3-3a54-4cb5-971c-e70c2b663b94" width="22%"/>
  <img src="https://github.com/user-attachments/assets/9e62703c-5dc6-41bb-997b-c1b1aa2b110a" width="22%"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/effea609-3ad3-4ade-ac93-cbb6feb96cc5" width="200"/>
  <img src="https://github.com/user-attachments/assets/cc8b9af8-64f1-4318-b99e-4c02ee5e2745" width="200"/>
  <img src="https://github.com/user-attachments/assets/b0bd3519-7170-4606-8248-c3c04d9bb760" width="200"/>
  <img src="https://github.com/user-attachments/assets/85933bec-141c-4e03-b368-8e674c1df896" width="200"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/db6f5cbb-8b67-4d21-a8ac-294bed1c3ea1" width="22%"/>
  <img src="https://github.com/user-attachments/assets/9f9038bf-1aac-4400-88b9-03802b27bee0" width="22%"/>
  <img src="https://github.com/user-attachments/assets/345685a1-17d5-4036-ab18-33037150318f" width="22%"/>
  <img src="https://github.com/user-attachments/assets/3767daf4-ec93-4337-bb18-a6de862f0b51" width="22%"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/e2e37ef9-0780-4c10-a0a9-8c4e927f38ec" width="22%"/>
  <img src="https://github.com/user-attachments/assets/2d88c2ae-1ea1-4084-9387-d2f3e3653e5e" width="22%"/>
</p>

## System Design
The app uses a central AppState object as a single source of truth, allowing all views to access shared data without complex data passing. AppState manages two stores: ProgressStore for practice session data, including schema migration, and GoalStore for user goals. Both stores persist data locally using UserDefaults with JSON serialisation. Practice data is processed by a ReportEngine, which aggregates it into weekly summaries, composition breakdowns, and quality trends. These insights are then used by two systems. VivekaEngine detects patterns such as streaks, burnout, and improvement trends, while SentimentEngine analyses the emotional tone of reflections using Apple’s on-device NaturalLanguage framework. Each layer has a clear responsibility. Views present data, stores manage persistence, and engines handle analysis. This structure keeps the system modular, scalable, and fully on-device without requiring external services.



## Key Features
1. Practice Logging: Log sessions by composition (Alarippu, Jathiswaram, Shabdam, Varnam, Adavu Basics, Hastas, or custom), duration, quality rating (1 to 5), and free-text remarks.
2. Calendar View: Monthly calendar with colour-coded indicators for practice sessions and goals set. Tap any date to view or edit its entries.
3. Goal Tracking: Set dated goals with descriptions. Track them with completion percentages and a visual pathway showing completed, in-progress, and upcoming stages.
4. Viveka: Intelligent Insights Analytics engine that monitors 10+ practice patterns without being prescriptive:
   - Session streaks and consistency rhythms
   - Quality trend detection (improving / declining / stable)
   - Burnout signal (4+ sessions across 5 days)
   - Optimal session duration based on personal history
   - Performance patterns after short vs. long practice gaps
   - Composition-specific mastery arcs
5. Sentiment Analysis of Remarks: The SentimentEngine uses Apple's NaturalLanguage framework to analyse the emotional tone of practice notes. If remarks tend negative around a particular composition or time of week, Viveka notices.
6. Reports: Generate periodic reports with weekly activity charts, composition breakdowns, quality summaries, and a narrative "Viveka's Reading" section.
7. Accessibility & Customisation: Font size scaling (5 presets, up to 1.6x standard) to enhance user experience and support dancers of all ages and preferences, daily reminder notifications, and a calendar start-day preference (Monday or Sunday) so the app aligns with each dancer’s schedule.

## Trade-offs & Decisions
1. Why UserDefaults instead of CoreData?
For the current scope of the app, data is user-specific, stored locally on a single device, and lightweight enough not to require complex querying or persistence infrastructure. UserDefaults with JSON serialisation provides a simple and reliable solution that is fast to implement and easy to maintain. CoreData would be more appropriate if the app later required iCloud sync, relational data modelling, or efficient querying across large datasets. The decision was made to match the storage layer to the actual requirements of the system, ensuring simplicity without introducing unnecessary architectural complexity.
2. Why no external ML library for sentiment?
Apple’s NaturalLanguage framework provides on-device sentiment analysis without requiring internet access, a developer account, or third-party SDKs. This ensures privacy, low latency, and a fully self-contained system. While the trade-off is that it uses a general-purpose model not specifically trained on dance practice language, it is sufficient for capturing broad emotional tone in user reflections. A domain-fine-tuned model would likely improve accuracy, but implementing and training such a model is outside the current scope of the project.
3. Why Bharatanatyam-specific vocabulary instead of a generic “art form” app?
Generic tools are typically designed for a broad, median user, which often results in shallow coverage across many domains. A Bharatanatyam student is not a generic user, but someone working within a specific pedagogical structure, with defined compositions, terminology, and practice conventions. Designing for this context allowed the product to reflect real learning workflows and vocabulary, making it more accurate and meaningful for its users. A fully generalised “any art form” approach would likely dilute this specificity and reduce usefulness for all users. The design choice prioritises depth over breadth.

## Shortcomings
1. Viveka has no personal baseline. All thresholds are universal constants: burnout fires at 4+ sessions in 5 days for every student, quality trend requires a 0.4 delta for every student. A student who trains six days a week will receive routine burnout alerts. The system detects deviation from an assumed average, not from the individual's own norm.
2. Duration is a proxy, not a signal. ProgressStore records time as the primary measure of practice investment, and ReportEngine uses duration buckets to infer optimal session length. But an anxious 90-minute repetition and a focused 90-minute refinement look identical in the data model. Quality rating compensates partially, but it is self-reported immediately after the session and subject to recency bias.
3. Time-of-day is never captured. Sessions are keyed by "DD-MM-YYYY" with no time component, making circadian pattern analysis permanently inaccessible. Whether morning practice consistently yields higher quality scores is a question the architecture cannot answer, now or in any future version, without a breaking schema change.
5. The SentimentEngine trades coverage for reliability. The 15-word minimum in SentimentEngine exists because Apple's NLTagger produces unreliable scores on short text. Below that threshold, a single word can swing the result. The trade-off is real: short remarks like "struggled today" are excluded not because they lack meaning, but because the model cannot be trusted to read them accurately. Longer, more articulate entries are analysed well. Terse ones are not analysed at all. A domain-trained model would close this gap.

## What I Learned
1. Design is a series of justified decisions, not aesthetic preferences. Every colour, every font, every copy choice in Sanchana was made for a reason rooted in the community it serves. The warm palette was drawn from classical performance aesthetics. The typography references temple inscription styles. Working through those reasons, and sometimes realising the reason was not good enough, was the most important design skill built through this project.
2. The hardest part of building a product is defining what it should not do. Early versions of Viveka were prescriptive. They told students to practise more, rest more, focus on a specific composition. All of it was cut. Students already have teachers for instruction. What they lack is a mirror, something that reflects patterns back without judgment. The decision to make Sanchana observational rather than instructional was the most consequential design call in the project, arrived at by thinking hard about what the community actually needed versus what was technically satisfying to build.
3. On-device intelligence is underrated, especially for communities where privacy matters. The SentimentEngine works entirely offline with no data leaving the device. For a student writing honest, vulnerable practice notes, that matters. Apple's NaturalLanguage framework made this possible without a server or third-party SDK, and it required going well off-tutorial to find.
4. A community's frustration is the most honest design brief. The absence of tools for Indian classical arts practitioners is not an accident. It reflects which communities get designed for and which do not. Starting from that gap, rather than from a generic feature list, shaped every decision in Sanchana.
5. Shipping something imperfect to real users teaches more than perfecting something in isolation. Sanchana is a real app used in real practice sessions. The feedback loop of building, using, noticing what breaks, and improving is how the product has evolved, and it is the only way a tool for a specific community can actually become useful to that community.

## Future Directions
1. iCloud sync: practice data should survive a phone change
2. Multi-tradition support: extend the composition vocabulary to Odissi, Kuchipudi, and Carnatic music practice
3. Richer sentiment modelling: fine-tune on dance practice language rather than relying on a general-purpose model
4. Typed composition system: replace raw strings with a proper enum and extensible custom type system
5. Test coverage: particularly for ReportEngine and SentimentEngine thresholds, which currently rest on intuition

Built by Darshini S P

Built with SwiftUI, Apple NaturalLanguage framework, and no external dependencies.
