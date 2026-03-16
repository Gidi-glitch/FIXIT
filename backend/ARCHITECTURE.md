# FIXIT Go Backend Structure

This backend design is scoped to the current Flutter frontend only:

- user login
- homeowner registration with ID upload
- tradesperson registration with government ID and license upload
- protected profile lookup after login

It does not yet include booking, on-duty status, reviews, or escrow.

## Recommended Folder Structure

```text
backend/
  main.go
  .env
  config/
    database.go
  controllers/
    auth_controller.go
    homeowner_controller.go
    tradesperson_controller.go
    profile_controller.go
  middleware/
    auth_middleware.go
    role_middleware.go
  models/
    user.go
    homeowner_profile.go
    tradesperson_profile.go
    verification_document.go
  routes/
    auth_routes.go
    homeowner_routes.go
    tradesperson_routes.go
    profile_routes.go
  services/
    auth_service.go
    upload_service.go
  utils/
    password.go
    response.go
    validator.go
  uploads/
    homeowners/
      ids/
    tradespeople/
      government_ids/
      licenses/
```

## Why This Structure Fits The Current Frontend

Your current Flutter screens collect these inputs:

### Login

- email
- password

### Homeowner registration

- first name
- last name
- email
- phone
- barangay
- password
- government ID type
- government ID file

### Tradesperson registration

- first name
- last name
- email
- phone
- password
- trade category
- years of experience
- service barangay
- bio
- government ID type
- government ID file
- license type
- professional license file

Because the frontend already uploads documents during registration, the backend should support `multipart/form-data` for registration endpoints that include files.

## Responsibility Of Each Folder

### config/

- database connection
- migration setup
- environment loading if you want to keep it separate from `main.go`

### controllers/

- parse HTTP requests
- call services
- return JSON responses
- keep file upload parsing close to request handling

### middleware/

- JWT authentication
- optional role checks such as homeowner-only or tradesperson-only routes

### models/

- GORM models only
- relationships between user, profiles, and uploaded documents

### routes/

- register route groups and map handlers

### services/

- password hashing
- login logic
- file naming and upload storage
- business rules shared across controllers

### utils/

- JSON response helpers
- request validation helpers
- reusable password and token helpers if you want to keep services thin

### uploads/

- actual uploaded ID, license, and certification files
- should not be served publicly as an open static directory

## Core Data Model

Use one `users` table for authentication and role, then attach role-specific profile tables.

### models/user.go

Suggested fields:

- `id`
- `email`
- `password_hash`
- `role` with values `homeowner` or `tradesperson`
- `is_active`
- `created_at`
- `updated_at`

### models/homeowner_profile.go

Suggested fields:

- `id`
- `user_id`
- `first_name`
- `last_name`
- `phone`
- `barangay`

### models/tradesperson_profile.go

Suggested fields:

- `id`
- `user_id`
- `first_name`
- `last_name`
- `phone`
- `trade_category`
- `years_experience`
- `service_barangay`
- `bio`
- `verification_status`

### models/verification_document.go

Suggested fields:

- `id`
- `user_id`
- `document_group` such as `government_id` or `license`
- `document_type`
- `original_name`
- `stored_name`
- `file_path`
- `mime_type`
- `file_size`
- `status`
- `uploaded_at`

## Suggested Route Design

### routes/auth_routes.go

```text
POST /api/auth/login
POST /api/auth/homeowners/register
POST /api/auth/tradespeople/register
```

### routes/profile_routes.go

```text
GET /api/profile/me
```

### routes/homeowner_routes.go

Keep this small for now. You do not need separate homeowner routes yet unless the app starts showing homeowner-only profile screens.

### routes/tradesperson_routes.go

For the current frontend, this can stay minimal too. Registration lives in auth because it creates both user and profile.

## Controller Design For Current Frontend

### controllers/auth_controller.go

Contains:

- `Login`
- shared login response with JWT

### controllers/homeowner_controller.go

Contains:

- `RegisterHomeowner`
- accepts `multipart/form-data`
- creates user with role `homeowner`
- creates homeowner profile
- stores uploaded government ID metadata

### controllers/tradesperson_controller.go

Contains:

- `RegisterTradesperson`
- accepts `multipart/form-data`
- creates user with role `tradesperson`
- creates tradesperson profile
- stores government ID metadata
- stores license metadata

### controllers/profile_controller.go

Contains:

- `GetMyProfile`
- returns base user info plus homeowner or tradesperson profile data based on role

## Upload Handling Design

The current frontend requires document upload during registration, so keep uploads organized by role and document purpose.

Recommended stored layout:

```text
uploads/
  homeowners/
    ids/
  tradespeople/
    government_ids/
    licenses/
```

Rules:

- generate unique stored filenames
- validate allowed extensions and mime types
- enforce file size limits
- save file metadata in the database
- never trust the client filename
- do not expose the folder directly to the public internet

## Minimal Build Order

Build in this order so it matches your current frontend screens:

1. `models/user.go`
2. `models/homeowner_profile.go`
3. `models/tradesperson_profile.go`
4. `models/verification_document.go`
5. `config/database.go`
6. `services/upload_service.go`
7. `controllers/homeowner_controller.go`
8. `controllers/tradesperson_controller.go`
9. `controllers/auth_controller.go`
10. `middleware/auth_middleware.go`
11. `controllers/profile_controller.go`
12. `routes/*.go`

## Important Correction To The Current Backend

The current backend mixes `User`, `Homeowner`, and `TradespersonProfile` inconsistently. Choose one base auth model and keep the rest as profile models.

For your current frontend, the cleanest choice is:

- one `User` model for login credentials and role
- one `HomeownerProfile` model
- one `TradespersonProfile` model
- one `VerificationDocument` model

That structure will match your Flutter screens better and avoid duplicated login logic.
