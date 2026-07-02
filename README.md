# ResuMate

An AI-powered, ATS-optimized, multi-template Resume Builder application built with Flutter, Riverpod, and Google Gemini AI.

---

## ✨ Comprehensive Application Features

### 📄 1. 8 Professional PDF Resume Templates
- **Modern Indigo**: Clean two-tone layout with Indigo header dividers and structured typography.
- **Minimalist**: Ultra-clean, high-density minimal design for executive readability.
- **Tech Monospace**: Monospaced code-inspired layout tailored for developers and engineers.
- **Classic Serif**: Elegant centered layout using classic serif typography.
- **Two-Column Sidebar**: Dark accent sidebar housing contact info and skill badges.
- **Creative Bold**: Large accent header block with bold typographic contrast.
- **ATS Clean**: Single-column ATS-tested design built for maximum parser accuracy.
- **Executive Formal**: Refined traditional layout with double-line dividers.

### 🔍 2. Live Document Preview & Template Switcher
- **Interactive PDF Canvas**: Real-time compilation with page preview zoom and page slider.
- **Template Card Previews**: Live rendered document page thumbnails directly on the template selection screen.
- **Custom Naming**: Custom resume naming directly inside the template preview modal.

### 🤖 3. Zero-Failure AI Resume Extractor
- **Raw Text Import**: Paste raw resume text from LinkedIn, Word, or plain text.
- **Gemini AI Parsing**: Structured extraction of contact info, work experience, education, skills, and projects using Google Gemini 1.5 Flash.
- **Persistent API Key Entry**: User-configured Gemini API keys saved persistently via SharedPreferences.
- **Smart Heuristic Fallback**: Built-in fallback text extractor guarantees resume parsing **never fails** even on network error or missing API keys.

### 💾 4. Data Portability & Multi-Format Export
- **Offline Encrypted JSON Backup & Restore**: Export all saved resumes into a `.resumate` / `.json` backup file with schema signature verification and 1-tap restoration.
- **Microsoft Word (`.docx`) Export**: Native OpenXML Word document generator producing editable `.docx` files compatible with Word, Google Docs, and Pages.
- **High-Res PDF Export & Google Drive Cloud Sync**: Direct PDF compilation and 1-tap upload to Google Drive.

### 💡 5. Smart Summary Database
- **40+ Pre-written Role Summaries**: Built-in database categorized by industry (*Software Engineering, Data Science, Product Management, Design, Marketing, Finance, Healthcare, General*).
- **Auto-Category Detection**: Automatically highlights relevant summary suggestions based on the user's filled resume profile.

### 📱 6. Multi-Resume Management & Premium UX
- **Dashboard Management**: Create, edit, rename, duplicate, and delete multiple resumes.
- **Custom Squircle Icon**: Custom squircle (rounded square) launcher icon across Android, iOS, and Web.
- **Glassmorphism Dark Mode**: Sleek dark and light themes powered by Riverpod state management.

---

## 📦 GitHub Actions CI & Automated Releases
Automated APK builds trigger on the `develop` branch with version numbers starting from `v0.1.x`. Every push to `develop` automatically creates a new version tag and publishes the compiled APK asset (`ResuMate-v0.1.x.apk`) directly to the [GitHub Releases](https://github.com/swastik2012/ResuMate/releases) tab for instant download.

---

## 🔒 Intellectual Property & Proprietary Terms of Use

**Copyright (c) 2026 swastik2012. All Rights Reserved.**

This repository and all associated assets—including source code, design elements, graphics, icons (`ResuMate` branding), UI architecture, templates, database schemas, and documentation—are the exclusive intellectual property of the GitHub account owner ([@swastik2012](https://github.com/swastik2012)).

### 1. Permitted Scope & Viewing Only
- **Inspection Only**: Access to this repository is provided solely for personal viewing, code audit, and educational evaluation directly on GitHub.
- **No Open-Source License**: This repository is **NOT** licensed under MIT, Apache, GPL, or any permissive open-source license. Absence of a permissive license strictly reserves all rights to the copyright holder.

### 2. Strict Restrictions & Loophole Protection
Without explicit, prior written authorization from [@swastik2012](https://github.com/swastik2012), any individual, company, or automated entity is strictly prohibited from:

1. **Reproduction & Copying**: Copying, cloning, duplicating, re-hosting, mirroring, or redistributing any portion of this codebase or its assets in any medium, whether public or private.
2. **Commercial & SaaS Exploitation**: Utilizing, hosting, offering, or embedding any part of this software for commercial purposes, paid services, white-label products, or monetized platforms.
3. **App Store Publishing & Rebranding**: Bundling, rebranding, or submitting this application (or any derivative work) to any app store or distribution platform (including Google Play Store, Apple App Store, Web hosting, F-Droid, or third-party APK stores).
4. **Derivative Works & Reverse Engineering**: Modifying, adapting, extracting components, reverse-engineering, decompiling, or building derivative applications based on this codebase.
5. **AI Training & Code Scraping**: Ingesting, harvesting, or utilizing any code, asset, or dataset from this repository for training, fine-tuning, or benchmarking artificial intelligence models, Large Language Models (LLMs), or code-generation systems.
6. **Sublicensing & Resale**: Sublicensing, renting, leasing, selling, or transferring any rights related to this software.

### 3. Legal Enforcement
- Unauthorized use or distribution constitutes copyright infringement under applicable international laws and intellectual property treaties.
- Infringements will be enforced via immediate GitHub DMCA takedown notices, platform revocation, app store takedown requests, and statutory legal remedies.

### 4. Licensing Inquiries
For permission requests or custom licensing inquiries, contact the repository owner at [github.com/swastik2012](https://github.com/swastik2012).
