# Smart Reporting System - Technical & Functional Documentation

This document provides a comprehensive overview of the **Smart Reporting System** project, describing its architecture, technology stack, database schemas, API endpoints, frontend screens, offline synchronization logic, third-party libraries, and code directories.

---

## 1. System Architecture Overview

The Smart Reporting System is built as a client-server application, facilitating reporting of campus incidents (e.g., maintenance, security, IT issues) by students, and monitoring/managing of these reports by administrators at Hazara University.

```
       +-----------------------------------------------------------+
       |                     FLUTTER APP                           |
       |  (UI Screens: Splash, Login, Upload Dashboard, Admin Map)  |
       +-----------------------------+-----------------------------+
                                     |
                REST APIs            |   Local SQLite DB (`sqflite`)
                (JSON / JWT)         |   (For caching offline drafts)
                                     v
       +-----------------------------------------------------------+
       |                    DJANGO BACKEND                         |
       |  (Authentication, Media Uploads, API Views, Serializers)  |
       +-----------------------------+-----------------------------+
                                     |
                                     |  Django ORM
                                     v
       +-----------------------------------------------------------+
       |                 SQLITE DATABASE (Backend)                 |
       |  (Tables: User, Report, Location, Media)                  |
       +-----------------------------------------------------------+
```

---

## 2. Technology Stack & Languages

The project is implemented using the following programming languages and framework environments:

| Language / Tech | Layer | Purpose |
| :--- | :--- | :--- |
| **Python** | Backend | Drives the Django and Django REST Framework API server, handling business logic, DB queries, auth, and dashboard metrics. |
| **Dart** | Frontend | Powers the cross-platform Flutter application, handling user interface rendering, device services (GPS, Camera), local caching, and HTTP communication. |
| **SQL (SQLite)** | Database | Relational database storage. Used as `db.sqlite3` on the backend and via the `sqflite` plugin for mobile offline queue storage. |
| **YAML** | Config | Used by Flutter (`pubspec.yaml`) to manage project metadata, assets, fonts, and packages. |
| **JSON** | Data Transfer | Format used for API requests, responses, and local config references (e.g., `osm_data.json`). |

---

## 3. Third-Party Libraries & Dependencies

### 3.1 Backend (Python / Django)
*   **Django (`6.0.6`)**: Core MVC framework for request routing, database modeling, and admin panels.
*   **djangorestframework (`3.17.1`)**: Provides toolkits for building RESTful APIs, serializer processing, and status responses.
*   **djangorestframework_simplejwt (`5.5.1`)**: Implements JSON Web Token (JWT) authentication for secure stateless sessions.
*   **django-cors-headers (`4.9.0`)**: Middleware to enable Cross-Origin Resource Sharing (CORS) so that frontend clients can communicate with the APIs.
*   **pillow (`12.2.0`)**: Python Imaging Library used for processing uploaded photos and images.
*   **python-dotenv (`1.2.2`)**: Loads environment variables from `.env` configuration files.
*   **python-dateutil (`2.9.0.post0`)**: Offers advanced date/time manipulations (specifically used for calculating account expiry dates via `relativedelta`).
*   **whitenoise (`6.9.0`)**: Serves static media files directly from Django in production.
*   **gunicorn (`23.0.0`)**: Production-ready WSGI HTTP server to execute Django app.

### 3.2 Frontend (Dart / Flutter)
*   **provider (`^6.1.2`)**: Flutter state management library to publish login statuses and user profile changes across screens.
*   **http (`^1.2.1`)**: Standard package for initiating HTTP GET, POST, PATCH, and Multi-part requests to the backend server.
*   **shared_preferences (`^2.2.2`)**: Stores lightweight key-value pairs (like JWT access tokens, usernames, and roles) persistently on the local device storage.
*   **google_maps_flutter (`^2.9.0`)**: Embeds interactive Google Maps directly in screens, rendering markers for campus locations and report Coordinates.
*   **geolocator (`^14.0.3`)**: Accesses mobile GPS coordinates to acquire current latitude/longitude coordinates.
*   **image_picker (`^1.1.0`)**: Interacts with the native system UI to snap photos/videos using the camera or select from the gallery.
*   **sqflite (`^2.3.0`) & path (`^1.9.0`)**: Creates a local SQLite database to queue incident reports on device storage when working offline.
*   **connectivity_plus (`^7.1.1`)**: Monitors active network status (Mobile Data, Wi-Fi, None) to automate background report synchronization.
*   **url_launcher (`^6.3.0`)**: Launches system browsers or external players to display uploaded media files (e.g., videos).
*   **permission_handler (`^12.0.3`)**: Handles permission check prompts (Camera, Location, Storage) gracefully.

---

## 4. Database Schema (SQLite)

The backend SQLite database `db.sqlite3` contains the following primary tables, managed by Django's Object-Relational Mapper (ORM):

### 4.1 `reports_user` (Custom User Table)
Stores credential and profile details for both students and administrators.
*   `id` (INTEGER, Primary Key): Unique auto-incrementing ID.
*   `password` (VARCHAR): Hashed user password.
*   `last_login` (DATETIME): Timestamp of last sign-in.
*   `is_superuser` (BOOLEAN): Admin superuser status flag.
*   `roll_number` (VARCHAR, Unique): Student roll number or Admin identifier (e.g., `k21-123` or `admin`). Acts as the username.
*   `name` (VARCHAR): Display name of the user.
*   `role` (VARCHAR): User type, restricted to `student` or `admin`.
*   `program` (VARCHAR): Academic program, restricted to `bs` (BS 4-Year) or `ms` (MS 2-Year).
*   `account_expiry` (DATE): Account validity limit. Dynamically calculated upon student creation (Current date + 4 years for BS, + 2 years for MS).
*   `fcm_token` (TEXT): Firebase Cloud Messaging token to receive push notifications.
*   `is_active` (BOOLEAN): Status flag to enable/disable login.
*   `is_staff` (BOOLEAN): Enables entry permission to Django admin panel.

### 4.2 `reports_report` (Incident Reports)
Holds text metadata and associations for submitted complaints.
*   `id` (INTEGER, Primary Key): Unique auto-incrementing ID.
*   `title` (VARCHAR): Incident title or category name.
*   `description` (TEXT): Detailed description of the problem.
*   `image_url` (VARCHAR): Web URL pointing to the uploaded media file.
*   `status` (VARCHAR): Process status, restricted to `pending`, `reviewing`, or `resolved`.
*   `submitted_at` (DATETIME): Automatically set when the report is first created.
*   `updated_at` (DATETIME): Automatically updated whenever the record changes.
*   `student_id` (INTEGER, Foreign Key): Links report to the `reports_user` who submitted it.

### 4.3 `reports_location` (Report Coordinates)
One-to-One association with reports to locate incidents on maps.
*   `id` (INTEGER, Primary Key): Unique ID.
*   `latitude` (DECIMAL): GPS latitude coordinate (up to 6 decimal places).
*   `longitude` (DECIMAL): GPS longitude coordinate (up to 6 decimal places).
*   `address` (VARCHAR): Decoded descriptive address location (optional).
*   `report_id` (INTEGER, Foreign Key / Unique): One-to-One reference to `reports_report`.

### 4.4 `reports_media` (Report Media Attachments)
Stores links to multiple media files associated with reports.
*   `id` (INTEGER, Primary Key): Unique ID.
*   `file_url` (VARCHAR): URL pointer of the asset.
*   `media_type` (VARCHAR): Media format, restricted to `photo` or `video`.
*   `report_id` (INTEGER, Foreign Key): Reference link to `reports_report`.

---

## 5. API Endpoints Catalog

All URLs are prefixed with `/api/` (except Django Admin). Authorization endpoints require a JWT header: `Authorization: Bearer <access_token>`.

### 5.1 Authentication API
*   **`POST /api/login/`**
    *   *Access*: Public
    *   *Payload*: `{"roll_number": "...", "password": "..."}`
    *   *Functionality*: Authenticates username/password. Returns access and refresh JWT tokens alongside the user's role and name.
*   **`GET /api/auth/me/`**
    *   *Access*: Authenticated Users
    *   *Functionality*: Returns details of the logged-in user profile.
*   **`POST /api/auth/change-password/`**
    *   *Access*: Authenticated Users
    *   *Payload*: `{"new_password": "..."}`
    *   *Functionality*: Updates user password (minimum 6 characters).
*   **`POST /api/auth/update-profile/`**
    *   *Access*: Authenticated Users
    *   *Payload*: `{"name": "..."}`
    *   *Functionality*: Modifies user's profile display name.

### 5.2 Student Incident API
*   **`POST /api/reports/submit/`**
    *   *Access*: Authenticated Students (Non-expired accounts)
    *   *Payload*: `{"title": "...", "description": "...", "latitude": float, "longitude": float, "media_url": "...", "address": "..."}`
    *   *Functionality*: Creates an incident report and binds geographic coordinate records inside a database transaction.
*   **`GET /api/my-reports/`**
    *   *Access*: Authenticated Students
    *   *Functionality*: Returns a list of all incident reports submitted by the logged-in student, ordered newest first.
*   **`POST /api/sync-reports/`**
    *   *Access*: Authenticated Students
    *   *Payload*: `{"reports": [{"title": "...", "description": "...", "latitude": ..., "longitude": ..., "image_url": "...", "address": "..."}, ...]}`
    *   *Functionality*: Syncs multiple offline reports captured locally by the device during network disconnection in an atomic block.
*   **`POST /api/upload-media/`**
    *   *Access*: Authenticated Students
    *   *Payload*: Multipart form-data with key `file` containing raw file bytes.
    *   *Functionality*: Validates and stores files in settings.MEDIA_ROOT under unique UUID filenames. Returns the absolute server URL.
*   **`POST /api/register-fcm/`**
    *   *Access*: Authenticated Students
    *   *Payload*: `{"fcm_token": "..."}`
    *   *Functionality*: Saves the device FCM push notification token.

### 5.3 Administrative Dashboard API
*   **`GET /api/all-reports/`**
    *   *Access*: Authenticated Admins
    *   *Functionality*: Retrieves all reports submitted in the system.
*   **`PATCH /api/reports/<id>/status/`**
    *   *Access*: Authenticated Admins
    *   *Payload*: `{"status": "pending"|"reviewing"|"resolved"}`
    *   *Functionality*: Updates report status. Emits simulated push notification logs.
*   **`GET /api/dashboard/`**
    *   *Access*: Authenticated Admins
    *   *Parameters (Query)*: `?status=...&days=...`
    *   *Functionality*: Calculates summary statistics (total report count, status splits, student counts grouped by BS/MS, and time-based metrics for today/week/month).
*   **`GET /api/heatmap/`**
    *   *Access*: Authenticated Admins
    *   *Parameters (Query)*: `?status=...&days=...`
    *   *Functionality*: Extracts coordinates of reports to plot heat overlays or markers on maps.
*   **`POST /api/create-student/`**
    *   *Access*: Authenticated Admins
    *   *Payload*: `{"roll_number": "...", "name": "...", "program": "bs"|"ms", "password": "..."}`
    *   *Functionality*: Creates a single student user.
*   **`POST /api/bulk-create/`**
    *   *Access*: Authenticated Admins
    *   *Payload*: `{"prefix": "...", "start": int, "end": int, "program": "bs"|"ms", "password": "..."}`
    *   *Functionality*: Dynamically creates a batch range of user profiles (e.g., `Prefix="hu-", Start="001", End="050"` registers `hu-001` through `hu-050` with automatic pad-width parsing).

---

## 6. Frontend Core Services & State Management

### 6.1 State Management via Provider (`AuthManager`)
The app uses the Provider framework for authentication state management:
*   `login()` calls `ApiService.login()` to authenticate credentials. If successful, it parses user profiles, stores tokens and details persistently in `SharedPreferences`, and calls `notifyListeners()`.
*   `loadUser()` is executed at app startup to check if tokens are cached in `SharedPreferences` to perform automatic logins.
*   `updateName()` calls the backend to edit names, updates `SharedPreferences` cache, and updates UI listeners.
*   `logout()` flushes SharedPreferences cache, resets variables, and returns the app back to the login screen.

### 6.2 Offline Storage & Sync Queue (`OfflineQueue` & `SyncManager`)
The application is designed to operate seamlessly in offline conditions (e.g., weak campus Wi-Fi):

1.  **Local SQLite Cache (`OfflineQueue`)**:
    *   If a student submits a report while offline, or clicks "Save as Draft", the app uses the `sqflite` plugin to store report information in a local device SQLite database file (`offline_reports.db`).
    *   The local table stores `id`, `title`, `description`, `latitude`, `longitude`, `file_path` (reference to local file system media), and `media_type`.
2.  **Periodic Background Sync (`SyncManager`)**:
    *   Initialized on app startup (`SyncManager.initialize()`).
    *   Runs a periodic background loop (configured by `AppConstants.syncIntervalSeconds`).
    *   In each cycle, it queries `connectivity_plus` to verify internet availability.
    *   If online, it fetches all queued drafts, uploads the media files to the server using multi-part requests (`ApiService.uploadMedia()`), submits the report online, and deletes successful entries from the local database.

---

## 7. Folder and File Catalog

Below is a map of the file system detailing each file's purpose:

### 7.1 Backend Directory Tree
```
backend/
│  manage.py                       # CLI admin script.
│  requirements.txt                # Python backend dependencies list.
│  db.sqlite3                      # SQL database file (contains tables).
│
├─backend/                         # Project Configuration Root
│      asgi.py                     # Asynchronous server entry point.
│      settings.py                 # Core system settings, middleware, database config.
│      urls.py                     # Top-level API router mapping.
│      wsgi.py                     # Synchronous WSGI web application server hook.
│
└─reports/                         # Main Backend Application
    │  admin.py                    # Django Admin configuration.
    │  api.py                      # Student Single Creation View.
    │  apps.py                     # Django application registry setup.
    │  auth_api.py                 # Auth logic, JWT issuance, profile updates.
    │  dashboard_api.py            # Analytics calculator for Admin dashboards.
    │  forms.py                    # Admin form validations.
    │  heatmap_api.py              # Map coordinates API.
    │  media_api.py                # File uploader and path converter.
    │  models.py                   # ORM structures for User, Report, Location, Media.
    │  notification_api.py         # Client token registers.
    │  notify.py                   # Print log engine simulating push alerts.
    │  permissions.py              # Role permissions validator (Admin/Student checks).
    │  serializers.py              # Serializers converting ORM queries to JSON.
    │  sync_api.py                 # Core transactional engine to handle batch offline syncs.
    │  urls.py                     # App endpoints directory mapping.
    │  views.py                    # Core views for reports and user creations.
```

### 7.2 Frontend Directory Tree
```
frontend/
│  pubspec.yaml                    # Flutter project description, assets, and packages.
│
└─lib/                             # Flutter Code Base
    │  main.dart                   # App entry point, routing directory, theme configs.
    │
    ├─managers/                    # App State Managers
    │      auth_manager.dart       # State provider for login lifecycle & user data.
    │      campus_map_manager.dart # University landmark coordinates fallback database.
    │
    ├─models/                      # Structured Data Formats
    │      campus_location.dart    # Mapping structures for landmark geopoints.
    │
    ├─screens/                     # Application User Interfaces
    │      admin_map_screen.dart   # Interactive Google Map, filters, status tools.
    │      change_password_screen.dart # Security settings updater.
    │      create_students_screen.dart # Create single or batch student accounts.
    │      drafts_screen.dart      # Displays offline saved reports with manual sync.
    │      login_screen.dart       # Credentials login form page.
    │      map_verification_screen.dart # Google Map verification page to confirm report pin.
    │      my_reports_screen.dart  # Personal logs of student-submitted reports.
    │      splash_screen.dart      # First screen, loading cached credentials.
    │      upload_screen.dart      # Main student dashboard to draft or submit reports.
    │
    ├─services/                    # Interface Services
    │      api_service.dart        # Base HTTP actions, multi-part file uploads, auth calls.
    │      camera_service.dart     # Snaps photos or records video clips.
    │      location_service.dart   # Requests GPS permissions and fetches coordinates.
    │      offline_queue.dart      # Local SQLite database manager for offline caching.
    │      sync_manager.dart       # Network connection listener automating background uploads.
    │
    └─utils/                       # Constant Settings
            constants.dart         # Base server URLs and time intervals.
```

---

## 8. Detailed System Workflows

### 8.1 Student: Submitting a Report
1.  **Preparation**: The student enters the incident details (Title and Description) on the `UploadScreen`.
2.  **Media Capture**: The student captures a photo or video using the `CameraService`.
3.  **Location Check**: The app checks if GPS is enabled and retrieves coordinates using `LocationService`.
4.  **Verification**: The student reviews and confirms the incident location on the `MapVerificationScreen`.
5.  **Submission**:
    *   **If Online**: The app uploads the media file to the server using `UploadMediaAPI` (receives a URL), and then submits the report details using `submit_report` view.
    *   **If Offline**: The app catches the connection error and saves the details (including local media file path and verified GPS coordinates) to the local SQLite database using `OfflineQueue`.
6.  **Background Sync**: Once the device reconnects to the internet, `SyncManager` automatically uploads the cached media and submits the report, removing it from the offline database.

### 8.2 Admin: Managing Reports
1.  **Dashboard Access**: The administrator logs in and is navigated to the `AdminMapScreen`.
2.  **Heatmap Overlay**: The app queries `HeatmapAPI` and plots red markers on Google Maps for active reports, and azure markers for landmark campus buildings.
3.  **Report Review**: The admin clicks on a marker to open details. They can view the incident title, description, student details, view photos, or launch video players.
4.  **Status Resolution**: The admin updates the report status (e.g. from `Pending` to `Resolved`) using the dropdown menu. This triggers a request to `update_report_status` view on the backend, which prints simulated push notifications.
5.  **Account Provisioning**: The admin can navigate to the `CreateStudentsScreen` to register individual student accounts or batch-generate users for a program (BS/MS).
