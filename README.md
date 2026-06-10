⚖️ Namma-Appeal: A Multimodal RAG Framework for Automated RTI Legal EmpowermentNamma-Appeal is an AI-powered legal co-pilot designed to democratize the Right to Information (RTI) process for Indian citizens. By translating complex bureaucratic jargon into actionable civic intelligence, the application lowers the cognitive and technical barriers to entry, transforming a manual bureaucratic chore into a guided digital workflow.  ✨ Key Features🤖 Multimodal AI Legal Co-Pilot: Powered by Google Gemini 2.5 Flash, strictly engineered via System Instructions to act as a professional Indian Constitutional law assistant. It processes both natural language descriptions and OCRs physical rejection letters.📄 Dynamic PDF Generation Engine: A custom layout and string sanitization engine that bypasses standard text-wrapping crashes, fixes missing glyphs, and strictly enforces chronological legal formatting for immediate, print-ready RTI drafts.⏰ Automated Legal Timelines: A background local notification service that tracks filing dates and triggers system alarms on Day 27 (Follow-up) and Day 57 (First Appeal Deadline) using native device timezone databases.🔒 Enterprise-Grade Security: Fully integrated with Supabase (PostgreSQL) featuring OAuth authentication and rigorous Row Level Security (RLS) policies to ensure tamper-proof legal data.📱 True Cross-Platform: A single unified Dart codebase flawlessly compiled Ahead-of-Time (AOT) for native Android and transpiled for responsive Web deployment (Vercel).✨ Premium UX/HCI: Features dynamic system-aware Dark Mode, haptic feedback integration, and Shimmer (skeleton) loading screens to mask network latency.🛠️ Tech StackFrontend: Flutter (Dart)Backend: Supabase (PostgreSQL, Auth, RLS)AI Engine: Google Generative AI SDK (Gemini 2.5 Flash)Local Storage & State: SharedPreferences, ValueNotifierKey Packages: pdf, printing, flutter_local_notifications, speech_to_text, shimmer, flutter_markdown🚀 Getting StartedPrerequisitesFlutter SDK (Latest Stable)Supabase Account & ProjectGoogle Gemini API KeyInstallationClone the repository:Bashgit clone https://github.com/Akashsubramanian123/Namma-Appeal-hybrid.git
cd Namma-Appeal-hybrid

2. **Install dependencies:**
   ```bash
   flutter pub get
Configure Environment Secrets:Create a file at lib/secrets.dart. Do not commit this file to version control (it is included in .gitignore).Dartclass Secrets {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
}

4. **Run the application:**
   ```bash
   # For Android
   flutter run -d android
   
   # For Web
   flutter run -d chrome
🏗️ Architecture OverviewNamma-Appeal relies on a secure, modular architecture:Strict Memory Typing: Manages dynamic lists (Web) and strict <String, dynamic> mapping (Mobile AOT) for seamless chat history loading without UI crashes.Cloud-Synced History: All RTI applications and legal appeal drafts are instantly synced to a PostgreSQL database, allowing users to pick up where they left off across devices.Prompt Engineering: The AI is locked into a highly restrictive persona, bound by a "Critical Language Rule" that forces professional English and eliminates AI hallucinations.👨‍💻 About the DeveloperDeveloped by Akash S., a B.Tech student specializing in Artificial Intelligence and Data Science at Saveetha School of Engineering (SSE/SIMATS). This project bridges the gap between full-stack software development and Indian Polity, leveraging advanced machine learning and cloud infrastructure to create a scalable civic utility.