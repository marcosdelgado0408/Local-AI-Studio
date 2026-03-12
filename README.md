<div align="center">
  <h1>Local AI Studio</h1>
  <p><strong>Privacy-first, offline-capable iOS app for running LLMs locally with MLX Swift.</strong></p>

  <p>
    <img alt="platform" src="https://img.shields.io/badge/platform-iOS-black?style=for-the-badge" />
    <img alt="language" src="https://img.shields.io/badge/language-Swift-orange?style=for-the-badge" />
    <img alt="ui" src="https://img.shields.io/badge/UI-UIKit-1f6feb?style=for-the-badge" />
    <img alt="license" src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge" />
  </p>
</div>

## Table of Contents

- [Overview](#overview)
- [Highlights](#highlights)
- [Features](#features)
- [Current Seeded Models](#current-seeded-models)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Important Notes](#important-notes)
- [Folder Structure](#folder-structure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

## Overview

**Local AI Studio** lets you run and chat with LLMs directly on-device.
No inference backend required.

| Why this project | What it provides |
| --- | --- |
| Privacy by design | Local model execution |
| Offline-first UX | Persistent chat sessions |
| Native performance | MLX-based iOS pipeline |
| Modular codebase | Clear clean-architecture layers |

## Highlights

- On-device inference with `MLX`, `MLXLLM`, and `MLXLMCommon`
- In-app model lifecycle: download, install, activate, remove
- Streaming chat responses with persistent history
- Tunable generation settings: temperature, top-p, max tokens, context

## Features

- Offline-first onboarding flow
- Local chat with streaming responses
- Multi-session chat management
- Pin, rename, and delete chat sessions
- Model catalog with status:
  - not downloaded
  - downloading
  - installed
  - active
- Active model selection and removal
- Settings screen with:
  - generation controls
  - chat history cleanup
  - local storage usage overview

## Current Seeded Models

- `Qwen 3.5 0.8B 8-bit (MLX)` (`mlx-community/Qwen3.5-0.8B-8bit`)
- `Qwen 3.5 2B 6-bit (MLX)` (`mlx-community/Qwen3.5-2B-6bit`)

## Tech Stack

- `Swift` + `UIKit` (no Storyboard)
- `async/await` + async streams
- Local persistence via files and `UserDefaults`
- ML runtime via:
  - [`mlx-swift`](https://github.com/ml-explore/mlx-swift)
  - [`mlx-swift-lm`](https://github.com/ml-explore/mlx-swift-lm)

## Architecture

The project follows a clean, modular structure:

- `App/` app lifecycle, coordination, and dependency injection
- `Features/` screens + view models (`Chat`, `Models`, `Settings`, `Onboarding`, `Downloads`)
- `Domain/` entities, contracts, and use cases
- `Data/` repositories, persistence, networking, and storage
- `InferenceEngine/` inference engine and MLX adapters
- `Core/` design system, utilities, and shared kernel

## Quick Start

### Requirements

- macOS with Xcode installed
- Apple device compatible with local inference (physical device recommended)
- Internet connection to fetch Swift Package dependencies and model assets

### Run

1. Clone the repository:

```bash
git clone <YOUR_REPOSITORY_URL>
cd "<YOUR_REPOSITORY_NAME>"
```

2. Open in Xcode:

```bash
open local_ai.xcodeproj
```

3. Let Xcode resolve Swift Package dependencies.
4. Select a physical iOS device and run (`Cmd + R`).
5. Open **Models**, download a model, and activate it.
6. Open **Chat** and send your first message.

## Important Notes

- On Simulator, model download/inference is blocked with an unsupported environment error.
- Current project target: `IPHONEOS_DEPLOYMENT_TARGET = 26.2`.
- Model files and metadata are stored locally in the app sandbox.

## Folder Structure

```text
local_ai/
├── App/
├── Core/
├── Data/
├── Domain/
├── Features/
└── InferenceEngine/
```

## Roadmap

- [ ] Remote model manifest support (already scaffolded in code)
- [ ] More model options and device compatibility heuristics
- [ ] Better download UX (advanced pause/resume)
- [ ] Chat history export/import

## Contributing

PRs are welcome. Suggested workflow:

1. Create a branch `codex/<feature-name>`
2. Make small, descriptive commits
3. Open a Pull Request with context and screenshots when relevant

## License

This project is licensed under MIT. See [`LICENSE`](LICENSE).
