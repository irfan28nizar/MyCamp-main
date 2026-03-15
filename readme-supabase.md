 # Supabase Authentication Migration Guide

This document explains **every change** made to migrate MyCamp from hardcoded local authentication (using Hive) to cloud-based authentication using **Supabase**. If you're a student picking this up, read through carefully — it covers the _why_ and _how_ of each change.

---

## Table of Contents

1. [What Was There Before (The Old System)](#1-what-was-there-before-the-old-system)
2. [What We Built (The New System)](#2-what-we-built-the-new-system)
3. [Architecture Overview](#3-architecture-overview)
4. [New Dependencies](#4-new-dependencies)
5. [Environment Variables Setup](#5-environment-variables-setup)
6. [File-by-File Changes](#6-file-by-file-changes)
7. [Admin Web Dashboard](#7-admin-web-dashboard)
8. [How Authentication Works Now](#8-how-authentication-works-now)
9. [How to Set Up From Scratch](#9-how-to-set-up-from-scratch)
10. [Common Issues & Troubleshooting](#10-common-issues--troubleshooting)

---

## 1. What Was There Before (The Old System)

The app originally used **Hive** (a local key-value store) with **hardcoded credentials**:

```dart
// OLD CODE (DELETED) — lib/features/auth/data/repositories/hive_auth_repository.dart

// Hardcoded users — anyone could see these in the source code!
final users = {
  'admin': {'password': 'admin123', 'role': 'admin'},
  'student': {'password': 'student123', 'role': 'student'},
};
```

**Problems with the old approach:**
- Credentials were visible in source code (security risk)
- Only 2 users existed — no way to add more
- No real authentication — just string comparison
- No session management — user had to log in every time
- No way for an admin to manage users

---

## 2. What We Built (The New System)

| Feature | Old | New |
|---------|-----|-----|
| Authentication | Hardcoded strings | Supabase Auth (email + password) |
| User storage | None (in-memory) | Supabase cloud database |
| User management | Not possible | Admin panel in app + web dashboard |
| Session persistence | None | Supabase JWT sessions (auto-restore) |
| Credentials in code | Yes (hardcoded) | No — stored in `.env` file |
| Password change | Not possible | Forced on first login |
| User roles | admin, student | admin, student, teacher, temp |
| User metadata | None | Name, phone, branch, year |

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
│                                                         │
│  LoginScreen → SupabaseAuthRepository → Supabase Auth  │
│  ProfileScreen ←──────────┘                             │
│  AdminScreen ─── createUser() ──→ Supabase Admin API   │
│  ChangePasswordScreen ── updatePassword() ──→ Supabase │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              Admin Web Dashboard (HTML/JS)              │
│                                                         │
│  Login ──→ Supabase Auth (anon key)                    │
│  Create/Delete Users ──→ Supabase Admin API            │
│                           (service_role key)            │
└─────────────────────────────────────────────────────────┘

                         ↕ HTTPS ↕

┌─────────────────────────────────────────────────────────┐
│                   Supabase Cloud                        │
│                                                         │
│  Auth Service ── stores users, passwords, sessions     │
│  user_metadata ── stores role, name, phone, etc.       │
└─────────────────────────────────────────────────────────┘
```

### Two Supabase Clients

The app uses **two different Supabase clients** — this is important to understand:

1. **Regular client** (uses `SUPABASE_ANON_KEY`): Used for normal operations — login, logout, get current user, update own password. This is what end users interact with.

2. **Admin client** (uses `SUPABASE_SERVICE_ROLE_KEY`): Used only by admins to create users, delete users, and list all users. The service role key bypasses Row Level Security and has full admin access.

```dart
// Regular client — initialized in main.dart
final _client = Supabase.instance.client;

// Admin client — created separately in the auth repository
SupabaseClient get _admin {
  _adminClient ??= SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
  );
  return _adminClient!;
}
```

---

## 4. New Dependencies

Added to `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.8.4    # Supabase SDK for Flutter
  flutter_dotenv: ^5.2.1      # Load environment variables from .env file
```

- **supabase_flutter**: The official Supabase SDK. Handles authentication, session management, and API calls to Supabase.
- **flutter_dotenv**: Reads the `.env` file at runtime so we don't hardcode API keys in source code.

Also added `.env` as an asset so the app can read it:

```yaml
flutter:
  assets:
    - .env
    - assets/images/auth/
    - assets/maps/
```

---

## 5. Environment Variables Setup

### Why environment variables?

API keys and secrets should **never** be committed to version control. We use a `.env` file that is listed in `.gitignore` so it stays on your machine only.

### `.env` file (create this in the project root):

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
ADMIN_EMAIL=admin@example.com
```

### `.env.example` file (committed to git — shows the structure without real values):

```
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY
ADMIN_EMAIL=YOUR_ADMIN_EMAIL
```

### Where to find these values:

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`
   - **service_role** key → `SUPABASE_SERVICE_ROLE_KEY`

### `.gitignore` additions:

```
.env
admin_web/env.js
```

---

## 6. File-by-File Changes

### Files DELETED:
- `lib/features/auth/data/repositories/hive_auth_repository.dart` — The old hardcoded auth. Completely removed.

### Files CREATED:
- `lib/features/auth/data/repositories/supabase_auth_repository.dart` — New Supabase auth implementation
- `lib/features/auth/presentation/screens/change_password_screen.dart` — Force password change on first login
- `.env` / `.env.example` — Environment variable files
- `admin_web/index.html` — Web admin dashboard
- `admin_web/env.js` / `admin_web/env.example.js` — Web dashboard config

### Files MODIFIED:
- `pubspec.yaml` — Added dependencies and `.env` asset
- `lib/main.dart` — Supabase initialization + session restore
- `lib/features/auth/domain/models/user.dart` — User model updated
- `lib/features/auth/domain/repositories/auth_repository.dart` — Interface updated
- `lib/features/auth/presentation/screens/login_screen.dart` — Email-based login
- `lib/features/home/presentation/screens/profile_screen.dart` — New user info display
- `lib/features/admin/presentation/screens/admin_screen.dart` — Create user form
- `lib/features/admin/presentation/screens/manage_users_screen.dart` — User list
- `lib/features/campus_navigation/presentation/screens/campus_navigation_screen.dart` — Import update
- `macos/Runner/DebugProfile.entitlements` — Network permission
- `macos/Runner/Release.entitlements` — Network permission
- `.gitignore` — Added `.env` and `admin_web/env.js`

---

### 6.1 `lib/main.dart` — App Entry Point

**What changed:** Added Supabase initialization and session auto-restore.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  // Initialize Supabase with URL and anon key from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Still init Hive for campus navigation data (not auth)
  await HiveInitializer.init();

  runApp(const MyApp());
}
```

**Session restore logic** — When the app starts, it checks if the user is already logged in:

```dart
Widget _getHomeScreen() {
  final client = Supabase.instance.client;
  final session = client.auth.currentSession;

  // No session? Show login screen
  if (session == null) return const LoginScreen();

  // User must change password? Show change password screen
  final metadata = client.auth.currentUser?.userMetadata;
  if (metadata?['must_change_password'] == true) {
    return const ChangePasswordScreen();
  }

  // All good — go to home
  return const HomeScreen();
}
```

---

### 6.2 `lib/features/auth/domain/models/user.dart` — User Model

**Before:** Only had `id`, `username`, `role`.

**After:** Has `id`, `email`, `role`, `name`, `phone`, `year`, `branch`.

```dart
class User {
  const User({
    required this.id,
    required this.email,
    required this.role,
    this.name,       // Full name (optional)
    this.phone,      // Phone number (optional)
    this.year,       // e.g. "2nd Year" (optional, students only)
    this.branch,     // e.g. "Computer Science" (optional)
  });

  // Display name: use name if set, otherwise extract from email
  String get displayName =>
      (name != null && name!.isNotEmpty) ? name! : email.split('@').first;
}
```

**Key change:** `username` was replaced with `email` everywhere. The `displayName` getter provides a friendly name — it uses the `name` metadata if available, otherwise extracts the part before `@` from the email.

---

### 6.3 `lib/features/auth/domain/repositories/auth_repository.dart` — Interface

**Added methods:**

```dart
abstract class AuthRepository {
  Future<User?> login(String email, String password);  // was username
  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<User?> signUp(String email, String password, {String role});  // NEW
  Future<void> deleteUser(String userId);                               // NEW
  Future<List<User>> listUsers();                                       // NEW
}
```

---

### 6.4 `lib/features/auth/data/repositories/supabase_auth_repository.dart` — The Core

This is the most important new file. Here's what each method does:

#### `login(email, password)`
Calls `_client.auth.signInWithPassword()` — Supabase validates the credentials against its auth database and returns a session + user object.

#### `getCurrentUser()`
Returns the currently cached user from `_client.auth.currentUser`. No network call needed — Supabase SDK caches the session locally.

#### `logout()`
Calls `_client.auth.signOut()` — clears the session locally and on the server.

#### `signUp(email, password, {role})`
Registers a new user via `_client.auth.signUp()`. Stores `role` and `must_change_password: true` in `user_metadata`.

#### `createUser(email, password, {role, name, phone, year, branch})`
**Admin-only.** Uses the **admin client** (`_admin`) with the service_role key to call `admin.createUser()`. This:
- Creates the user with confirmed email (no verification needed)
- Sets the password directly
- Stores all metadata: role, name, phone, year, branch, must_change_password

#### `mustChangePassword`
Reads `must_change_password` from the current user's metadata. Returns `true` if the user needs to set a new password.

#### `updatePassword(newPassword)`
Updates the user's password and sets `must_change_password: false` in their metadata. Used by the ChangePasswordScreen.

#### `deleteUser(userId)` / `listUsers()`
**Admin-only.** Uses the admin client to delete users or list all users.

#### `_toAppUser(supabaseUser)`
Maps a Supabase `User` object to the app's `User` model. Extracts role, name, phone, year, branch from `userMetadata`.

---

### 6.5 `lib/features/auth/presentation/screens/login_screen.dart`

**Before:** Had a "Username" field. Compared against hardcoded strings.

**After:** Has an "Email" field. Calls `SupabaseAuthRepository.login()` which authenticates against Supabase.

**Key addition — first login redirect:**

```dart
if (user != null) {
  if (_authRepository.mustChangePassword) {
    // First login — force password change
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => const ChangePasswordScreen(),
    ));
  } else {
    // Normal login — go to home
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => const HomeScreen(),
    ));
  }
}
```

---

### 6.6 `lib/features/auth/presentation/screens/change_password_screen.dart` — NEW

This screen appears when a newly created user logs in for the first time. It:

1. Shows two fields: "New Password" and "Confirm Password"
2. Validates they match and are at least 6 characters
3. Calls `updatePassword()` which updates the password in Supabase AND sets `must_change_password: false`
4. Signs the user out and redirects to login (they log in again with their new password)

---

### 6.7 `lib/features/admin/presentation/screens/admin_screen.dart` — Create User

**Before:** No user creation capability.

**After:** An admin can create users with:
- Email (required)
- Initial Password (auto-filled with "Welcome@321", visible, with copy button)
- Full Name
- Phone Number
- Branch (e.g. "Computer Science")
- Role: Student / Teacher / Admin / Temp
- Year: 1st–4th Year (only shown for Student and Temp roles)

All this data is stored in Supabase `user_metadata`.

---

### 6.8 `lib/features/home/presentation/screens/profile_screen.dart`

**Changes:**
- Shows display name (from `name` metadata, or email prefix)
- Shows email
- Shows role (capitalized, e.g. "Student", "Teacher", "Admin")
- Shows additional info card with phone, branch, year (if available)
- Admin Panel button only visible for admin users
- Logout clears Supabase session

---

### 6.9 `lib/features/campus_navigation/presentation/screens/campus_navigation_screen.dart`

**Changes:**
- Changed import from `HiveAuthRepository` to `SupabaseAuthRepository`
- Fixed menu visibility: popup menu (with logout + admin panel) now shows for **all roles** (was previously broken for teachers — they had no logout button!)
- Admin Panel menu item still only appears for admin role

---

### 6.10 macOS Entitlements

Added network permission so the app can connect to Supabase:

```xml
<!-- Added to both DebugProfile.entitlements and Release.entitlements -->
<key>com.apple.security.network.client</key>
<true/>
```

Without this, macOS blocks outgoing HTTP connections and you get "Operation not permitted" errors.

---

## 7. Admin Web Dashboard

Located in `admin_web/index.html` — a standalone HTML/JS page for managing users from a browser.

### Features:
- **Login** — admin email + password (only admin users can access)
- **Create users** — same fields as the Flutter admin screen (3 per row layout)
- **Users table** — shows name, email, phone, role, branch, year, password changed status, last sign-in, created date
- **Search** — real-time filter by name, email, phone, branch, year
- **Role filter** — dropdown to show only students, teachers, etc.
- **Delete users** — with confirmation (admin email is protected from deletion)
- **Session auto-restore** — stays logged in on page refresh

### How it works:

```javascript
// Regular client for login/logout
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Admin client for user management (bypasses Row Level Security)
const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});
```

### Configuration:

Create `admin_web/env.js` (from `env.example.js`):

```javascript
window.__ENV__ = {
  SUPABASE_URL: 'https://your-project.supabase.co',
  SUPABASE_ANON_KEY: 'your-anon-key',
  SUPABASE_SERVICE_ROLE_KEY: 'your-service-role-key',
  ADMIN_EMAIL: 'admin@example.com',
};
```

### Running locally:

```bash
cd admin_web
python3 -m http.server 8080
# Open http://localhost:8080
```

---

## 8. How Authentication Works Now

### User Creation Flow:

```
Admin creates user (app or web)
        ↓
Supabase stores: email, password (hashed), user_metadata
        ↓
user_metadata = {
  "role": "student",
  "name": "John Doe",
  "phone": "+91 9876543210",
  "branch": "Computer Science",
  "year": "2nd Year",
  "must_change_password": true    ← this flag is key
}
```

### First Login Flow:

```
User enters email + initial password ("Welcome@321")
        ↓
Supabase validates credentials → success
        ↓
App checks: must_change_password == true?
        ↓ YES
ChangePasswordScreen appears
        ↓
User enters new password → updatePassword() called
        ↓
Supabase updates password + sets must_change_password = false
        ↓
User is signed out → logs in again with new password
        ↓
must_change_password == false → goes to HomeScreen
```

### Subsequent Logins:

```
User enters email + password
        ↓
Supabase validates → success
        ↓
must_change_password == false → HomeScreen
```

### Session Persistence:

When the app starts, `main.dart` checks `Supabase.instance.client.auth.currentSession`. If a valid session exists (JWT not expired), the user skips the login screen entirely.

### Where User Data Lives in Supabase:

All user data is in Supabase's **Authentication** service, specifically in `user_metadata` (also called `raw_user_meta_data` in the raw JSON). You can see it in the Supabase Dashboard under **Authentication → Users → click a user → User Metadata**.

```json
{
  "role": "student",
  "name": "John Doe",
  "phone": "+91 9876543210",
  "branch": "Computer Science",
  "year": "2nd Year",
  "must_change_password": false
}
```

---

## 9. How to Set Up From Scratch

### Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a free account
2. Create a new project (pick a name, set a database password, choose a region)
3. Wait for the project to be provisioned

### Step 2: Get API Keys

1. Go to **Settings → API** in your Supabase Dashboard
2. Copy the **Project URL**, **anon key**, and **service_role key**

### Step 3: Configure the Flutter App

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Fill in your Supabase values in `.env`

### Step 4: Create the Admin User

1. In Supabase Dashboard, go to **Authentication → Users → Add User**
2. Enter admin email and password, check "Auto Confirm User"
3. After creation, you need to set the admin's role. Run this in your terminal (replace the values):
   
   ```bash
   curl -X PUT \
     'https://YOUR_PROJECT.supabase.co/auth/v1/admin/users/USER_ID_HERE' \
     -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
     -H "apikey: YOUR_SERVICE_ROLE_KEY" \
     -H "Content-Type: application/json" \
     -d '{"user_metadata": {"role": "admin", "must_change_password": false}}'
   ```
   
   (The USER_ID is shown in the Supabase Dashboard when you click on the user)

### Step 5: Install Dependencies & Run

```bash
flutter pub get
flutter run
```

### Step 6: Set Up Web Admin Dashboard (Optional)

1. Copy `admin_web/env.example.js` to `admin_web/env.js`
2. Fill in your Supabase values
3. Run: `cd admin_web && python3 -m http.server 8080`
4. Open `http://localhost:8080` and log in with your admin email

---

## 10. Common Issues & Troubleshooting

### "Invalid email or password" when logging in
- Make sure the user exists in Supabase Dashboard → Authentication → Users
- If you created the user via Dashboard (not via the app/admin panel), their `user_metadata` might be missing. The app still authenticates fine, but the role will default to "student".

### Admin user shows as "Student" in the app
- The admin user created directly in Supabase Dashboard doesn't have `role: admin` in their metadata. Use the curl command in Step 4 above to set it.

### "Operation not permitted" on macOS
- The macOS entitlements need `com.apple.security.network.client` set to `true`. This was already added to both `DebugProfile.entitlements` and `Release.entitlements`.

### Users created in the admin panel can't log in
- Make sure the Flutter app is using the **service_role key** for the admin client (not the anon key). The `createUser` method in `supabase_auth_repository.dart` uses `_admin` (service_role) while `login` uses `_client` (anon key).

### "Teacher" users can't see the menu / can't logout
- This was a bug that was fixed. The campus navigation screen's popup menu originally only showed for `student` and `admin` roles. It now shows for all authenticated users. Only the "Admin Panel" menu item is restricted to admins.

### Year field showing for teachers
- The Year dropdown in the create user form is intentionally hidden for `teacher` and `admin` roles. It only appears for `student` and `temp` roles.

### Password not resetting on first login
- The `must_change_password` flag must be `true` in the user's metadata. When users are created via `createUser()`, this is set automatically. If you create users manually in the Supabase Dashboard, you'll need to set this flag yourself.

---

## Summary of Key Concepts for New Developers

1. **Supabase Auth** handles all user creation, password hashing, session tokens (JWT), and login validation. We never store or compare passwords ourselves.

2. **user_metadata** is a JSON object on each Supabase user where we store custom fields (role, name, phone, etc.). It's readable and writable via the Supabase SDK.

3. **Two API keys**: The `anon` key is safe to use client-side (limited permissions). The `service_role` key is a superadmin key — it bypasses all security rules. Keep it secret.

4. **`.env` file**: Contains sensitive keys. Never commit it to git. Share it securely with teammates.

5. **Clean Architecture**: The app separates concerns — `domain/models/user.dart` defines what a User is, `domain/repositories/auth_repository.dart` defines the interface, and `data/repositories/supabase_auth_repository.dart` is the concrete implementation. If you ever need to switch auth providers, you only change the data layer.
