# AGENTS.md

## Cursor Cloud specific instructions

### Overview

EXFIN REST is a Flutter-based restaurant management system designed primarily for Windows desktop with PostgreSQL as primary database. The app also compiles and runs on Web (Chrome) and Linux desktop.

### Running the app

- **Web (recommended for cloud agents):** `flutter run -d chrome --web-port=8080`
- **Linux desktop:** `flutter run -d linux`
- **Lint:** `flutter analyze`
- **Tests:** `flutter test` (no test directory exists currently)
- **Build web:** `flutter build web`

### Key environment requirements

- Flutter SDK is installed at `/opt/flutter/bin` — add to PATH: `export PATH="/opt/flutter/bin:$PATH"`
- PostgreSQL 16 runs on localhost:5432, database `exfin_db`, user `postgres`, password `Yq7xwQpt6c`
- Start PostgreSQL: `sudo pg_ctlcluster 16 main start`
- The `.env` file must exist at project root (copy from `env.example`)
- XDG user directories must be set up: `xdg-user-dirs-update`

### Platform-specific gotchas

1. **Linux desktop:** `DatabaseService` only initializes `sqfliteFfiInit()` and `databaseFactoryFfi` on Windows (`Platform.isWindows`). On Linux desktop, SQLite operations fail with "databaseFactory not initialized". The app renders but login/DB features don't work.

2. **Web (Chrome):** `dart:io` `Platform` class is unsupported on web. PostgreSQL direct connection fails, but the app renders with graceful error handling showing "DB Bağlantısı Kapalı" and "Hızlı giriş başarısız" on login attempts.

3. **C++ build toolchain:** Linux desktop build requires a symlink for clang++ to find libstdc++: `sudo ln -sf /usr/lib/gcc/x86_64-linux-gnu/13/libstdc++.so /usr/lib/x86_64-linux-gnu/libstdc++.so` and C++ headers: `sudo ln -sf /usr/include/c++/13 /usr/include/c++/14`.

4. **Database schema:** Load with `sudo -u postgres psql -d exfin_db -f Sql/database_setup.sql`. This drops and recreates all tables with seed data.

### Default credentials (from database seed)

| Username | Password | Role |
|----------|----------|------|
| admin | admin123 | admin |
| manager | password | manager |
| cashier | password | cashier |
| waiter | password | waiter |
| kitchen | password | kitchen |
| guest | password | guest |
