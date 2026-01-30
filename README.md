🧘 Gamified Mental Health Application

A cross-platform mobile application designed to incentivize mental wellness through interactive gamification and progress tracking. This project leverages a modern serverless architecture to ensure high availability, data security, and seamless user experiences.
🚀 Key Features

    Gamified Wellness Tracking: Engaging UI/UX components that transform mental health check-ins into an interactive journey.

    Cross-Platform Performance: Built with Flutter for a high-performance, single-codebase experience across iOS and Android.

    Real-time Progress: Instant updates on user achievements and social features utilizing Supabase Realtime.

    Advanced Security: Implemented Row-Level Security (RLS) in PostgreSQL to ensure that sensitive user data is strictly protected.

    Scalable Microservices: Custom backend logic hosted on Google Cloud Run for efficient, auto-scaling serverless execution.

🛠️ Tech Stack

    Frontend: Flutter (Dart)

    Backend-as-a-Service: Supabase (PostgreSQL, Authentication, Realtime)

    Infrastructure: Google Cloud Run (Dockerized microservices)

    Database: PostgreSQL with Row-Level Security

    Tools: Git/GitHub, Docker, Figma

🏗️ Architecture

The application follows a modern serverless pattern:

    Mobile Client: Flutter handles the UI and direct communication with Supabase for data and authentication.

    BaaS Layer: Supabase manages the relational database and provides secure access to user data.

    Microservices: Google Cloud Run executes complex server-side logic and integrations that require a dedicated backend environment.

📦 Getting Started
Prerequisites

    Flutter SDK

    A Supabase Project

    Google Cloud CLI (for deployment)

Setup

    Clone the Repository:
    Bash

    git clone https://github.com/CSLiI/Gamified-mental-health-app.git
    cd Gamified-mental-health-app

    Environment Variables: Create a .env file in the root directory:
    Plaintext

    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_anon_key
    CLOUD_RUN_ENDPOINT=your_service_url

    Install Dependencies:
    Bash

    flutter pub get

    Run Locally:
    Bash

    flutter run

🛡️ Best Practices

    Data Privacy: Utilizing Supabase RLS policies to prevent unauthorized data access at the database level.

    Scalability: Leveraging Google Cloud Run's containerized environment to handle horizontal scaling automatically based on traffic.

    Maintainability: Modular code structure in Flutter to separate UI components from business logic.
