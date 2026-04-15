# Backend to Frontend Integration TODO

Use this as your working checklist. Complete each phase in order so you avoid breaking too many screens at once.

## Phase 0 - Preflight

- [ ] Confirm backend is running on port 8080.
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
- [ ] Confirm tradesperson edit profile save works end to end.
- [x] Wire homeowner privacy/security password change to real API call.
- [ ] Retest profile photo upload on both roles.

### Validation

- [ ] Login as homeowner and update profile.
- [ ] Login as tradesperson and update profile.
- [ ] Change password flow works for both roles.

## Phase 2 - Replace Homeowner Mock Data

### Backend Endpoints

- [ ] Add `GET /api/tradespeople` (search, category, on-duty filter).
- [ ] Add `POST /api/bookings` (create booking request).
- [ ] Add `GET /api/bookings/homeowner` (list bookings).
- [ ] Add `GET /api/bookings/{id}` (booking details).
- [ ] Add `PATCH /api/bookings/{id}` (edit request fields).
- [ ] Add `POST /api/bookings/{id}/cancel`.
- [ ] Add `POST /api/bookings/{id}/review`.
- [ ] Add `POST /api/bookings/{id}/issues`.

### Frontend Wiring

- [ ] Replace tradesperson list sample data with API response.
- [ ] Replace booking creation from local store to API call.
- [ ] Replace bookings list local store reads with API fetch.
- [ ] Replace booking details status/edit/review/issue actions with API.

### Validation

- [ ] New booking appears after create without app restart.
- [ ] Booking status updates are reflected in list and details.
- [ ] Review submission persists and is visible after relogin.

## Phase 3 - Replace Tradesperson Mock Data

### Backend Endpoints

- [ ] Add `PATCH /api/tradespeople/me/on-duty`.
- [ ] Add `GET /api/requests/incoming`.
- [ ] Add `POST /api/requests/{id}/accept`.
- [ ] Add `POST /api/requests/{id}/decline`.
- [ ] Add `GET /api/jobs/tradesperson`.
- [ ] Add `GET /api/jobs/{id}`.
- [ ] Add `POST /api/jobs/{id}/start`.
- [ ] Add `POST /api/jobs/{id}/complete`.
- [ ] Enforce rule: only one in-progress job at a time.

### Frontend Wiring

- [ ] Replace `TradespersonWorkStore` requests feed with API.
- [ ] Replace accept/decline actions with API calls.
- [ ] Replace jobs screen and job details reads with API data.
- [ ] Wire dashboard on-duty switch to API.

### Validation

- [ ] Accepted request moves into jobs list correctly.
- [ ] Start job blocks when another job is already in progress.
- [ ] Complete job updates status and dashboard cards.

## Phase 4 - Reviews, Documents, and Settings

### Backend Endpoints

- [ ] Add `GET /api/reviews/tradesperson/me` (filter/sort support).
- [ ] Add document replacement upload endpoint(s).
- [ ] Add service area save endpoint.
- [ ] Add trade/skills save endpoint.
- [ ] Optional: add homeowner addresses CRUD endpoints.

### Frontend Wiring

- [ ] Replace tradesperson reviews mock list with API.
- [ ] Replace tradesperson documents mock upload flow with API.
- [ ] Move service area from SharedPreferences to backend.
- [ ] Move trade/skills from SharedPreferences to backend.

## Phase 5 - Messaging (After Job/Booking Stability)

### Backend Endpoints

- [ ] Add `GET /api/conversations`.
- [ ] Add `GET /api/conversations/{id}/messages`.
- [ ] Add `POST /api/conversations/{id}/messages`.
- [ ] Add `POST /api/conversations/{id}/attachments`.

### Frontend Wiring

- [ ] Replace local chat store reads with API.
- [ ] Replace send message and attachment save with API.
- [ ] Keep current UI and only swap data source first.

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
