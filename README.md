# MyCamp 🗺️

MyCamp is an offline campus navigation application built using Flutter.  
It provides graph-based route calculation using JSON-defined nodes and edges, enabling structured navigation inside a campus environment.

---

## 📌 Features

- 🏫 Interactive campus map
- 📍 Graph-based navigation using Nodes & Edges
- 🧠 Shortest path calculation (Graph service layer)
- 💾 Offline data storage using Hive
- 👤 Admin user management screen
- 📦 Clean feature-based architecture

---

## 🏗 Architecture

The project follows a feature-based Clean Architecture structure:

lib/
│
├── core/
│ └── storage/
│
├── features/
│ ├── campus_navigation/
│ │ ├── data/
│ │ ├── domain/
│ │ └── presentation/
│ │
│ └── home/
│
└── main.dart


### Layers

- **Data Layer** → Models & local data services (JSON loading, storage)
- **Domain Layer** → Graph logic & business rules
- **Presentation Layer** → UI screens & coordinate mapping

---

## 🗂 Map Data Structure

Navigation is powered by JSON files:

- `nodes.json`
- `edges.json`
- `edges_with_geometry.json`
- `places.json`

These define the campus graph and routing structure.

---

## 🛠 Tech Stack

- Flutter
- Dart
- Hive (local storage)
- JSON-based graph structure

---

## 🚀 Getting Started

### 1️⃣ Clone the repository

```bash
git clone https://github.com/irfan28nizar/mycamp.git
cd mycamp
```

### 2️⃣ Set up environment variables

```bash
cp .env.example .env
```

Edit `.env` and fill in your Supabase credentials:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
ADMIN_EMAIL=your-admin@email.com
```

You can find these in **Supabase Dashboard → Project Settings → API**.

### 3️⃣ Install dependencies & run the app

```bash
flutter pub get
flutter run
```

---

## 🖥 Admin Web Dashboard

A standalone web app for managing Supabase users (create/delete) is located in the `admin_web/` folder.

### Setup

1. Copy the example config:

```bash
cp admin_web/env.example.js admin_web/env.js
```

2. Edit `admin_web/env.js` and fill in the same Supabase credentials from your `.env`.

### Create the admin user

Before logging into the admin dashboard, create the admin user in Supabase:

1. Go to **Supabase Dashboard** → **Authentication** → **Users**
2. Click **Add user** → **Create new user**
3. Enter your admin email and password, check **Auto Confirm User**
4. After creation, edit the user's **User Metadata** and set:
   ```json
   {"role": "admin"}
   ```

### Launch the dashboard

```bash
cd admin_web
python3 -m http.server 8080
```

Then open **http://localhost:8080** in your browser and sign in with the admin email and password.

From the dashboard you can:
- **Create users** with email, password, and role (student/admin/temp)
- **View** all users
- **Delete** users

> ⚠️ **Security note:** The admin dashboard uses the `service_role` key which has full access. Only run it locally or on a secured server. Never expose `env.js` publicly.
