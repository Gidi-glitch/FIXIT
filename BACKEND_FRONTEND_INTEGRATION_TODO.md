# Backend to Frontend Integration TODO

Use this as your working checklist. Complete each phase in order so you avoid breaking too many screens at once.

## Phase 0 - Preflight

- [x] Confirm backend is running on port 8080.
- [ ] Confirm Flutter app can reach backend base URL on your device/emulator.
- [ ] Keep one Postman collection or curl notes for all endpoints you touch.
- [ ] Add a standard API error format if not already consistent (message, optional details).

## Phase 1 - Finish Profile APIs First (Safest Start)

### Backend

- [x] Add `PUT /api/profile/me` route.
- [x] Implement controller logic to update fields used by UI:
  - [x] first_name
  - [x] last_name
  - [x] phone
  - [x] email
  - [x] bio
  - [x] gender
  - [x] barangay
- [x] Add `POST /api/auth/change-password` route.
- [x] Implement current password validation + new password update.

### Frontend

- [x] Confirm homeowner edit profile uses `ApiService.updateProfile(...)` directly.
- [x] Confirm tradesperson edit profile save works end to end.
- [x] Wire homeowner privacy/security password change to real API call.
- [x] Retest profile photo upload on both roles.

### Validation

- [x] Login as homeowner and update profile.
- [x] Login as tradesperson and update profile.
- [x] Change password flow works for both roles.

## Phase 2 - Replace Homeowner Mock Data

### Backend Endpoints

- [x] Add `GET /api/tradespeople` (search, category, on-duty filter).
- [x] Add `POST /api/bookings` (create booking request).
- [x] Add `GET /api/bookings/homeowner` (list bookings).
- [x] Add `GET /api/bookings/{id}` (booking details).
- [x] Add `PATCH /api/bookings/{id}` (edit request fields).
- [x] Add `POST /api/bookings/{id}/cancel`.
- [x] Add `POST /api/bookings/{id}/review`.
- [x] Add `POST /api/bookings/{id}/issues`.

### Frontend Wiring

- [x] Replace tradesperson list sample data with API response.
- [x] Replace booking creation from local store to API call.
- [x] Replace bookings list local store reads with API fetch.
- [x] Replace booking details status/edit/review/issue actions with API.

### Validation

- [x] New booking appears after create without app restart.
- [x] Booking status updates are reflected in list and details.
- [x] Review submission persists and is visible after relogin.

## Phase 3 - Replace Tradesperson Mock Data

### Backend Endpoints

- [x] Add `PATCH /api/tradespeople/me/on-duty`.
- [x] Add `GET /api/requests/incoming`.
- [x] Add `POST /api/requests/{id}/accept`.
- [x] Add `POST /api/requests/{id}/decline`.
- [x] Add `GET /api/jobs/tradesperson`.
- [x] Add `GET /api/jobs/{id}`.
- [x] Add `POST /api/jobs/{id}/start`.
- [x] Add `POST /api/jobs/{id}/complete`.
- [x] Enforce rule: only one in-progress job at a time.

### Frontend Wiring

- [x] Replace `TradespersonWorkStore` requests feed with API.
- [x] Replace accept/decline actions with API calls.
- [x] Replace jobs screen and job details reads with API data.
- [x] Wire dashboard on-duty switch to API.

### Validation

- [x] Accepted request moves into jobs list correctly.
- [x] Start job blocks when another job is already in progress.
- [ ] Complete job updates status and dashboard cards.

## Phase 4 - Reviews, Documents, and Settings

### Backend Endpoints

- [x] Add `GET /api/reviews/tradesperson/me` (filter/sort support).
- [x] Add document replacement upload endpoint(s).
- [x] Add service area save endpoint.
- [x] Add trade/skills save endpoint.
- [ ] Optional: add homeowner addresses CRUD endpoints.

### Frontend Wiring

- [x] Replace tradesperson reviews mock list with API.
- [x] Replace tradesperson documents mock upload flow with API.
- [x] Move service area from SharedPreferences to backend.
- [x] Move trade/skills from SharedPreferences to backend.

## Phase 5 - Messaging (After Job/Booking Stability)

### Backend Endpoints

- [x] Add `GET /api/conversations`.
- [x] Add `GET /api/conversations/{id}/messages`.
- [x] Add `POST /api/conversations/{id}/messages`.
- [x] Add `POST /api/conversations/{id}/attachments`.

### Frontend Wiring

- [x] Replace local chat store reads with API.
- [x] Replace send message and attachment save with API.
- [x] Keep current UI and only swap data source first.

## Phase 6 - Hardening and Cleanup

- [ ] Add loading + retry states for every API-backed screen.
- [ ] Add token-expired handling (auto logout to login screen).
- [ ] Add integration tests for login, profile update, booking create, request accept, job start/complete.
- [ ] Remove or archive local mock stores after migration is complete.
- [ ] Update README with run steps and endpoint list.

## Suggested First 3 Tasks Today

- [x] Implement `PUT /api/profile/me` in backend.
- [x] Implement `POST /api/auth/change-password` in backend.
- [x] Wire homeowner privacy/security password change to `ApiService.changePassword(...)`.
