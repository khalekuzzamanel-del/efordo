# eFordo

**Personal Productivity Platform**

A production-grade, cross-platform productivity suite combining the power of Flutter on the frontend with a robust NestJS REST API backend, backed by Supabase PostgreSQL.

---

## Monorepo Structure

```
efordo/
├── frontend/
│   └── flutter_app/          # Flutter application (Android, iOS, Web)
├── backend/
│   └── api/                  # NestJS REST API
├── docs/                     # Documentation & architectural decisions
├── shared/
│   ├── api-contracts/        # Shared API contracts & types
│   └── assets/               # Shared assets (icons, images, fonts)
├── .vscode/
│   ├── extensions.json       # Recommended VS Code extensions
│   └── settings.json         # Workspace settings
├── .gitignore                # Root git ignore rules
└── README.md                 # This file
```

## Technology Stack

| Layer       | Technology                                                |
| ----------- | --------------------------------------------------------- |
| **Mobile**  | Flutter (Dart) — Material 3, Android/iOS/Web              |
| **Backend** | NestJS (TypeScript) — REST API, ESLint, Prettier, Jest    |
| **Database**| Supabase PostgreSQL                                       |
| **Tooling** | Node.js, npm, Git, VS Code                                |

## How to Run

### Prerequisites

- **Flutter SDK** ≥ 3.44 (stable channel)
- **Node.js** ≥ 24.16
- **npm** ≥ 11.13
- **Git**

### Frontend (Flutter)

```bash
cd frontend/flutter_app
flutter pub get
flutter run
```

To run on a specific platform:

```bash
flutter run -d android   # Android
flutter run -d ios       # iOS (macOS required)
flutter run -d chrome    # Web
```

### Backend (NestJS)

```bash
cd backend/api
npm install
npm run start:dev
```

The API will be available at `http://localhost:3000`.

### Running Tests

**Frontend:**

```bash
cd frontend/flutter_app
flutter test
```

**Backend:**

```bash
cd backend/api
npm test
```

## Future Development Phases

### Phase 1 — Core Infrastructure
- [ ] Authentication (Supabase Auth / JWT)
- [ ] User profile management
- [ ] Database schema & migrations
- [ ] CI/CD pipeline setup

### Phase 2 — Foundation Features
- [ ] Dashboard with analytics
- [ ] Workspace management
- [ ] Project CRUD
- [ ] Task management with states

### Phase 3 — Execution Engine
- [ ] Execution management
- [ ] Real-time updates (WebSocket/SSE)
- [ ] Notification system
- [ ] Personal organization tools

### Phase 4 — Polish & Scale
- [ ] Offline-first support
- [ ] Performance optimization
- [ ] Comprehensive test coverage
- [ ] App store deployment (Play Store / App Store)

## Development Guidelines

- Follow the established code style and linting rules for each sub-project.
- Keep shared API contracts in `shared/api-contracts/` for type safety across the stack.
- Write tests alongside new features — we use Jest (backend) and Flutter Test (frontend).
- Use feature branches and pull requests for all changes.

## License

Proprietary — all rights reserved.
