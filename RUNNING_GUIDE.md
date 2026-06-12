# eFordo — Running Guide

> **Monorepo:** `C:\Users\B I S H A L\Documents\efordo\efordo\`
> **Frontend:** Flutter (Dart)
> **Backend:** NestJS (TypeScript)
> **Database:** Supabase (PostgreSQL)

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Backend Setup & Run](#2-backend-setup--run)
3. [Supabase Setup](#3-supabase-setup)
4. [Frontend Setup & Run](#4-frontend-setup--run)
5. [Expected Behavior](#5-expected-behavior)
6. [API Endpoints Reference](#6-api-endpoints-reference)
7. [Flutter Routes](#7-flutter-routes)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

| Tool | Version |
|---|---|
| **Flutter** | 3.44.2+ (Dart 3.12.2+) |
| **Node.js** | 24.16.0+ |
| **npm** | 11.13.0+ |
| **Supabase** | Free project (app.supabase.com) |

### Verify Installation

```bash
flutter --version
node --version
npm --version
```

**Expected output:**

```
Flutter 3.44.2 • channel stable
Dart 3.12.2
v24.16.0
11.13.0
```

---

## 2. Backend Setup & Run

### 2.1 Install Dependencies

```bash
cd backend/api
npm install
```

**Expected output:** `added 693 packages` — no vulnerabilities.

### 2.2 Configure Environment

```bash
cd backend/api
cp .env.example .env
```

Edit `.env` with your Supabase credentials:

```env
# Server
PORT=3000

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key   # Only needed if using admin operations
```

### 2.3 Build

```bash
npx nest build
```

**Expected output:** No output = success. Exit code 0.
**Check:** `dist/` directory is created with compiled JS files.

### 2.4 Start Server

**Production mode:**
```bash
npm run start:prod
# or
node dist/main
```

**Development mode (with hot-reload):**
```bash
npm run start:dev
```

### 2.5 Verify Server is Running

```bash
# Health check
curl http://localhost:3000/health
```

**Expected response:**
```json
{"status":"ok","timestamp":"2026-06-12T18:45:36.124Z"}
```

```bash
# Swagger docs
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:3000/api/docs
```

**Expected response:** `HTTP 200`

**Open in browser:** [http://localhost:3000/api/docs](http://localhost:3000/api/docs)
— You should see the Swagger UI with all documented endpoints.

### 2.5 Expected Startup Logs

```
[NestFactory] Starting Nest application...
[InstanceLoader] ConfigModule dependencies initialized
[InstanceLoader] ConfigHostModule dependencies initialized
[InstanceLoader] HealthModule dependencies initialized
[InstanceLoader] DiscoveryModule dependencies initialized
[InstanceLoader] AppModule dependencies initialized
[InstanceLoader] ScheduleModule dependencies initialized
[InstanceLoader] SupabaseModule dependencies initialized
[InstanceLoader] AuthModule dependencies initialized
[InstanceLoader] UsersModule dependencies initialized
[RoutesResolver] AppController {/}:
[RouterExplorer] Mapped {/, GET} route
[RoutesResolver] HealthController {/health}:
[RouterExplorer] Mapped {/health, GET} route
[RoutesResolver] AuthController {/auth}:
[RouterExplorer] Mapped {/auth/register, POST} route
[RouterExplorer] Mapped {/auth/login, POST} route
[RouterExplorer] Mapped {/auth/me, GET} route
[RouterExplorer] Mapped {/auth/logout, POST} route
[NestApplication] Nest application successfully started
```

---

## 3. Supabase Setup

### 3.1 Create Supabase Project

1. Go to [app.supabase.com](https://app.supabase.com)
2. Click **New Project**
3. Enter project name: `eFordo`
4. Set a secure database password
5. Choose a region close to you
6. Click **Create**

### 3.2 Run Profiles Table Migration

1. In your Supabase dashboard, go to **SQL Editor**
2. Open `backend/api/src/supabase/profiles.sql`
3. Copy and paste the entire SQL content
4. Click **Run**

**Expected output:** `Success. No rows returned`

### 3.3 Get API Credentials

1. Go to **Project Settings → API**
2. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon/public key** → `SUPABASE_ANON_KEY`
   - **service_role key** → `SUPABASE_SERVICE_ROLE_KEY`
3. Paste into `backend/api/.env`

### 3.4 Verify Database

```sql
-- In Supabase SQL Editor, run:
SELECT * FROM public.profiles;
```

**Expected:** Empty result set (no users yet).

---

## 4. Frontend Setup & Run

### 4.1 Install Dependencies

```bash
cd frontend/flutter_app
flutter pub get
```

**Expected output:** `Changed 85 dependencies!`

### 4.2 Configure Environment

```bash
cd frontend/flutter_app
cp .env.example .env
```

Edit `.env`:

```env
API_BASE_URL=http://localhost:3000
```

### 4.3 Verify Analysis

```bash
flutter analyze
```

**Expected output:** `0 issues found` (may show info-level suggestions only, no errors or warnings).

### 4.4 Run on Web (Chrome)

```bash
flutter run -d chrome --web-port 5000
```

**Expected startup:**
- Chrome opens automatically
- App loads after ~30-60 seconds (first build is slow)
- You see the **eFordo splash screen**

### 4.5 Run on Mobile (Android/iOS)

#### Prerequisites

- **Android:** USB debugging enabled on your device
- **Windows:** Install [Google USB Driver](https://developer.android.com/studio/run/oem-usb) if needed
- **iOS (macOS only):** Xcode installed, iOS device trusted

#### Connect Your Device

1. Enable **Developer options** and **USB debugging** on your Android device
2. Connect via USB cable
3. Verify the device is detected:

```bash
flutter devices
```

**Expected output:** Your device listed as `mobile`:
```
POCO F1 • af6fb2f8 • android-arm64 • Android 12 (API 32)
```

#### Configure API URL for Physical Device

When running on a physical device, `localhost` refers to the device itself, **not** your development machine. The app will fail to connect to the backend if `API_BASE_URL=http://localhost:3000`.

👉 Update `frontend/flutter_app/.env` to use your **machine's local IP address**:

```env
# Windows: Run `ipconfig` to find your IPv4 address (e.g., 192.168.1.100)
# macOS/Linux: Run `ifconfig` or `ip addr`
API_BASE_URL=http://192.168.1.100:3000
```

Make sure the device is on the **same Wi-Fi network** as your development machine.

> **Alternative for Android (requires ADB):** You can use `adb reverse` to tunnel `localhost`:
> ```bash
> adb reverse tcp:3000 tcp:3000
> ```
> Then keep `API_BASE_URL=http://localhost:3000` — this forwards the device's `localhost:3000` to your machine.

#### Run the App

```bash
# List available devices (copy the device ID)
flutter devices

# Run on specific device by name
flutter run -d "POCO F1"

# Or use device ID
flutter run -d af6fb2f8
```

**First run:** ~2–5 minutes (builds APK, installs, and launches).
**Subsequent runs:** ~30–60 seconds.

#### Build APK (without running)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk

flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 4.6 Build for Production

```bash
# Web
flutter build web
# Output: build/web/

# Android APK
flutter build apk
# Output: build/app/outputs/flutter-apk/

# iOS (macOS only)
flutter build ios
# Output: build/ios/
```

---

## 5. Expected Behavior

### 5.1 Splash Screen → Login Flow

When you open the app:

```
┌─────────────────────────────────┐
│                                 │
│           ☐ (logo icon)         │
│                                 │
│          eFordo                 │
│     Project Management          │
│                                 │
│       ◌ (loading spinner)       │
│                                 │
└─────────────────────────────────┘
     (2 second delay, checking session)
            ↓
┌─────────────────────────────────┐
│                                 │
│          ☐ (logo icon)          │
│                                 │
│          eFordo                 │
│     Sign in to continue         │
│                                 │
│  ┌──────────────────────┐       │
│  │ Username or Email   👤│       │
│  └──────────────────────┘       │
│  ┌──────────────────────┐       │
│  │ Password          🔒👁│       │
│  └──────────────────────┘       │
│                                 │
│  ┌──────────────────────┐       │
│  │      Sign In          │       │
│  └──────────────────────┘       │
│                                 │
│   Don't have an account?        │
│        Create one               │
│                                 │
└─────────────────────────────────┘
```

**What happens:**
- **No stored session** → Redirects to `/login` after 2s
- **Stored valid session** → Redirects to `/dashboard`
- **Stored expired session** → Clears tokens → Redirects to `/login`

### 5.2 Registration

Click "Create one" → Registration form:

```
┌─────────────────────────────────┐
│ ←  Create Account               │
├─────────────────────────────────┤
│                                 │
│       Join eFordo               │
│  Create your account to start   │
│                                 │
│  ┌──────────────────────┐       │
│  │ Username           👤│       │
│  │ 3-30 chars, ...      │       │
│  └──────────────────────┘       │
│  ┌──────────────────────┐       │
│  │ Email             ✉️  │       │
│  └──────────────────────┘       │
│  ┌──────────────────────┐       │
│  │ Password          🔒👁│       │
│  └──────────────────────┘       │
│  ┌──────────────────────┐       │
│  │ Confirm Password   🔒👁│       │
│  └──────────────────────┘       │
│                                 │
│  ┌──────────────────────┐       │
│  │    Create Account     │       │
│  └──────────────────────┘       │
│                                 │
│   Already have an account?      │
│          Sign in                │
│                                 │
└─────────────────────────────────┘
```

**Validation rules:**
| Field | Rule |
|---|---|
| Username | 3–30 chars, letters/numbers/underscores only |
| Email | Valid email format |
| Password | 8+ characters |
| Confirm | Must match password |

**After successful registration:** Auto-login → Dashboard

### 5.3 Dashboard (Authenticated)

```
┌─────────────────────────────────┐
│ Dashboard                👤 ▾   │
├─────────────────────────────────┤
│ ┌─────────────────────────┐     │
│ │ 👤 Welcome, johndoe     │     │
│ │    john@example.com     │     │
│ └─────────────────────────┘     │
│                                 │
│ Quick Actions                   │
│ ┌──────┐ ┌──────┐ ┌──────┐     │
│ │  ＋  │ │  📂  │ │  ☑  │     │
│ │ New  │ │ My   │ │Recent│     │
│ │Project│ │Proj. │ │Tasks │     │
│ └──────┘ └──────┘ └──────┘     │
│                                 │
│ Overview                        │
│ ┌─────────────────────────┐     │
│ │ 📂 Active Projects   —  │     │
│ │─────────────────────────│     │
│ │ ☑ Pending Tasks      —  │     │
│ │─────────────────────────│     │
│ │ 👥 Team Members       —  │     │
│ └─────────────────────────┘     │
│                                 │
├─────────────────────────────────┤
│  📊    📂    ☑    ⚙️           │
│ Dash  Proj  Tasks  Settings     │
└─────────────────────────────────┘
```

**Bottom navigation:** 4 tabs switching between screens.

**User menu (top-right avatar):**
- Tap avatar → dropdown with profile info + Logout

### 5.4 Placeholder Screens

| Route | Screen | Shows |
|---|---|---|
| `/dashboard` | Dashboard | Welcome card, Quick Actions, Overview stats |
| `/projects` | Projects | "Projects module coming soon." |
| `/tasks` | Tasks | "Tasks module coming soon." |
| `/settings` | Settings | Theme toggle placeholder, Account placeholder |

### 5.5 Logout

1. Tap user avatar (top-right)
2. Select **Logout**
3. Tokens cleared from secure storage
4. Redirected to `/login`

---

## 6. API Endpoints Reference

### Health

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/health` | No | API health status |

```bash
curl http://localhost:3000/health
```
```json
{"status":"ok","timestamp":"2026-06-12T18:45:36.124Z"}
```

### Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/auth/register` | No | Create new account |
| `POST` | `/auth/login` | No | Sign in with username or email |
| `GET` | `/auth/me` | JWT | Get current user profile |
| `POST` | `/auth/logout` | JWT | Invalidate session |

### POST /auth/register

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "email": "john@example.com",
    "password": "securePass123"
  }'
```

**Success (201):**
```json
{"message": "Registration successful"}
```

**Errors:**
```json
{"message": "Username is already taken", "statusCode": 409}
{"message": "Email is already registered", "statusCode": 409}
{"message": "Password must be at least 8 characters", "statusCode": 400}
```

### POST /auth/login

```bash
# Login with email
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "john@example.com",
    "password": "securePass123"
  }'

# Login with username
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "johndoe",
    "password": "securePass123"
  }'
```

**Success (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "4c0f1b2a-3d5e-4f7a-8b9c-1d2e3f4a5b6c",
    "email": "john@example.com",
    "username": "johndoe",
    "display_name": null
  }
}
```

### GET /auth/me

```bash
curl http://localhost:3000/auth/me \
  -H "Authorization: Bearer <access_token>"
```

**Success (200):**
```json
{
  "user": {
    "id": "4c0f1b2a-3d5e-4f7a-8b9c-1d2e3f4a5b6c",
    "email": "john@example.com",
    "username": "johndoe",
    "display_name": null
  }
}
```

### POST /auth/logout

```bash
curl -X POST http://localhost:3000/auth/logout \
  -H "Authorization: Bearer <access_token>"
```

**Success (200):**
```json
{"message": "Logged out successfully"}
```

---

## 7. Flutter Routes

| Path | Screen | Auth Required |
|---|---|---|
| `/splash` | SplashScreen | No (entry point) |
| `/login` | LoginScreen | No |
| `/register` | RegisterScreen | No |
| `/dashboard` | DashboardScreen | Yes |
| `/projects` | ProjectsScreen | Yes |
| `/tasks` | TasksScreen | Yes |
| `/settings` | SettingsScreen | Yes |

**Redirect rules (GoRouter):**
- Unauthenticated user → blocked from shell routes → redirected to `/login`
- Authenticated user → blocked from `/login` and `/register` → redirected to `/dashboard`
- Splash → session check → `/dashboard` or `/login`

---

## 8. Troubleshooting

### Backend

| Problem | Solution |
|---|---|
| `port 3000 already in use` | Change `PORT` in `.env` or kill the process: `netstat -ano \| findstr :3000` |
| `Cannot find module './memoize'` (lodash) | Delete `node_modules` and reinstall: `rm -rf node_modules && npm install` |
| `Supabase credentials not configured` | Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env` |
| Build fails with TS errors | Run `npx nest build` and check error messages |

### Frontend

| Problem | Solution |
|---|---|
| `flutter: command not found` | Ensure Flutter is in PATH: `export PATH="$PATH:/c/flutter/bin"` |
| `Could not find an option named "--web-renderer"` | Remove `--web-renderer` flag, use: `flutter run -d chrome` |
| Build fails on web | Run `flutter clean && flutter pub get && flutter build web` |
| `HiveError: Box not found` | Ensure `Hive.initFlutter()` is called before accessing boxes |
| `.env` asset not found | Ensure `.env` file exists in `frontend/flutter_app/` |

### Database

| Problem | Solution |
|---|---|
| `relation "public.profiles" does not exist` | Run the `profiles.sql` migration in Supabase SQL Editor |
| `duplicate key value violates unique constraint` | Username or email already registered — use different values |
| Registration succeeds but no profile created | Check Supabase Auth settings: ensure email confirmation is disabled for testing |
