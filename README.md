# Local AI Studio

A native iOS app to download and run AI models locally with MLX Swift, focused on privacy, offline usage, and modular architecture.

## Overview

**Local AI Studio** lets you chat with LLMs directly on-device, without requiring a backend for inference.

- Local inference with `MLX`, `MLXLLM`, and `MLXLMCommon`
- In-app model download and activation flow
- Chat with persistent history and multiple sessions
- Generation controls (temperature, top-p, max tokens, context length)

## Features

- Onboarding flow with an offline-first value proposition
- Local chat with streaming responses
- Multiple chat sessions
- Pin, rename, and delete sessions
- Model catalog with status:
  - not downloaded
  - downloading
  - installed
  - active
- Download and remove models
- Active model selection
- Settings screen with:
  - generation parameter controls
  - chat history cleanup
  - local storage usage overview

## Current Seeded Models

- `Qwen 3.5 0.8B 8-bit (MLX)` (`mlx-community/Qwen3.5-0.8B-8bit`)
- `Qwen 3.5 2B 6-bit (MLX)` (`mlx-community/Qwen3.5-2B-6bit`)

## Tech Stack

- `Swift` + `UIKit` (no Storyboard)
- `async/await` + async streams
- Local persistence via files and `UserDefaults`
- Local ML via:
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

## Running the App

### Requirements

- macOS with Xcode installed
- An Apple device compatible with local inference (physical device recommended)
- Internet connection to fetch Swift Package dependencies and model assets

### Steps

1. Clone the repository:

```bash
git clone <URL_DO_SEU_REPOSITORIO>
cd "<NOME_DO_REPOSITORIO>"
```

2. Open the project in Xcode:

```bash
open local_ai.xcodeproj
```

3. Let Xcode resolve the Swift Package dependencies.
4. Select a **physical device** and run (`Cmd + R`).
5. In the app, open **Models**, download a model, and activate it.
6. Open **Chat** and send your first message.

## Important Notes

- On Simulator, model download/inference is blocked with an unsupported environment error.
- The current project target is set to `IPHONEOS_DEPLOYMENT_TARGET = 26.2`.
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

## Suggested Roadmap

- Remote model manifest support (already scaffolded in code)
- More model options and device compatibility heuristics
- Better download UX (advanced pause/resume)
- Chat history export/import

## Contributing

PRs are welcome. Suggested flow:

1. Create a branch `codex/<feature-name>`
2. Make small, descriptive commits
3. Open a Pull Request with context and screenshots when relevant

## License

This project is licensed under MIT. See [`LICENSE`](LICENSE).
