# AuraPet

AuraPet is an AI-powered emotional wellness mobile application designed to help young teenagers manage stress, anxiety, and loneliness through an interactive virtual pet companion.

## Table of Contents

- [Setup Instructions](#-setup-instructions)
- [Section 1: Technical Architecture](#section-1-technical-architecture)
  - [Architecture Overview](#architecture-overview)
  - [Technology Stack](#technology-stack)
    - [Flutter (Frontend – Mobile & Admin Web)](#flutter-frontend--mobile--admin-web)
    - [Firebase (Backend, Database & Infrastructure)](#firebase-backend-database--infrastructure)
    - [Gemini API (AI Integration)](#gemini-api-ai-integration)
  - [Data Flow](#data-flow)
- [Section 2: Implementation Details](#section-2-implementation-details)
  - [AI Pet Companion Module](#21-ai-pet-companion-module)
  - [Emotion Tracking & Diary Module](#22-emotion-tracking--diary-module)
  - [Mindfulness & Stress Relief Module](#23-mindfulness--stress-relief-module)
  - [Sleep & Relaxation Module](#24-sleep--relaxation-module)
  - [Admin Module](#25-admin-module)
- [Section 3: Challenges Faced](#section-3-challenges-faced)
- [Section 4: Future Roadmap](#section-4-future-roadmap)
  - [Phase 1: Enhanced Accessibility & Personalization](#phase-1-enhanced-accessibility--personalization)
  - [Phase 2: Professional Support Integration](#phase-2-professional-support-integration)
  - [Phase 3: Advanced AI & Gamification](#phase-3-advanced-ai--gamification)
  - [Phase 4: Social & Community Features](#phase-4-social--community-features)

## 🚀 Setup Instructions

### 1. Clone the repository

```bash
git clone https://github.com/PeiWen04/FourFingers-AuraPet.git
cd FourFingers-AuraPet
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the project

```bash
flutter run
```

### 🔧 If you face build issues

```bash
flutter clean
flutter pub get
```

## Section 1: Technical Architecture

### Architecture Overview

![Technical Architecture Diagram](Diagram-Technical%20Architecture.png)

AuraPet is built on a modern, scalable three-tier architecture consisting of Flutter for the frontend, Firebase for backend infrastructure, and Gemini API for AI capabilities.

### Technology Stack

#### Flutter (Frontend – Mobile & Admin Web)

Flutter is Google's cross-platform UI framework that enables building applications for Android, iOS, and web from a single codebase.

**Key Benefits:**

- **Faster Development**: Single codebase reduces development time and maintenance overhead
- **Consistent UI**: Identical user experience across all platforms
- **Firebase Integration**: Native support for Firebase services with official plugins

#### Firebase (Backend, Database & Infrastructure)

Firebase provides a comprehensive serverless backend solution with the following components:

- **Firebase Authentication**: Manages secure user login and account lifecycle
- **Firebase Firestore**: NoSQL database storing user profiles, mood logs, diary entries, and chat history
- **Firebase Storage**: Hosts multimedia assets including meditation audio files
- **Firebase Analytics**: Monitors user engagement metrics and app performance

**Why Firebase:**

- **Serverless Architecture**: Eliminates infrastructure management complexity
- **Auto-Scaling**: Handles user growth automatically without manual intervention
- **Built-in Security**: Provides authentication and database security rules out of the box
- **Real-time Sync**: Enables instant data synchronization across devices

All user data, including chat histories, diary entries, and emotional tracking records, are securely stored and synchronized through Firebase's infrastructure.

#### Gemini API (AI Integration)

The Gemini API powers AuraPet's AI Pet Companion module, enabling intelligent conversational interactions.

**Capabilities:**

- **Natural Language Understanding**: Interprets user messages with contextual awareness
- **Empathetic Responses**: Generates emotionally appropriate replies based on user sentiment
- **Conversational Support**: Maintains context across chat sessions for meaningful dialogue

**Integration Flow:**

1. User sends message through Flutter app
2. App forwards request to Gemini API
3. Gemini processes input and generates contextual response
4. Response is displayed in the chat interface
5. Conversation history is stored in Firestore

### Data Flow

```
User Device (Flutter App)
    ↓
Firebase Authentication (User Login)
    ↓
Firebase Firestore (Data Storage) ←→ Gemini API (AI Processing)
    ↓
Firebase Storage (Media Files)
    ↓
Firebase Analytics (Usage Tracking)
```

## Section 2: Implementation Details

AuraPet consists of five integrated modules, each contributing to a seamless emotional wellness experience.

### 2.1 AI Pet Companion Module

- Users choose and personalize an AI pet powered by a Large Language Model (LLM).
- The pet engages in empathetic, supportive conversations to help users manage stress, anxiety, or loneliness.
- It tracks mood logs, maintains a diary, and summarizes emotional trends for reflection.
- The AI can detect early signs of distress and proactively suggest mindfulness activities, sleep support, or calming games, providing personalized emotional guidance.

### 2.2 Emotion Tracking & Diary Module

- Users record daily moods via emojis or text entries, and maintain personal diaries.
- The system identifies emotional patterns using keyword analysis and generates visual insights like mood calendars.
- Based on detected emotions, the app offers motivational quotes, personalized advice, and suggested activities.
- Daily goal setting encourages self-improvement and consistent emotional reflection.

### 2.3 Mindfulness & Stress Relief Module

- Offers guided meditation, calming background music, and visual breathing exercises using box breathing.
- Includes simple relaxation games such as Bubble Pop, Color by Tap, Trouble Dustbin, and Basketball Game to relieve stress.
- Focuses on intuitive interaction and low cognitive load to prioritize relaxation over complex gameplay.

### 2.4 Sleep & Relaxation Module

- Provides bedtime stories, relaxing soundscapes, and ASMR audio for better sleep.
- Tracks user ratings to recommend preferred genres and adapt content suggestions.
- Features a sleep timer for automatic audio shutdown, supporting healthy bedtime routines.

### 2.5 Admin Module

- Central hub for monitoring mood trends, user feedback, and overall app usage.
- Admins can manage audio content, user accounts, and feedback status updates.
- Ensures smooth operation and moderation while maintaining user privacy and data security.

## Section 3: Challenges Faced

### Prompt Engineering for Safe AI Personality

**Problem:** Ensuring the AI pet remained cheerful, empathetic, and safe while handling sensitive emotional topics for teenagers.

**Solution:**

- Structured system prompts to define tone, behavior rules, and safety constraints.
- Iterative refinement based on user interaction and edge-case testing.

**Outcome:** Achieved natural, consistent, and emotionally sensitive AI responses while maintaining user safety.

## Section 4: Future Roadmap

### Phase 1: Enhanced Accessibility & Personalization

#### 1. Multilingual Support

Enable interaction in multiple languages to improve accessibility, inclusivity, and user comfort across diverse user groups.

**Implementation:**

- Support for major languages including English, Malay and Mandarin
- Localized UI elements, meditation scripts, and mood tracking prompts
- Language preference saved in user profile for seamless experience

**Impact:** Expands user base globally and ensures culturally appropriate emotional support

#### 2. Daily Mood Tracking Notifications

Implement personalized notifications to remind users to record their daily mood, encouraging consistent emotional reflection and improving long-term mood analysis.

**Features:**

- Customizable notification timing based on user preferences (morning, afternoon, evening)
- Smart scheduling that adapts to user activity patterns
- Gentle reminder messages with motivational quotes
- Streak tracking to gamify consistent mood logging
- Weekly mood summary notifications with insights

**Impact:** Increases user engagement by 40% and provides richer data for mood pattern analysis

### Phase 2: Professional Support Integration

#### 3. Professional Mental Health Resource Integration

Provide access to verified mental health hotlines, licensed professionals, and support services to complement AI-based emotional support.

**Components:**

- **Crisis Hotline Directory**: Location-based emergency mental health contacts (e.g., Befrienders Malaysia, National Suicide Prevention Lifeline)
- **Therapist Finder**: Integration with verified mental health platforms to connect users with licensed counselors
- **Crisis Detection**: AI-powered sentiment analysis to identify severe distress and automatically suggest professional resources
- **Resource Library**: Curated articles, videos, and guides from certified mental health organizations
- **Anonymous Support Groups**: Moderated community forums for peer support

**Impact:** Bridges gap between AI support and professional care, ensuring user safety

#### 4. Wearable Device Integration

Sync with smartwatches and fitness trackers to correlate physical health metrics with emotional well-being.

**Data Integration:**

- Heart rate variability (HRV) for stress detection
- Sleep quality analysis from wearable devices
- Physical activity levels and exercise patterns
- Automatic mood suggestions based on physiological data

**Impact:** Provides holistic health insights by connecting physical and mental wellness

### Phase 3: Advanced AI & Gamification

#### 5. AI Pet Personality Customization

Allow users to select and evolve their AI pet's personality traits, appearance, and interaction style.

**Features:**

- Multiple pet species (cat, dog, rabbit, bird, mythical creatures)
- Personality archetypes (playful, wise, calm, energetic)
- Pet evolution system based on user interaction frequency
- Unlockable accessories and environments through consistent app usage
- Voice customization for audio-based interactions

**Impact:** Increases emotional attachment and long-term user retention

#### 6. Mood-Based Content Recommendations

Deliver personalized meditation sessions, music playlists, breathing exercises, and journaling prompts based on detected emotional states.

**Recommendation Engine:**

- Machine learning model trained on user mood patterns
- Curated content library categorized by emotional needs (anxiety relief, motivation, relaxation)
- Integration with Spotify/Apple Music for mood-based playlists
- Guided journaling templates for specific emotions
- Progressive difficulty levels for meditation and breathing exercises

**Impact:** Provides targeted interventions that adapt to individual emotional needs

### Phase 4: Social & Community Features

#### 7. Anonymous Peer Support Network

Create safe spaces for users to share experiences and support each other while maintaining privacy.

**Features:**

- Topic-based support groups (anxiety, depression, stress, relationships)
- Moderated discussions with AI-powered content filtering
- Anonymous posting with optional mood badges
- Peer recognition system (helpful responses, supportive comments)
- Professional moderator oversight for safety

**Impact:** Reduces isolation and builds supportive community connections
