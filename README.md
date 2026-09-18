# Puean Chuay Tiu Mobile App

## About

Puean Chuay Tiu is a university Mini Project for discovering student tutors, viewing their available courses and schedules, and chatting with them. The project intentionally keeps a small academic-project scope.

## Existing Features

- Register and log in
- Search tutors and courses
- View tutor/course details and real schedule rows
- One-to-one chat with five-second polling
- View and update a profile
- Apply to become a tutor
- Create, edit, open/close, and delete owned tutor courses

## Prototype Features

Booking, reviews, notifications, forgot-password, credits/payment history, booking history, and contact-admin are not implemented. Their unavailable controls are hidden or clearly marked as Prototype; no mock review score is presented as real data.

## Tech Stack

- Flutter and Dart
- PHP REST-like API
- MySQL / MariaDB

## Screenshots

Add portfolio screenshots here:

- Login
- Home
- Search
- Tutor Detail
- Chat
- Tutor Management

## Project Structure

- `lib/auth`: registration and login
- `lib/search`: home, search, and tutor detail
- `lib/chat`: conversation list and chat room
- `lib/profile`: profile display and editing
- `lib/tutor`: tutor application and course management
- `lib/config.dart`: API URL, timeout, and authenticated request headers

## Setup

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://YOUR_LOCAL_IP/mini_backend
```

`API_BASE_URL` has one development fallback in `lib/config.dart`; override it for each environment with `--dart-define`. Use an HTTPS API URL for any public demo or production-like deployment. Android permits cleartext traffic only in the debug manifest for local development; the main/release manifest does not enable it globally.

## Backend Setup

Configure and run the sibling `mini_backend` PHP project, import its `database/schema.sql`, and make the API reachable from the emulator or device. Follow the backend README for `.env`, CORS, and authentication setup.

## Security Note

Never commit `.env` files, authentication secrets, passwords, logs, uploaded user images, or database exports containing real user data.
