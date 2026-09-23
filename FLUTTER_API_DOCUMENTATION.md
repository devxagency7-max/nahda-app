# Nahda Case Management API — Flutter (Mobile) Integration Guide

This document is the authoritative contract between the Nahda .NET backend and the **mobile (Flutter)** frontend. It is generated directly from the current source code (minimal-API endpoint definitions, request/response records, FluentValidation validators, authorization policies, the Cases workflow state machine, and the shared error/response contracts). Nothing here is invented — a capability not documented here does not exist in the backend today. This document does **not** prescribe a local database/offline architecture for the app; it documents only what the **backend contract** allows the app to safely rely on for retry, conflict, and sync behavior (§14).

Backend stack: ASP.NET Core minimal APIs, MediatR (CQRS), FluentValidation, EF Core / PostgreSQL. Endpoints live in `src/Nahda.Api/Endpoints/*.cs`.

---

## 1. Base URL & Versioning

```
/api/v1
```
Single active version. No Swagger in Production.

## 2. Authentication

### 2.1 Header contracts

- Login/Refresh/Logout require:
  ```
  X-Client-Type: mobile
  ```
- Every protected endpoint requires:
  ```
  Authorization: Bearer <accessToken>
  ```

### 2.2 Platform lock — mobile is `social_worker`'s ONLY way in

The backend enforces this server-side (`LoginCommandHandler.ValidatePlatform`), not just as a UI convention:

| Role | Allowed client type |
|---|---|
| `social_worker` | **mobile only** ✅ |
| `manager`, `reviewer`, `data_entry` | web only — attempting mobile login returns `403 PLATFORM_NOT_ALLOWED` |

**In practice: the Flutter app is built for the `social_worker` role.** Every other role is rejected at login. Do not build multi-role screens expecting a manager/reviewer to authenticate through this app; if the product ever needs that, it requires a backend change to the platform lock, not a client-side bypass (there is none — the check is server-side and cannot be spoofed by changing `X-Client-Type`, since the role itself is what's validated against the header, not the reverse).

### 2.3 Endpoints

#### `POST /api/v1/auth/login`
- Auth: none. Rate limit: `auth` (5/60s per IP).
- Headers: `X-Client-Type: mobile`
- Body: `{ "email": "worker@nahda.org", "password": "..." }`
- Success `200`:
  ```json
  {
    "success": true,
    "data": {
      "accessToken": "eyJhbGciOi...",
      "refreshToken": "8f3a1c...",
      "expiresIn": 900,
      "user": {
        "id": "5b1e...",
        "fullName": "منى حسن",
        "email": "worker@nahda.org",
        "role": "social_worker",
        "permissions": ["view_cases", "edit_case", "write_worker_opinion", "accept_reject_assignment"]
      }
    }
  }
  ```
- Errors: `401 INVALID_CREDENTIALS` (generic — never distinguishes unknown email / wrong password / disabled account), `423 ACCOUNT_LOCKED` (5 failed attempts → 15-minute lock), `403 PLATFORM_NOT_ALLOWED` (a non-social_worker account trying to use the app), `429 RATE_LIMITED`.

#### `POST /api/v1/auth/refresh`
- Body: `{ "refreshToken": "..." }` → `{ "accessToken": "...", "refreshToken": "...", "expiresIn": 900 }` — **rotates** the refresh token every call.
- **Reuse detection**: replaying an already-rotated token revokes the entire token family (forces re-login). This matters a lot on mobile where a crash/restart mid-refresh is common — never persist "the refresh token I'm about to send" separately from "the refresh token I already used"; only ever hold the single latest one, and if a refresh attempt's result is genuinely unknown (app killed mid-request), the safest recovery is to fall back to login rather than guessing and risking a reuse-triggered logout.
- **Concurrent refresh**: exactly one of two simultaneous refresh calls with the same token wins; the other's whole family is revoked. Serialize refresh through a single in-flight future/mutex in the app's HTTP layer.
- Errors: `401 TOKEN_INVALID` / `401 TOKEN_REVOKED` / `401 TOKEN_EXPIRED`.

#### `POST /api/v1/auth/logout`
- Body: `{ "refreshToken": "..." }`. Revokes only this one device's session. Always `200` (idempotent).

#### `GET /api/v1/auth/me`
- Re-reads the user from the database (not the JWT) every call — reflects a deactivation within one call, not just at next token expiry.

### 2.4 Token lifetimes

| Token | Lifetime |
|---|---|
| Access token (JWT, RS256) | **15 minutes** |
| Refresh token (opaque) | **7 days** |

Clock skew tolerance: 30 seconds. On a device with a badly-drifted clock, expect early `401`s.

### 2.5 401 handling contract

Any `401` → attempt exactly one `/auth/refresh`; on failure, clear stored tokens and force re-login. A `403` is never solved by refreshing.

---

## 3. Response Envelope

Success:
```json
{ "success": true, "data": { /* endpoint-specific, or null */ }, "message": null }
```
Error:
```json
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "بيانات غير صحيحة", "details": { "field": ["reason"] } } }
```
- camelCase JSON everywhere; Arabic text is sent as raw UTF-8 (not `\u` escapes).
- `error.details` is **absent**, not `null`, when there is nothing field-specific.
- Unmatched routes and rate-limit rejections return this same envelope shape (`404 NOT_FOUND`, `429 RATE_LIMITED` respectively) — a mobile HTTP client that special-cases "non-JSON 404 page" will break; always parse the envelope.

## 4. Pagination

```json
{ "items": [...], "page": 1, "limit": 20, "total": 137, "totalPages": 7, "hasNext": true, "hasPrev": false }
```
`page` 1-based (default 1), `limit` default 20, server-clamped max 100.

## 5. Concurrency — `rowVersion`

No ETag/If-Match anywhere. A plain integer `rowVersion` (or `caseRowVersion` on case-section/workflow calls, since those guard the parent Case row) travels with every read and must be echoed on every write to that resource. Stale value → `409 CONCURRENCY_CONFLICT`. **This is the mechanism the offline queue must respect — see §14.**

## 6. Idempotency-Key (workflow transitions)

Nine routes require an `Idempotency-Key: <uuid>` header — all under `CaseWorkflowEndpoints`: `assign`, `accept`, `reject-assignment`, `opinions/worker`, `opinions/reviewer`, `return-to-worker`, `opinions/manager`, `return-for-completion`.

- Missing/malformed → `400 IDEMPOTENCY_KEY_REQUIRED`.
- The **first** call's exact response (status + body) is cached server-side for **24 hours**, keyed by `(key, userId)`. A replay with the same key by the same user returns the cached response verbatim, without re-executing the side effect. This is precisely the mechanism a mobile app should lean on for safe retries after a dropped connection — see §14.2.

## 7. Roles & Permissions

Since only `social_worker` can log into this app, only that row matters operationally, but the full matrix is included for completeness (a future admin-in-app screen, or shared code with the web client).

### 7.1 `social_worker`'s grants (`RolePermissionMatrix`)
`view_cases`, `edit_case` (own assigned cases only), `view_opinions`, `write_worker_opinion`, `accept_reject_assignment`.

Notably **absent**: `create_case` (a worker cannot create a new case from the app), `manage_*`, `write_reviewer_opinion`, `write_manager_approval`.

### 7.2 Full matrix (for reference / shared model code)

| Permission | manager | reviewer | data_entry | social_worker |
|---|:---:|:---:|:---:|:---:|
| `create_case` | ✅ | ✅ | ✅ | ❌ |
| `view_cases` | ✅ | ✅ | ✅ | ✅ |
| `edit_case` | ✅ | ❌ | ✅ | ✅ (assigned only) |
| `manage_charities` | ✅ | ✅ | ✅ | ❌ |
| `manage_locations` | ✅ | ✅ | ✅ | ❌ |
| `view_opinions` | ✅ | ✅ | ✅ | ✅ |
| `write_reviewer_opinion` | ❌ | ✅ | ❌ | ❌ |
| `write_manager_approval` | ✅ | ❌ | ❌ | ❌ |
| `view_employees` | ✅ | ❌ | ❌ | ❌ |
| `manage_employees` | ✅ | ❌ | ❌ | ❌ |
| `write_worker_opinion` | ❌ | ❌ | ❌ | ✅ |
| `accept_reject_assignment` | ❌ | ❌ | ❌ | ✅ |
| `manage_configurations` | ✅ | ❌ | ❌ | ❌ |

### 7.3 Enforcement

Every permission is its own ASP.NET policy, resolved from the server-verified `role` JWT claim only. `401` = bad/missing token; `403 FORBIDDEN` = authenticated but not permitted. **A jailbroken/tampered client cannot escalate role or permission** — the token is RS256-signed and the role claim is what the server trusts, never a client-local value.

## 8. Error Code Catalogue

| Code | HTTP | Meaning |
|---|---|---|
| `UNAUTHORIZED` | 401 | Missing/invalid credentials |
| `FORBIDDEN` | 403 | Authenticated, not permitted |
| `VALIDATION_ERROR` | 422 | FluentValidation failure (422, not 400, system-wide) |
| `NOT_FOUND` | 404 | Generic not-found / unmatched route |
| `RATE_LIMITED` | 429 | Rate limiter rejection |
| `INTERNAL_ERROR` | 500 | Unhandled exception, no detail leaked |
| `INVALID_CREDENTIALS` | 401 | Login failure (generic) |
| `ACCOUNT_LOCKED` | 423 | 5 failed logins → 15-min lock |
| `PLATFORM_NOT_ALLOWED` | 403 | Non-social_worker account on mobile |
| `SOCIAL_WORKER_WEB_BLOCKED` | 403 | (n/a for mobile login; also reused for a worker-opinion submitted from a **non-mobile** client type claim) |
| `TOKEN_EXPIRED` / `TOKEN_REVOKED` / `TOKEN_INVALID` | 401 | Refresh token lifecycle failures |
| `DUPLICATE_RESOURCE` | 409 | Unique constraint violation |
| `DELETE_CONFLICT` | 409 | Delete blocked by dependent data |
| `CASE_NOT_FOUND` | 404 | Case missing or invisible to caller |
| `DUPLICATE_NATIONAL_ID` | 409 | Duplicate beneficiary national ID |
| `CONCURRENCY_CONFLICT` | 409 | Stale `rowVersion`/`caseRowVersion` |
| `INVALID_STATUS_TRANSITION` | 422 | Workflow action invalid from current status |
| `OPINION_SLOT_LOCKED` | 422 | Re-writing an already-finalized opinion |
| `MISSING_WORKER_OPINION` | 422 | Reviewer/manager acted before worker opinion exists |
| `CASE_ALREADY_APPROVED` | 422 | Action on a terminal Approved case |
| `IDEMPOTENCY_KEY_REQUIRED` | 400 | Missing/malformed header on a workflow route |
| `FILE_TOO_LARGE` | 422 | Attachment over 10MB |
| `UNSUPPORTED_FILE_TYPE` | 422 | MIME/magic-byte mismatch against the allow-list |
| `STORAGE_UNAVAILABLE` | 503 | Object store outage — only attachments are affected |

## 9. Enums & Wire Values

All lowercase snake_case strings, no integers.

**Case status**: `draft`, `pending_assignment`, `assigned`, `accepted`, `in_research`, `pending_review`, `returned_to_worker`, `pending_approval`, `approved`, `rejected`

**Workflow action** (`availableActions`): `assign`, `accept_assignment`, `reject_assignment`, `submit_worker_opinion`, `save_reviewer_draft`, `submit_reviewer_opinion`, `return_to_worker`, `approve`, `reject`, `return_for_completion`

**Opinion decision**: `accepted`, `rejected`

**Case priority**: `low`, `medium`, `high`, `urgent`

**Client type**: `web`, `mobile`

**Holding answer** (agriculture): `unanswered`, `yes`, `no`

**Land type** (literal Arabic on the wire): `تمليك`, `إيجار`

**Attachment status**: `pending` → `complete` (→ `orphaned` after 48h if never committed)

**Device push platform**: `android`, `ios`

**Audit `entityType`**: `case`, `user`, `attachment`, `refresh_token`

## 10. Complete Endpoint Index (mobile-relevant + full reference)

All prefixed `/api/v1`. Routes marked **(social_worker reachable)** are the ones a `write_worker_opinion`/`accept_reject_assignment`/`edit_case`/`view_cases` grant actually unlocks for this app's user; the rest are documented for completeness / shared model code but return `403` for this role.

| Method | Route | Perm | Idempotency-Key | Social worker? |
|---|---|---|---|:---:|
| POST | `/auth/login`, `/auth/refresh`, `/auth/logout` | none | — | ✅ |
| GET | `/auth/me` | Auth only | — | ✅ |
| GET | `/locations` | Auth only | — | ✅ (dropdowns) |
| GET | `/charities` | Auth only | — | ✅ (dropdowns) |
| GET | `/employees/social-workers` | `create_case` | — | ❌ |
| PUT | `/profile` | Auth only | — | ✅ |
| GET | `/cases` | `view_cases` | — | ✅ |
| POST | `/cases` | `create_case` | — | ❌ |
| GET | `/cases/{id}` | `view_cases` | — | ✅ |
| GET | `/cases/{id}/completion` | `view_cases` | — | ✅ |
| GET | `/cases/{id}/family-members` | `view_cases` | — | ✅ |
| POST/DELETE | `/cases/{id}/bookmark` | `view_cases` | — | ✅ |
| PUT | `/cases/{id}/beneficiary` etc. (9 section routes) | `edit_case` | — | ✅ (assigned cases only) |
| GET | `/cases/{id}/support` | `view_cases` | — | ✅ |
| PUT | `/cases/{id}/support-recommendations` | `edit_case` | — | ✅ (assigned) |
| PUT | `/cases/{id}/approved-support` | `write_manager_approval` | — | ❌ |
| POST | `/cases/{id}/assign` | `create_case` | ✅ | ❌ |
| POST | `/cases/{id}/accept` | `accept_reject_assignment` | ✅ | ✅ |
| POST | `/cases/{id}/reject-assignment` | `accept_reject_assignment` | ✅ | ✅ |
| POST | `/cases/{id}/opinions/worker` | `write_worker_opinion` | ✅ | ✅ **(mobile-only enforced)** |
| POST | `/cases/{id}/opinions/reviewer` | `write_reviewer_opinion` | ✅ | ❌ |
| POST | `/cases/{id}/return-to-worker` | `write_reviewer_opinion` | ✅ | ❌ |
| POST | `/cases/{id}/opinions/manager` | `write_manager_approval` | ✅ | ❌ |
| POST | `/cases/{id}/return-for-completion` | `write_manager_approval` | ✅ | ❌ |
| POST | `/cases/{id}/field-visits` | `write_worker_opinion` | — | ✅ **(mobile-only enforced)** |
| PUT | `/field-visits/{id}` | `write_worker_opinion` | — | ✅ |
| PUT | `/cases/{id}/field-verification` | `write_worker_opinion` | — | ✅ **(mobile-only enforced)** |
| POST | `/attachments/init` | `edit_case` (+Moderate limit) | — | ✅ |
| POST | `/attachments/{id}/commit` | `edit_case` | — | ✅ |
| GET | `/attachments/{id}/download` | `view_cases` | — | ✅ |
| DELETE | `/attachments/{id}` | `edit_case` | — | ✅ |
| GET | `/cases/{id}/attachments` | `view_cases` | — | ✅ |
| GET | `/search/cases` | `view_cases` (+Moderate) | — | ✅ |
| GET | `/dashboard/stats`, `/dashboard/work-queue` | `view_cases` (+Moderate) | — | ✅ |
| GET | `/notifications` | Auth only | — | ✅ |
| PUT | `/notifications/mark-all-read`, `/{id}/read` | Auth only | — | ✅ |
| POST | `/notifications/device-tokens` | Auth only | — | ✅ **(this app's key route — §12)** |
| GET | `/audit-logs` | `view_cases` | — | ✅ |
| `/dropdown-configs*`, `/dropdown-options*` (admin) | `manage_configurations` | — | ❌ |
| GET | `/dropdowns/{key}` | Auth only | — | ✅ (form dropdowns) |
| Employees admin, Locations/Charities writes, exports | various `manage_*` | — | ❌ |

**Excluded (not app-consumable):** `GET /system/version`, `GET /system/authz-probe/{permission}` (13 internal RBAC-proof routes), `/health/live`, `/health/ready`.

---

## 11. Field Visits & Field Verification — the app's core screens

### `POST /cases/{caseId}/field-visits` (FV1)
- Enforced, in order: case is visible → **caller is on `mobile`** (a non-mobile client type claim on this call is technically unreachable from this app but is checked defense-in-depth) → caller is the case's current assignee → case status is `in_research` or `returned_to_worker` (the "field research window").
- Body: `visitDate` (date), `startTimeUtc?`, `endTimeUtc?`, `latitude?`, `longitude?` (must both be present together, within valid ranges, or neither), `locationDescription?`, `outcome` (required), `status?`, `notes?`, `description?`, `photoAttachmentIds?: []` (must reference already-**committed** attachments belonging to the same case — upload and commit photos via §13 first, then attach their ids here).
- `caseId` and the worker's own id are never in the body — they come from the route and the JWT; sending them is a no-op.

### `PUT /field-visits/{id}` (FV2)
- Update a visit **you** created; requires `rowVersion`; the case/worker on a visit can never be reassigned through this route. A visit that doesn't exist or belongs to another worker returns `404` (no distinction).

### `PUT /cases/{caseId}/field-verification` (FV3)
- Full replace of the field-verification set. Send only `fieldLabel`, `verifiedValue`, `differenceReason` per entry — the server computes `originalValue`/`isDifferent` from the case's real stored data; you cannot spoof either. `differenceReason` is required only where the computed comparison finds an actual difference. Guarded by `caseRowVersion`.
- Neither of the two "record" routes (FV1/FV3 uses `caseRowVersion`; FV1 itself has none) requires an `Idempotency-Key` — a duplicate `POST /field-visits` from a flaky connection is **not** deduplicated server-side; the app's own retry logic must avoid double-submitting (see §14.2).

## 12. Push Notifications (FCM) — mobile-specific

### `POST /notifications/device-tokens` (N4)
Body:
```json
{ "token": "<fcm-registration-token-from-firebase-sdk>", "platform": "android" }
```
- `platform` must be `android` or `ios`. Empty/invalid → `422 VALIDATION_ERROR`.
- Owner is always the authenticated caller (from the JWT) — there is no `userId` field; the app cannot register a token on behalf of another user.
- Re-registering the same token updates the existing row (no duplicates). One user can hold multiple device tokens (multi-device support is native to the schema).
- **Lifecycle**: if FCM permanently rejects a token (app uninstalled, token rotated on the OS side), the backend disables it on the **first** failed send attempt — it does not retry indefinitely. **Re-register the token on every app foreground/resume** (standard FCM guidance: tokens can rotate silently), not just once at install time.
- Push delivery configuration lives server-side under `PushNotifications` (`appsettings.json`: `Enabled`, `ProjectId`, `ServiceAccountJson`, `MaxAttempts: 3`, retry backoff) — this is Firebase Cloud Messaging specifically; there is no APNs-direct or other push provider in this codebase.
- **Call this endpoint after every successful login**, and again whenever the OS delivers a token-refresh callback to the app. There is no dedicated "unregister" endpoint — logging out does not deregister the device token; the backend degrades gracefully to a failed-send-and-disable on the next push attempt if the app is gone.
- Web push is explicitly out of scope of this backend (per the endpoint's own documentation) — this route exists for mobile only.

## 13. Attachments — Upload Flow (presigned URL; the app never proxies bytes through the API, and neither does the API)

Same three-step flow used by web, relevant here because it's how the app attaches field-visit photos and case documents.

### Step 1 — `POST /attachments/init`
```json
{
  "caseId": "c9a1...",
  "documentType": "field_visit_photo",
  "fileName": "IMG_2031.jpg",
  "mimeType": "image/jpeg",
  "fileSize": 2114532,
  "description": null
}
```
- Allow-list (checked by MIME, not filename): `image/jpeg` (jpg/jpeg), `image/png`, `image/heic` (iPhone camera roll — multiple ISO-BMFF brand variants accepted), `image/webp`, `application/pdf`, `application/msword`, `.docx`.
- **Max 10MB per file** — checked before any upload URL is issued.
- Rate-limited (`Moderate` policy, per-user) — a bulk-photo field visit should batch reasonably, not fire dozens of `/init` calls in a burst.

Response: `attachmentId`, `uploadUrl`, `httpMethod: "PUT"`, `objectKey`, `mimeType`, `maxFileSizeBytes`, `uploadUrlExpiresAtUtc`, `status: "pending"`.

### Step 2 — client `PUT`s the file bytes directly to `uploadUrl`
Set `Content-Type` to exactly the returned `mimeType`. This goes straight to object storage (S3-compatible; provider-agnostic in code, configured via `Storage:ServiceUrl`), not through the Nahda API.

### Step 3 — `POST /attachments/{id}/commit`
```json
{ "checksum": "<hex-md5-of-uploaded-bytes>" }
```
- The server re-reads the object's real bytes and verifies **magic bytes**, independent of the declared Content-Type — a mis-declared/corrupted upload is rejected here even if `/init` accepted the metadata.
- **This route is safely retryable without an `Idempotency-Key`**: calling `/commit` again on an already-complete attachment returns `200` with `alreadyComplete: true` and does nothing further. This is the one write in the whole system that is idempotent by resource id alone — lean on it if a commit call's result is ambiguous after a dropped connection (§14.2).
- `checksum` is optional; if you can't compute an MD5 client-side cheaply, omit it — the server still verifies existence, size, and real content type without it.
- **Orphan cleanup**: an attachment that reaches `/init` but is never committed is purged after 48 hours — if the app captured a photo offline and hasn't uploaded it yet, don't call `/init` until you're ready to immediately follow through with the PUT and `/commit` in the same online session (see §14.4).

### Other routes
- `GET /attachments/{id}/download` — fresh presigned URL, 15-minute validity, every call. Never cache/reuse across sessions.
- `GET /cases/{id}/attachments?page=&limit=` — metadata only, no download links; not embedded in case details.

---

## 14. Offline Integration — what the backend contract actually allows

**This backend has no bespoke offline/sync API** (no batch-upload endpoint, no delta/changes-since feed, no server-side conflict-resolution engine). Everything below describes what the *existing* endpoints' behavior lets a client-side offline queue safely do — it is not a description of any client-side database schema (that is an app-architecture decision outside this backend's contract).

### 14.1 What is safe to queue and retry blindly

- **`POST /attachments/{id}/commit`** — idempotent by attachment id (§13). Safe to retry on ambiguous network failure without any extra bookkeeping.
- **The nine `Idempotency-Key`-bearing workflow routes** (§6) — safe to retry **as long as the same `Idempotency-Key` is reused for retries of the same logical action**. Generate the key once when the user taps the action (e.g., "submit worker opinion"), persist it alongside the queued action, and reuse it on every retry attempt until it succeeds. Never generate a new key per retry — that would defeat the mechanism and risk double-execution (e.g., resubmitting an opinion after a status has already moved on).
- **`PUT /notifications/mark-all-read`** — idempotent (0 marked is a valid success), safe to retry.
- **`PUT /notifications/{id}/read`** — idempotent, safe to retry.

### 14.2 What is NOT idempotent — needs app-side dedup before it ever reaches the wire

- **`POST /cases/{caseId}/field-visits`** — no `Idempotency-Key` support. If the app queues a field-visit creation offline, it must guarantee **exactly-once submission** itself (e.g., a durable client-side dedup id checked before enqueueing the HTTP call, not after), because a retried `POST` here creates a second visit row server-side. This is a real gap in the backend contract for this specific endpoint — treat it with more caution than the workflow actions.
- **`POST /attachments/init`** — not idempotent (each call mints a new `attachmentId` + presigned URL + object key). If a queued "upload this photo" job retries `/init` after a partial failure, it will leak an orphaned pending attachment (auto-cleaned after 48h, but still wasted quota/bandwidth on the eventual retry). Prefer: call `/init` once, and if the subsequent `PUT`/`commit` fails, retry **those** steps against the *same* `attachmentId`/`uploadUrl` rather than re-calling `/init` — note the presigned `uploadUrl` itself has its own expiry (`uploadUrlExpiresAtUtc`), so a long offline gap between `/init` and the actual upload may require a fresh `/init` call anyway, accepting the orphan risk.
- **All section `PUT` endpoints** (beneficiary, family-members, housing, etc.) — these are replace/upsert semantics guarded by `rowVersion`/`caseRowVersion`, so a *retry of the exact same request* is harmless (same `rowVersion` in, same data in → same result), but **two different queued edits to the same section made while offline will not both apply** — the second one to reach the server will see a stale `rowVersion` from the first and get `409 CONCURRENCY_CONFLICT`. See §14.3.

### 14.3 Conflict handling contract (what `409 CONCURRENCY_CONFLICT` means for a sync queue)

- The backend's optimistic-concurrency model has **no server-side merge**. When a queued write's `rowVersion` no longer matches, the server rejects it outright with `409` — it never partially applies, never auto-merges field-by-field, and never silently overwrites.
- For an offline queue, this means: **do not blindly replay a queue of stale writes** against a section after reconnecting. On `409`, the correct recovery is: `GET` the current server state for that case/section, discard or rebase the queued write against the fresh `rowVersion`, and — if the same field was changed both offline and server-side in the meantime — surface a conflict to the user rather than guessing which value wins. There is no `PATCH`-style partial-merge alternative for these endpoints (they are full-section replace or single-entity full update).
- Field-visit and workflow actions are naturally more forgiving of this because assignment/ownership checks (§9's role gates in the WEB doc's terms, or simply "you can only act on your own assigned case") limit how much genuine concurrent editing of the *same* case by the *same* worker's own queue can actually happen — the realistic conflict scenario for this app is the worker's own two devices, or a stale queue replayed after the case was reassigned/returned by someone else while the device was offline.

### 14.4 Ordering & staleness

- **`GET`s are not versioned beyond `rowVersion`/`caseRowVersion`** — there is no "changes since timestamp X" feed. A sync strategy must re-`GET` the resources it cares about after reconnecting rather than assuming a queued mutation captures the full current truth.
- **Assignment/status can change server-side while the device is offline** (e.g., a manager reassigns the case, or a reviewer returns it). A queued action built against an assumption of the case's prior status can legitimately fail with `422 INVALID_STATUS_TRANSITION` or `403` (ownership) on replay — this is not a bug to work around, it is the backend correctly refusing an action that is no longer valid. Surface it to the user rather than retrying it further.
- **Access/refresh tokens do not survive indefinitely offline**: the access token expires in 15 minutes and the refresh token in 7 days. A queue that accumulates actions over a multi-day offline period must be prepared for the stored refresh token to have expired by the time connectivity returns, requiring a full re-login before the queue can flush — plan queue-flush logic to check/refresh auth *before* attempting to drain the queue, not per-item.
- **Attachments have their own clock**: the 15-minute presigned download URL and the 48-hour orphan-expiry window on uncommitted uploads are both real deadlines the offline queue must respect — an upload queued for more than 48 hours before it gets a chance to run should re-`init` rather than trusting a stale `attachmentId` is still valid.

### 14.5 Summary table

| Endpoint category | Safe to blind-retry? | Notes |
|---|---|---|
| 9 workflow transitions | ✅ with a stable, reused `Idempotency-Key` | Never mint a new key per retry of the same action |
| `attachments/{id}/commit` | ✅ | Idempotent by attachment id |
| `notifications/mark-all-read`, `{id}/read` | ✅ | Naturally idempotent |
| `attachments/init` | ⚠️ | Not idempotent — retry the *upload*, not `/init`, where possible |
| `field-visits` (POST) | ❌ | No dedup mechanism — app must prevent duplicate enqueue/send itself |
| Section `PUT`s (beneficiary/housing/etc.) | ⚠️ | Safe to retry the *same* request; unsafe to queue multiple divergent edits without re-checking `rowVersion` |
| `POST /cases` (create) | ❌ | Duplicate submission creates a second case unless the national ID is already taken (which then correctly surfaces `409 DUPLICATE_NATIONAL_ID` — use that as your practical dedup signal if a create is ever retried) |

---

## 15. Frontend Must NOT

1. **Do not build a login screen for any role other than `social_worker`** in this app — every other role is rejected by the server's platform lock regardless of what `X-Client-Type` claims.
2. **Do not attempt to bypass the platform lock** by changing headers — the check is server-side against the account's actual role, not the client's self-reported type.
3. **Do not generate a new `Idempotency-Key` on every retry** of the same user action — reuse the one generated when the user first triggered it.
4. **Do not retry `POST /field-visits` blindly** — it has no server-side dedup; guarantee exactly-once send yourself.
5. **Do not call `/attachments/init` repeatedly as a retry strategy** — retry the upload/commit steps against the original `attachmentId` instead.
6. **Do not cache or reuse a presigned download URL** beyond its 15-minute window.
7. **Do not assume `availableActions` in `GET /cases/{id}` is authorization** — every action endpoint re-validates role, status, and (for worker actions) assignment ownership independently, and can reject even if the hint said otherwise (e.g., after a manager reassigned the case while the device was offline).
8. **Do not skip re-registering the FCM device token** on app resume/token-refresh — the backend does not proactively re-fetch it.
9. **Do not treat `403` as a token problem** — never refresh in response to `403`; it means the action itself is not permitted (e.g., editing a case no longer assigned to this worker).
10. **Do not submit `latitude` without `longitude` or vice versa** on a field visit — both or neither.
11. **Do not assume a queued action from more than 7 days ago can flush without a fresh login** — the refresh token will have expired.

## 16. End-to-End Mobile Flow Recipes (including offline/sync/conflict)

### 16.1 Login → work queue
1. `POST /auth/login` with `X-Client-Type: mobile`.
2. `POST /notifications/device-tokens` with the current FCM token.
3. `GET /dashboard/work-queue?page=1` (auto-filtered to this worker's `assigned`/`in_research`/`returned_to_worker` cases).

### 16.2 Accept an assignment and start research
1. `GET /cases/{id}` → confirm `workflow.availableActions` includes `accept_assignment`.
2. `POST /cases/{id}/accept` with a fresh `Idempotency-Key` and the case's current `rowVersion` → case moves to `in_research`.

### 16.3 Field visit with photos (online)
1. Capture photos; for each: `POST /attachments/init` → `PUT` bytes to `uploadUrl` → `POST /attachments/{id}/commit`.
2. `POST /cases/{id}/field-visits` with `photoAttachmentIds: [...]` from step 1.
3. Fill in case sections as needed (`PUT /cases/{id}/housing`, etc.), echoing `rowVersion` each time.
4. `PUT /cases/{id}/field-verification` to reconcile stated vs. observed facts.
5. `POST /cases/{id}/opinions/worker` (`decision: "accepted"|"rejected"`, `Idempotency-Key`) → case moves to `pending_review`.

### 16.4 Field visit captured offline, synced later
1. While offline: capture the visit form data and photos locally; do **not** call `/attachments/init` yet (avoid burning the 48h orphan window against a connection you don't have).
2. On reconnect: check token validity first — if the access token is expired, refresh; if the refresh token is also expired (queue older than 7 days), require re-login before proceeding.
3. Upload each pending photo through the full init → PUT → commit sequence (fresh `/init` calls now that you're online).
4. Submit the field-visit `POST` exactly once (app-side dedup — §14.2).
5. `GET /cases/{id}` to confirm current `rowVersion`/status before submitting any queued section edits; if the case's status or assignment changed while offline (e.g., `422 INVALID_STATUS_TRANSITION` or `403` on the next call), stop and surface a conflict to the user rather than continuing to replay the rest of the queue against a stale assumption.
6. Replay queued section `PUT`s against the just-fetched `rowVersion`; on `409 CONCURRENCY_CONFLICT`, re-fetch and let the user resolve rather than force-overwriting.
7. Replay the queued `opinions/worker` submission last, reusing its original `Idempotency-Key`.

---

## 17. Production Integration Checklist

- [ ] Send `X-Client-Type: mobile` on login/refresh/logout.
- [ ] Store tokens in secure platform storage (Keychain/Keystore), not plain SharedPreferences.
- [ ] Serialize refresh calls through one in-flight future; never fire concurrent refreshes.
- [ ] Register the FCM token after every login and on every OS token-refresh callback.
- [ ] Persist a stable `Idempotency-Key` per queued workflow action, generated once, reused on every retry.
- [ ] Never retry `POST /field-visits` or `POST /attachments/init` without app-level dedup — see §14.2.
- [ ] Check access/refresh token validity before attempting to flush any offline queue.
- [ ] On `409 CONCURRENCY_CONFLICT`, re-fetch and reconcile — never force-resubmit the same stale `rowVersion`.
- [ ] On `422 INVALID_STATUS_TRANSITION` / `403` for a queued action, stop replaying the rest of that case's queue and surface a conflict, since the case likely changed server-side while offline.
- [ ] Respect the 15-minute download URL and 48-hour upload-orphan windows in any local caching logic.
- [ ] Do not build any UI path for logging in as `manager`/`reviewer`/`data_entry` from this app.

## 18. Endpoint Details — Locations, Charities, Employees, Profile, Configuration (Dropdowns)

Full per-endpoint detail for every reference-data/admin route. Most of this module is **not reachable by `social_worker`** (see §10's reachability column) — it is included in full because the app still needs `GET /locations`, `GET /charities`, and `GET /dropdowns/{key}` for its own form dropdowns, and because this reference doubles as shared model documentation for any future admin surface. Routes marked not reachable below return `403 FORBIDDEN` for a `social_worker` token; do not build UI for them in this app.


Conventions used throughout this document (all confirmed from source):

- **Envelope**: success = `{ "success": true, "data": {...}, "message": null }`; error = `{ "success": false, "error": { "code", "message", "details" } }`. `ApiResponse<T>`/`ApiResponse`/`ApiErrorResponse` in `Nahda.SharedKernel.Contracts`. `details` is present only when there is field-level validation info (`JsonIgnoreCondition.WhenWritingNull`).
- **JSON casing**: confirmed project-wide camelCase via `ApiJsonOptions` (`JsonNamingPolicy.CamelCase`) — no per-endpoint override found in any of the files read for this group.
- **Pagination**: `PagedResult<T>` — `items`, `page`, `limit`, `total`, `totalPages` (computed), `hasNext`, `hasPrev`. `DefaultPageSize = 20`, `MaxPageSize = 100` (`PagedResult<T>.ClampPageSize` clamps `limit` server-side; the clamp is defined but note: for Charities/Employees the endpoint itself does not visibly call `ClampPageSize` before constructing the query — it passes `limit ?? PagedResult<object>.DefaultPageSize` straight through to the repository. **Unconfirmed**: whether the repository implementation itself clamps to `MaxPageSize` — the interfaces read here don't show it; flagging rather than asserting a numeric ceiling behavior beyond the documented constant).
- **Auth**: every route in this group requires `RequireAuthorization()` (JWT) at minimum; specific permission requirements are called out per endpoint.
- **Idempotency-Key**: none of the endpoints in this group reference `Idempotency-Key` or `IdempotencyKeyRequired` — confirmed absent (that error code is Phase-9 workflow-only per `ErrorCodes.cs`).
- **rowVersion**: the request/response DTOs were checked individually per entity — see each endpoint. Locations (centers/villages) do **not** carry `rowVersion` at all (no optimistic concurrency there); Charities, Employees, and Profile do.

---

### Locations

Source: `src/Nahda.Api/Endpoints/LocationEndpoints.cs`, `src/Modules/Nahda.Modules.Locations/Application/Features/{ListLocationsQuery,CenterCommands,VillageCommands,ResetLocationsCommand}.cs`.

Permission: reads (`GET /locations`) require only authentication (any role). All writes (`centers`, `villages`, `reset`) require `manage_locations`.

#### GET /api/v1/locations

Returns every center with its villages nested underneath — no pagination, no filters (there are none in `ListLocationsQuery`, which takes no parameters at all).

- **Query parameters**: none.
- **Example**: `GET /api/v1/locations`
- **Headers**: standard `Authorization: Bearer <token>` only.
- **Success response** — `200 OK`:
```json
{
  "success": true,
  "data": [
    {
      "id": "6f1e2a10-....",
      "name": "مركز بني سويف",
      "villages": [
        { "id": "9c3b7d20-....", "name": "قرية اختبار" }
      ]
    }
  ],
  "message": null
}
```
  Centers are ordered by `Name` (ordinal string compare); villages within each center are likewise ordered by `Name` ordinal. `LocationCenterDto(Id, Name, Villages)` / `LocationVillageDto(Id, Name)` — no `rowVersion`, no `createdAtUtc`, no soft-delete flag exposed.
- **Errors**: none specific beyond standard 401 (no token).
- **rowVersion**: not applicable — centers/villages have no concurrency token in the API surface.
- **Idempotency-Key**: not applicable (GET).
- **Frontend note**: this is the endpoint to use for cascading center→village pickers (villages already nested) — the dynamic dropdown keys `district`/`village` under `GET /api/v1/dropdowns/{key}` return a **flat** list of *all* active villages regardless of center (see the Configuration section's Frontend note on `DynamicOptionKeys` — a documented source gap, not a bug), so this locations endpoint is the only way to get villages correctly scoped to their center for a cascading UI.

#### POST /api/v1/locations/centers

- **Permission**: `manage_locations`.
- **Request body** (`CreateCenterRequest`):
```json
{ "name": "مركز جديد" }
```

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `name` | string | yes | `NotEmpty()`, `MaximumLength(100)` — message: "اسم المركز مطلوب (100 حرف كحد أقصى)" | — |

- **Success** — `200 OK` (not 201 — confirmed from `Results.Ok(ApiResponse<Guid>.Ok(id))`):
```json
{ "success": true, "data": "6f1e2a10-....", "message": null }
```
  `data` is a bare GUID string (the new center's id), not an object.
- **Errors**:
  - `409 DUPLICATE_RESOURCE` — a center with the same name already exists. Checked via `CenterNameExistsAsync(name, excludingId: null)`, which **respects the soft-delete filter** — a previously-deleted center's name is free to reuse again (confirmed by integration test `A_Center_Name_Freed_By_Deletion_Can_Be_Used_Again`).
  - `422 VALIDATION_ERROR` — empty name or name over 100 chars.
  - `403 FORBIDDEN` — caller lacks `manage_locations` (e.g. `social_worker`).
- **rowVersion**: n/a. **Idempotency-Key**: n/a.

#### PUT /api/v1/locations/centers/{id}

- **Permission**: `manage_locations`.
- **Path params**: `id` (guid, required).
- **Request body** (`UpdateCenterRequest`): `{ "name": "اسم محدث" }` — same validator/rules as create.
- **Success** — `200 OK`: `{ "success": true, "data": null, "message": null }` (non-generic `ApiResponse.Ok()`).
- **Errors**:
  - `404 NOT_FOUND` — center id doesn't exist (`RenameCenterAsync` returns false).
  - `409 DUPLICATE_RESOURCE` — new name collides with another center's name (excluding itself).
  - `422 VALIDATION_ERROR` — empty/oversized name.
- **rowVersion/concurrency**: **none** — `UpdateCenterCommand(Id, Name)` carries no rowVersion field; there is no optimistic-concurrency check on centers/villages at all. Last write wins.

#### DELETE /api/v1/locations/centers/{id}

- **Permission**: `manage_locations`.
- **Success** — `200 OK`, empty `data`.
- **Errors**:
  - `404 NOT_FOUND` — center doesn't exist.
  - `409 DELETE_CONFLICT` — the center still has one or more villages attached (`center.Villages.Count > 0`). The handler deliberately never cascades — the caller must delete/reassign the villages first.
- **Frontend note**: deleting a center is a soft delete (`SoftDeleteCenterAsync`), and its name becomes reusable immediately (see duplicate-name note above) — unlike employee emails, which stay reserved forever after a soft delete. This asymmetry is explicitly called out and tested in the codebase (`BusinessModulesTests`) as intentional, not a bug.

#### POST /api/v1/locations/villages

- **Permission**: `manage_locations`.
- **Request body** (`CreateVillageRequest`):
```json
{ "centerId": "6f1e2a10-....", "name": "قرية جديدة" }
```

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `centerId` | guid | yes | `NotEmpty()` (i.e. not `Guid.Empty`) | must reference an existing center (checked in handler, not the validator) |
| `name` | string | yes | `NotEmpty()`, `MaximumLength(100)` | uniqueness is scoped **per center**, not global |

- **Success** — `200 OK`: `{ "success": true, "data": "<village-guid>", "message": null }`.
- **Errors**:
  - `404 NOT_FOUND` — `centerId` doesn't reference an existing center (`GetCenterByIdAsync` returns null) — this is a plain `NotFoundAppException`, **not** a `ValidationAppException`/422, despite `centerId` being a body field. Confirm this against Charities below, where an invalid `centerId`/`villageId` combination instead produces 422 — the two modules diverge on this point.
  - `409 DUPLICATE_RESOURCE` — a village with the same name already exists **within that center** (`VillageNameExistsInCenterAsync`). The same name is allowed in a different center.
  - `422 VALIDATION_ERROR` — empty/oversized name, or `centerId` = `Guid.Empty`.

#### PUT /api/v1/locations/villages/{id}

- **Permission**: `manage_locations`.
- **Request body** (`UpdateVillageRequest`): `{ "name": "اسم محدث" }` — note there is **no `centerId` field on update** — a village cannot be moved to a different center through this endpoint, only renamed within its current center.
- **Success** — `200 OK`, empty data.
- **Errors**:
  - `404 NOT_FOUND` — village id not found.
  - `409 DUPLICATE_RESOURCE` — duplicate name within the same center.
  - `422 VALIDATION_ERROR` — empty/oversized name.
- **rowVersion**: none (same as centers).

#### DELETE /api/v1/locations/villages/{id}

- **Permission**: `manage_locations`.
- **Success** — `200 OK`.
- **Errors**: `404 NOT_FOUND` only (`SoftDeleteVillageAsync` returns false → NotFound). No `DELETE_CONFLICT` case is implemented for villages (unlike centers) — deleting a village that has charities attached to it was **not found to be checked** in `VillageCommands.cs`; charities reference `VillageId` as a normal FK without a village-emptiness guard in this handler. **Unconfirmed** whether the database enforces a restrict constraint that would surface as a 500/other error in that scenario — not visible from the application-layer code read.

#### POST /api/v1/locations/reset

- **Permission**: `manage_locations`.
- **Request body**: none.
- **Success** — `200 OK`, empty data.
- **Behavior**: calls `ILocationRepository.ResetToSeedAsync()` — wipes and reseeds all centers/villages to the seed data. No filters, no confirmation body, no dry-run.
- **Errors**: none endpoint-specific documented beyond standard 401/403.
- **Frontend note**: this is destructive and irreversible from the API's perspective (whatever currently exists is replaced by seed data) — there is no confirmation token or second-factor gate in the code; the frontend is the only safety net (e.g. a confirmation dialog) since the backend performs the reset unconditionally on a single POST.

---

### Charities

Source: `src/Nahda.Api/Endpoints/CharityEndpoints.cs`, `src/Modules/Nahda.Modules.Charities/Application/Features/{ListCharitiesQuery,CharityCommands,ExportCharitiesCsvQuery}.cs`, `ICharityRepository.cs`.

Permission: `GET /` (list) requires only authentication (any role can read). `GET /export` and all writes require `manage_charities`.

#### GET /api/v1/charities

- **Query parameters**:

| Name | Type | Required | Notes |
|---|---|---|---|
| `search` | string | no | free-text search (repository-level; confirmed SQL-injection-safe by parametrization — a literal `'; DROP TABLE charities; --` search string returns 0 results, not an error, per integration test) |
| `centerId` | guid | no | filters to charities within a specific center |
| `page` | int | no | defaults to 1 |
| `limit` | int | no | defaults to `PagedResult<object>.DefaultPageSize` = 20 |

  There is **no `villageId` filter** on the list query despite `villageId` existing on the entity — only `centerId` and `search`.
- **Example**: `GET /api/v1/charities?search=جمعية&centerId=6f1e2a10-...&page=1&limit=20`
- **Success** — `200 OK`:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "a1b2....",
        "name": "جمعية اختبار",
        "governorate": "بني سويف",
        "centerId": "6f1e2a10-....",
        "villageId": "9c3b7d20-....",
        "phone": "0100",
        "dateAdded": "2026-09-18",
        "rowVersion": 1
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1,
    "hasNext": false,
    "hasPrev": false
  },
  "message": null
}
```
  `CharityListItem(Id, Name, Governorate, CenterId, VillageId, Phone, DateAdded, RowVersion)` — note the list item does **not** include `address`, only `phone`.

#### GET /api/v1/charities/export

- **Permission**: `manage_charities` (note: **stricter** than the plain list endpoint, which any authenticated user can read — export is gated behind the write permission even though it's a GET).
- **Response**: `200 OK`, `Content-Type: text/csv; charset=utf-8`, filename `charities.csv`, UTF-8 **with BOM** (`Encoding.UTF8.GetPreamble()` prepended — for correct Arabic rendering in Excel).
- **CSV columns**: `Name,Governorate,Phone,DateAdded` (in that order; `DateAdded` formatted `yyyy-MM-dd`). Fields are RFC 4180 escaped (quoted if containing comma/quote/newline).
- **No query filters** — `ExportCharitiesCsvQuery` takes no parameters; it always exports **all** active charities unfiltered (unlike Employees' export, which reuses the list's `search`/`role` filters — see below). This is an asymmetry worth flagging to frontend: charity export cannot be scoped by `centerId`/`search` the way the on-screen list can.

#### POST /api/v1/charities

- **Permission**: `manage_charities`.
- **Request body** (`CreateCharityRequest`):
```json
{
  "name": "جمعية جديدة",
  "centerId": "6f1e2a10-....",
  "villageId": "9c3b7d20-....",
  "address": "عنوان الجمعية",
  "phone": "01000000000"
}
```

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `name` | string | yes | `NotEmpty()`, `MaximumLength(255)` | |
| `centerId` | guid | yes | `NotEmpty()` + must exist (`CenterExistsAsync`) | |
| `villageId` | guid | yes | `NotEmpty()` + must belong to `centerId` (`VillageBelongsToCenterAsync`) | checked as a **cross-field** rule in the handler, not the FluentValidation validator |
| `address` | string? | no | `MaximumLength(1000)` | |
| `phone` | string? | no | `MaximumLength(20)` | |

  `governorate` is **not** client-settable — it's hardcoded server-side to `"بني سويف"` for this deployment (`CreateCharityCommandHandler.Governorate`). Sending a `governorate` field in the body has no effect (the DTO has no such property).
- **Success** — `200 OK`: `{ "success": true, "data": "<charity-guid>", "message": null }`.
- **Errors**:
  - `422 VALIDATION_ERROR` — from either the FluentValidation rules above, **or** from the cross-field location check: if `centerId` doesn't exist → `{"centerId": ["المركز غير موجود"]}`; if `villageId` doesn't belong to `centerId` → `{"villageId": ["القرية غير تابعة لهذا المركز"]}`. Both raised as `ValidationAppException` → 422, **not** 404 (confirmed by integration test — sending a mismatched `centerId`/`villageId` pair returns `422 UnprocessableEntity`).
- **rowVersion**: create has none (server assigns it, starts implicitly at whatever the persistence layer initializes — value `1` shown above is illustrative, not guaranteed).

#### PUT /api/v1/charities/{id}

- **Permission**: `manage_charities`.
- **Request body** (`UpdateCharityRequest`):
```json
{
  "name": "جمعية معدلة",
  "centerId": "6f1e2a10-....",
  "villageId": "9c3b7d20-....",
  "address": null,
  "phone": null,
  "rowVersion": 1
}
```

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `name` | string | yes | `NotEmpty()`, `MaximumLength(255)` | |
| `centerId` | guid | yes | `NotEmpty()` + must exist | |
| `villageId` | guid | yes | `NotEmpty()` + must belong to `centerId` | |
| `address` | string? | no | `MaximumLength(1000)` | |
| `phone` | string? | no | `MaximumLength(20)` | |
| `rowVersion` | uint | yes (structurally, it's a non-nullable `uint`) | none explicit in the validator | the concurrency token the client last read |

- **Success** — `200 OK`, empty data.
- **Errors**:
  - `404 NOT_FOUND` — charity id doesn't exist.
  - `409 CONCURRENCY_CONFLICT` — `rowVersion` sent doesn't match the current stored value (confirmed by integration test sending `rowVersion: 999999`). Note: `UpdateAsync`'s doc comment says it "throws … with CONCURRENCY_CONFLICT if the row exists but its xmin no longer matches" and "returns false if the row no longer exists" — so a genuinely missing id yields 404, while a stale rowVersion on an existing id yields 409.
  - `422 VALIDATION_ERROR` — same location cross-checks as create.
- **rowVersion/concurrency**: **yes, required.** This is a real optimistic-concurrency field backed by Postgres `xmin` (per the repository interface doc comment).

#### DELETE /api/v1/charities/{id}

- **Permission**: `manage_charities`.
- **Success** — `200 OK`.
- **Errors**: `404 NOT_FOUND` only — no delete-conflict check found (unlike centers-with-villages); a charity can always be soft-deleted regardless of any dependent data.

---

### Employees

Source: `src/Nahda.Api/Endpoints/EmployeeEndpoints.cs`, `src/Modules/Nahda.Modules.Identity/Application/Features/Employees/{EmployeeCommands,EmployeeQueries,ExportEmployeesCsvQuery}.cs`, `IEmployeeRepository.cs`.

Every write and the plain list/export require `manage_employees` or `view_employees`; `social-workers` uses `create_case` instead (see per-endpoint below). Every mutating command (create/update/role/activate/deactivate/delete) writes a **synchronous** audit row via `IAuditWriter` (never the async Outbox) — Master Plan §13.1 classifies employee administration as transaction-critical.

#### GET /api/v1/employees

- **Permission**: `view_employees`.
- **Query parameters**:

| Name | Type | Required | Notes |
|---|---|---|---|
| `search` | string | no | free text |
| `role` | string | no | one of `manager`, `reviewer`, `data_entry`, `social_worker`; **an unrecognized value silently falls back to `null`** (no filter applied) rather than erroring — `ParseRole` returns `null` for any string it doesn't recognize, so `?role=bogus` behaves identically to omitting the parameter, not a 422. |
| `page` | int | no | default 1 |
| `limit` | int | no | default 20 |

- **Example**: `GET /api/v1/employees?search=%40test.local&role=reviewer&page=1&limit=20`
- **Success** — `200 OK`:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "c1d2....",
        "fullName": "موظف اختبار",
        "email": "user@test.local",
        "role": "reviewer",
        "status": "active",
        "centerId": null,
        "phone": null,
        "rowVersion": 1
      }
    ],
    "page": 1, "limit": 20, "total": 1, "totalPages": 1, "hasNext": false, "hasPrev": false
  },
  "message": null
}
```
  `EmployeeListItem(Id, FullName, Email, Role, Status, CenterId, Phone, RowVersion)` — `role`/`status` are wire strings (`"manager" | "reviewer" | "data_entry" | "social_worker"`, `"active" | "inactive"`), not raw enum ordinals. `gender` is **not** in the list item at all.

#### GET /api/v1/employees/export

- **Permission**: `manage_employees` (note: **stricter** than the list's `view_employees` — a role with `view_employees` but not `manage_employees` can see the on-screen list but cannot export it; confirmed by test `Only_Manage_Employees_Permission_Can_Export_Not_Any_Other_Role`).
- **Query parameters**: `search`, `role` — **reuses the exact same filters as `GET /employees`** (unlike Charities' export, which has no filters at all).
- **Response**: `200 OK`, `text/csv; charset=utf-8`, filename `employees.csv`, UTF-8 with BOM.
- **CSV columns**: `FullName,Email,Role,Status,Phone` — deliberately **excludes** `centerId` and, obviously, the password hash / any credential material.

#### GET /api/v1/employees/social-workers

- **Permission**: `create_case` — **not** `view_employees`/`manage_employees`. This is intentional: roles that can create a case (e.g. `data_entry`) but lack `view_employees` still need a picker to assign a social worker.
- **Query parameters**: `search` (string, optional) only.
- **Success** — `200 OK`:
```json
{ "success": true, "data": [ { "id": "c1d2....", "fullName": "أخصائي اجتماعي", "phone": "0100", "centerId": "6f1e2a10-...." } ], "message": null }
```
  `SocialWorkerListItem(Id, FullName, Phone, CenterId)` — a deliberately minimal shape (no `email`, `role`, `status`, `rowVersion`) since it's consumed by roles without full employee-management visibility. Returns only **active** social workers (per doc comment on `ListSocialWorkersQuery`).

#### POST /api/v1/employees

- **Permission**: `manage_employees`.
- **Request body** (`CreateEmployeeRequest`):
```json
{
  "fullName": "موظف جديد",
  "email": "new.employee@test.local",
  "password": "Str0ng#Passw0rd",
  "role": "reviewer",
  "centerId": null,
  "phone": null,
  "gender": null
}
```

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `fullName` | string | yes | `NotEmpty()`, `MaximumLength(255)` | |
| `email` | string | yes | `NotEmpty()`, `EmailAddress()`, `MaximumLength(255)` | uniqueness checked with `IgnoreQueryFilters()` — see Frontend note below |
| `password` | string | yes | `NotEmpty()`, `MinimumLength(8)` | no complexity/character-class rule beyond length found in this validator |
| `role` | string | yes | `NotEmpty()`, must be one of `manager`, `reviewer`, `data_entry`, `social_worker` | message: "الدور الوظيفي غير صحيح" |
| `centerId` | guid? | no | if provided, must reference an existing center | checked in handler, not validator |
| `phone` | string? | no | `MaximumLength(20)` | |
| `gender` | string? | no | no validator rule found — **unconfirmed** allowed value set (no enum/allow-list check visible in `CreateEmployeeCommandValidator`) |

- **Success** — `200 OK`: `{ "success": true, "data": "<user-guid>", "message": null }`. New employees are created with `Status = Active` always (not client-settable).
- **Errors**:
  - `409 DUPLICATE_RESOURCE` — email already in use.
  - `422 VALIDATION_ERROR` — from the rules above, or `{"centerId": ["المركز غير موجود"]}` if `centerId` doesn't exist.
- **Frontend note**: an employee's email is **reserved permanently**, even after the employee is soft-deleted (`EmailExistsAsync` uses `IgnoreQueryFilters()`). Attempting to re-create an account with a previously-deleted employee's email returns a clean `409 DUPLICATE_RESOURCE`, not a 500 — but the email can never be reused. This is the **opposite** behavior from center/village names, which do free up on deletion — both are confirmed intentional and separately tested (`An_Email_Stays_Reserved_After_The_Employee_Is_Deleted` vs. `A_Center_Name_Freed_By_Deletion_Can_Be_Used_Again`).

#### PUT /api/v1/employees/{id}

- **Permission**: `manage_employees`.
- **Request body** (`UpdateEmployeeRequest`):
```json
{ "fullName": "اسم محدث", "centerId": null, "phone": "0100", "gender": null, "rowVersion": 1 }
```

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `fullName` | string | yes | `NotEmpty()`, `MaximumLength(255)` | |
| `centerId` | guid? | no | must exist if provided | |
| `phone` | string? | no | `MaximumLength(20)` | |
| `gender` | string? | no | no rule found | |
| `rowVersion` | uint | yes | — | concurrency token |

  **Structurally excludes** `role`, `status`, `email`, and `password` — there is no way to mass-assign these through this endpoint even by sending extra JSON fields (confirmed by integration test that smuggles `"role": "manager", "status": "active"` in a raw JSON body and shows neither field changes).
- **Success** — `200 OK`, empty data.
- **Errors**:
  - `404 NOT_FOUND` — employee id not found.
  - `409 CONCURRENCY_CONFLICT` — stale `rowVersion` (via `UpdateProfileFieldsAsync`'s same concurrency contract as Charities).
  - `422 VALIDATION_ERROR` — validation rules above, or `{"centerId": ["المركز غير موجود"]}`.
- **Audit**: writes `EMPLOYEE_UPDATED` synchronously, metadata records only the **field names** touched (`["fullName","centerId","phone","gender"]`), never the actual values (phone/name are personal data — §19.6).

#### POST /api/v1/employees/{id}/role

- **Permission**: `manage_employees`.
- **Request body** (`ChangeEmployeeRoleRequest`): `{ "role": "data_entry" }`.

| Field | Type | Required | Validation |
|---|---|---|---|
| `role` | string | yes | `NotEmpty()`, must be one of `manager`, `reviewer`, `data_entry`, `social_worker` |

- **Success** — `200 OK`, empty data.
- **Errors**: `404 NOT_FOUND` only (no 422 path documented at the endpoint level beyond the validator's own role-name check, which is also 422 `VALIDATION_ERROR` if violated).
- **Audit**: `EMPLOYEE_ROLE_CHANGED`, metadata records the new role value (role names aren't sensitive).
- **Frontend note**: **no self-demotion/last-manager guard was found.** Neither `ChangeEmployeeRoleCommandHandler` nor `ChangeEmployeeStatusCommandHandler` nor `SoftDeleteEmployeeCommandHandler` check whether `id` equals the caller's own id, nor whether the target is the last remaining `manager`. A manager can change their own role, deactivate themselves, or (per the delete endpoint) soft-delete their own account through the API as written — this contradicts an assumption a frontend might reasonably make; there is no backend safety net for it as of this reading of the code.

#### POST /api/v1/employees/{id}/activate | POST /api/v1/employees/{id}/deactivate

- **Permission**: `manage_employees`.
- **Request body**: none for either.
- **Success** — `200 OK`, empty data.
- **Errors**: `404 NOT_FOUND` only.
- **Audit**: `EMPLOYEE_ACTIVATED` / `EMPLOYEE_DEACTIVATED` (two distinct action codes, not one code with a boolean — chosen so "who was ever deactivated" is an index-friendly equality filter on the audit log).
- **Frontend note**: same self-service caveat as role-change above — no guard against deactivating your own account or the last active manager.

#### DELETE /api/v1/employees/{id}

- **Permission**: `manage_employees`.
- **Success** — `200 OK`, empty data (soft delete).
- **Errors**: `404 NOT_FOUND` only.
- **Audit**: `EMPLOYEE_DELETED`, `metadataJson: null` (no extra metadata recorded — the audit row's existence past the soft-deleted user is itself the point, since `audit_logs` is append-only and unfiltered).
- **Frontend note**: as above, no self-delete or last-manager protection found; also, the employee's email becomes permanently unusable for any future account (see the duplicate-email note under `POST /employees`).

---

### Profile

Source: `src/Nahda.Api/Endpoints/ProfileEndpoints.cs`, `UpdateOwnProfileCommand` in `EmployeeCommands.cs`.

#### PUT /api/v1/profile

- **Permission**: authentication only (no specific permission — every authenticated user can edit their own profile).
- **Target user id**: **always** taken from the caller's own JWT `sub` claim — there is no id in the route or body, so this endpoint is structurally incapable of editing another user's record (not just permission-checked — IDOR is impossible by construction).
- **Request body** (`UpdateOwnProfileRequest`):
```json
{ "fullName": "الاسم الجديد", "phone": null, "gender": null, "rowVersion": 1 }
```

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `fullName` | string | yes | `NotEmpty()`, `MaximumLength(255)` | |
| `phone` | string? | no | `MaximumLength(20)` | |
| `gender` | string? | no | no rule found | |
| `rowVersion` | uint | yes | — | concurrency token, same `UpdateProfileFieldsAsync` mechanism as the admin employee update |

  **No `centerId` field at all** — even narrower than the admin `UpdateEmployeeCommand` — which center an employee belongs to is an administrative assignment, not self-editable.
- **Success** — `200 OK`, empty data.
- **Errors**:
  - `404 NOT_FOUND` — theoretically only if the user record vanished mid-session (not realistically reachable via normal flows since the JWT implies the row existed at login).
  - `409 CONCURRENCY_CONFLICT` — stale `rowVersion`.
  - `422 VALIDATION_ERROR` — empty/oversized `fullName`, oversized `phone`.
- **Audit**: writes `EMPLOYEE_PROFILE_UPDATED` synchronously (a different action code from the admin-driven `EMPLOYEE_UPDATED`), metadata records field names only (`["fullName","phone","gender"]`). Actor and subject are always the same id here.
- **rowVersion/concurrency**: yes, required, same mechanism as employee/charity updates.
- **Idempotency-Key**: not required.

---

### State Data Configuration (dropdown-configs / dropdown-options / dropdowns)

Source: `src/Nahda.Api/Endpoints/ConfigurationEndpoints.cs` (contains extensive inline doc comments already reasoned through by the original implementers — reproduced/confirmed below, not re-derived), `src/Modules/Nahda.Modules.Configuration/Application/Features/{DropdownConfigQueries,GetDropdownQuery,DropdownOptionCommands}.cs`, and `tests/Nahda.IntegrationTests/ConfigurationTests.cs` for concrete examples.

**Permission model**: every route under `/dropdown-configs` and `/dropdown-options` (6 admin routes) requires `manage_configurations` — held by `manager` only (confirmed: `reviewer`/`data_entry`/`social_worker` all get 403 on every admin route, per `Non_Manager_Roles_Are_Denied_On_Every_Admin_Route`). The one exception is `GET /api/v1/dropdowns/{key}` (consumption), which requires authentication only — confirmed every role (including `social_worker` on mobile) can call it.

**Validation status code**: 422 `VALIDATION_ERROR` (not 400) — consistent with the rest of this system since Phase 1; explicitly noted in the source as a deliberate, documented divergence from an older spec document that said 400.

**Error code mapping note**: the source spec (a separate design doc) names `DUPLICATE`, `IN_USE`, `SERVER_ERROR` — none of which exist in this codebase's `ErrorCodes` catalogue. They are mapped onto the real shipped codes: `DUPLICATE_RESOURCE`, `DELETE_CONFLICT` (unused in practice here — no `IN_USE` case actually triggers in the option handlers read), and `INTERNAL_ERROR` respectively. Only `DUPLICATE_RESOURCE`, `FORBIDDEN`, `VALIDATION_ERROR`, and `NOT_FOUND` were observed as actually reachable for these routes.

#### GET /api/v1/dropdown-configs

- **Permission**: `manage_configurations`.
- **Query parameters**:

| Name | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `step` | short (1-8) | no | if provided, must be 1-8 or 422 `{"step": ["رقم المحطة يجب أن يكون بين 1 و 8"]}` | |
| `fieldType` | string | no | must be `select`, `chip`, or `support` or 422 `{"fieldType": [...]}` | |
| `isActive` | bool | no | — | |

- **Example**: `GET /api/v1/dropdown-configs?fieldType=support&step=7`
- **Success** — `200 OK`:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "00000000-0000-0000-0003-000000000048",
        "key": "دعم طبي",
        "label": "دعم طبي",
        "fieldType": "support",
        "step": 7,
        "isFixed": false,
        "allowOther": false,
        "dependencyKey": null,
        "sortOrder": 48,
        "isActive": true,
        "optionsCount": 7
      }
    ],
    "meta": { "total": 53, "byType": { "select": 25, "chip": 19, "support": 9 } }
  },
  "message": null
}
```
  Note `meta` is **nested inside `data`**, not a sibling of it at the envelope's top level — the fixed `{success, data, message}` envelope permits no other top-level keys. `byType` always has all three keys present (0 rather than absent when filtered to zero of a type).
- **Full unfiltered seed**: confirmed exactly 53 configurations — 25 `select`, 19 `chip`, 9 `support` (all 9 support types are step 7).

#### GET /api/v1/dropdown-configs/{id}

- **Permission**: `manage_configurations`.
- **Path params**: `id` (guid).
- **Success** — `200 OK`, single `DropdownConfigDto` (same shape as one item above, without the `meta`/`items` wrapper).
- **Errors**: `404 NOT_FOUND` — "قائمة الإعدادات غير موجودة".

#### GET /api/v1/dropdown-configs/{key}/options

- **Permission**: `manage_configurations`.
- **Path params**: `key` (**string key, not the id** — confirmed intentional asymmetry vs. the POST-options route below, which uses `id`; preserved from the source spec as-is rather than "corrected").
- **Example**: `GET /api/v1/dropdown-configs/head-relation/options` or `GET /api/v1/dropdown-configs/دعم طبي/options` (Arabic keys are valid — several configuration keys are Arabic strings, confirmed by test).
- **Success** — `200 OK`, array of `DropdownOptionDto`:
```json
{
  "success": true,
  "data": [
    {
      "id": "00000000-0000-0000-0004-000000000006",
      "configId": "00000000-0000-0000-0003-000000000048",
      "value": "دعم-طبي-جذر",
      "label": "دعم طبي",
      "isOther": false,
      "isActive": true,
      "sortOrder": 0,
      "parentOptionId": null
    }
  ],
  "message": null
}
```
  Returns **all** options including inactive ones — this is the admin listing (a deactivated option must remain visible so it can be reactivated). The consumption endpoint (`GET /api/v1/dropdowns/{key}`) is the one that filters to active-only.
- **Errors**: `404 NOT_FOUND` — key doesn't match any configuration.

#### POST /api/v1/dropdown-configs/{id}/options

- **Permission**: `manage_configurations`.
- **Path params**: `id` (guid — the **configuration's** id, this time, not the key).
- **Request body** (`CreateDropdownOptionRequest`):
```json
{ "value": "عم", "label": "العم", "sortOrder": 11, "isOther": false, "parentOptionId": null }
```

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `value` | string | yes | `NotEmpty()`, `MaximumLength(255)` | the value stored against case records |
| `label` | string | yes | `NotEmpty()`, `MaximumLength(255)` | display text |
| `sortOrder` | short? | no | — | defaults to `0` if omitted |
| `isOther` | bool? | no | — | defaults to `false` |
| `parentOptionId` | guid? | no | must belong to the **same** configuration if provided, else 422 | used for "support" type sub-options |

  Structurally excludes `id`, `configId`, `isActive`, timestamps — none of these are bindable even if sent in the raw JSON body (confirmed by test `Mass_Assignment_Of_Id_ConfigId_And_IsActive_Is_Ignored`: a forged `id`/different `configId`/`isActive: false` are all silently dropped; the server always assigns its own id, uses the route's configId, and always creates active).
- **Success** — **`201 Created`** (the only endpoint in this group that returns 201, not 200), `Location` header `/api/v1/dropdown-options/{result.Id}`:
```json
{
  "success": true,
  "data": {
    "id": "<new-option-guid>",
    "configId": "<config-guid-from-route>",
    "value": "عم",
    "label": "العم",
    "isOther": false,
    "isActive": true,
    "sortOrder": 11,
    "parentOptionId": null
  },
  "message": null
}
```
- **Errors**:
  - `404 NOT_FOUND` — the `{id}` configuration doesn't exist.
  - `403 FORBIDDEN` — the configuration is `isFixed=true` — applies **even to a manager**; this is a data-level constraint, not an authorization check, so full `manage_configurations` rights don't override it.
  - `409 DUPLICATE_RESOURCE` — `value` already exists in this configuration; enforced by a **real database unique constraint** (`UNIQUE(config_id, value)`), confirmed race-safe under concurrent identical POSTs (exactly one of two simultaneous requests wins with 201, the loser gets 409) — not merely an application-level pre-check.
  - `422 VALIDATION_ERROR` — empty/oversized `value`/`label`, or `{"parentOptionId": ["الخيار الأصلي غير موجود في هذه القائمة"]}` if the parent belongs to a different configuration.
- **Audit**: `DROPDOWN_OPTION_CREATED`, synchronous. **Cache invalidation**: the owning configuration's Redis cache entry is invalidated after the write commits.

#### PATCH /api/v1/dropdown-options/{id}

- **Permission**: `manage_configurations`.
- **Request body** (`UpdateDropdownOptionRequest`) — genuine partial update, every field nullable, **omitted ⇒ unchanged** (not "set to null"):
```json
{ "isActive": false }
```

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `label` | string? | no | `NotEmpty()`, `MaximumLength(255)` — **only enforced when the field is present** (`.When(x => x.Label is not null)`) | sending `label: ""` explicitly does fail 422; omitting `label` entirely never touches it |
| `sortOrder` | short? | no | — | |
| `isActive` | bool? | no | — | `{"isActive": false}` is the **soft-delete path** — see Frontend note |
| `isOther` | bool? | no | — | |

  **`value` is not present on this DTO at all** — it can never be changed via PATCH. The stored `value` is what case records reference by string; renaming it in place would silently orphan every case holding the old value. To "rename" a value: deactivate the old option and add a new one.
- **Success** — `200 OK`, the full updated `DropdownOptionDto` (confirmed: unsent fields like `label` are unchanged in the response, per test `Patch_Updates_Only_The_Fields_Sent`).
- **Errors**:
  - `404 NOT_FOUND` — option id doesn't exist.
  - `403 FORBIDDEN` — the owning configuration is `isFixed=true` (checked before applying any field, even if only touching an unrelated field like `sortOrder`).
  - `422 VALIDATION_ERROR` — only if `label` is sent and is empty/oversized.
- **Audit**: `DROPDOWN_OPTION_UPDATED`, metadata includes `configKey`, `value`, `label`, `isActive`, `sortOrder`, `isOther` (actual values, not just field names — unlike the Employee update's metadata-by-name-only pattern). **Cache invalidation**: same as create.
- **Frontend note**: this is also the **only supported deactivation path**. §8 business rule 6 requires deactivating before any further lifecycle step, and per the "Nahda Backend Integration Decisions" doc referenced in the source, hard delete is now permanently disabled (see DELETE below) — `PATCH {"isActive": false}` is the terminal retirement action for a dropdown value in this system.

#### DELETE /api/v1/dropdown-options/{id}

- **Permission**: `manage_configurations`.
- **Behavior**: **always returns `403 FORBIDDEN`**, unconditionally — confirmed the handler still does a `GetOptionWithConfigurationAsync` lookup first (so a genuinely nonexistent `id` yields `404 NOT_FOUND` **before** the 403 check is reached — the 403 is only guaranteed once the option is confirmed to exist), then throws `ForbiddenAppException` regardless of the option's active state or whether it has children. **No row is ever removed by this route**, for any input, regardless of caller role (even `manager` with full `manage_configurations`).
- **Response body on the 403 path**:
```json
{ "success": false, "error": { "code": "FORBIDDEN", "message": "الحذف النهائي غير مسموح به نهائيًا؛ استخدم تعطيل الخيار (PATCH isActive=false) بدلًا من ذلك" } }
```
- **Route kept mapped** purely for URL/backward compatibility with older clients; it is explicitly documented in-source as hard-disabled per a later "Integration Decisions" document that superseded the original spec's two-step hard-delete lifecycle. `IDropdownRepository.DeleteOptionAsync` is no longer called from this handler at all.
- **Correction to the task's framing**: the endpoint is not literally "always 403" for every input — an id that doesn't exist at all still surfaces `404 NOT_FOUND` first (confirmed by reading `DeleteDropdownOptionCommandHandler.Handle`, which does the existence lookup before the unconditional `ForbiddenAppException`). For any **existing** option it is unconditionally 403.

#### GET /api/v1/dropdowns/{key}

- **Permission**: authentication only (confirmed every role, including `social_worker` on mobile, gets 200).
- **Path params**: `key` (string — static keys like `gender`, `head-relation`, `دعم طبي`, or one of the 5 dynamic keys: `district`, `village`, `referral-district-select`, `referral-village-select`, `referral-charity-select`).
- **Success** — `200 OK`:
```json
{
  "success": true,
  "data": {
    "key": "دعم طبي",
    "options": [
      { "id": "00000000-0000-0000-0004-000000000006", "value": "دعم-طبي-جذر", "label": "دعم طبي", "isOther": false, "sortOrder": 0, "parentOptionId": null }
    ]
  },
  "message": null
}
```
  Confirmed by test that the **top-level response object has exactly** `success`, `data`, `message` — no sibling `cached`/`cacheTtl` fields (an older spec document had put those at the top level; this codebase's fixed envelope rule forbids it).
- **Behavior/business rules** (§8 rule 1): an option is returned only if `option.isActive=true` **and** `config.isActive=true`. A **disabled configuration** returns an **empty `options` array**, not a 404 — the key still exists, the field simply has nothing to offer. A key that doesn't correspond to **any** configuration at all returns `404 NOT_FOUND` (confirmed by test).
- **Caching**: Redis, key `nahda:dropdowns:v1:{key}`, TTL 3600s, invalidated immediately on any mutation to that configuration's options (create/PATCH). **Cache-down fallback**: if Redis is unavailable, the handler transparently falls back to a live DB query and never surfaces an error to the client — confirmed as the identical mechanism `GetDashboardStatsQueryHandler` already uses elsewhere in the system, not a new one.
- **Dynamic keys**: `district`/`referral-district-select` resolve to `Centers`; `village`/`referral-village-select` resolve to `Villages`; `referral-charity-select` resolves to `Charities`. For these keys, `value` in each returned option is the **row's UUID**, not a name string — confirmed live (creating a center through `POST /api/v1/locations/centers` immediately appears via `GET /api/v1/dropdowns/district`, with no seed/migration step). **Documented source gap**: village-type dynamic keys (`village`, `referral-village-select`) return **every active village regardless of center** — there is no center-scoping query parameter on this consumption route. For a center-scoped village list, use `GET /api/v1/locations` instead (villages are already nested under their center there).
- **Errors**: `404 NOT_FOUND` — key matches no configuration at all.

---

### Summary / deviations from the "known context" provided

All of the following were **confirmed to match** the known context exactly, with no contradictions found:
- Envelope shape, pagination shape, rowVersion/concurrency semantics (409 `CONCURRENCY_CONFLICT`), and the specific error codes cited (`VALIDATION_ERROR`=422, `NOT_FOUND`=404, `DUPLICATE_RESOURCE`=409, `DELETE_CONFLICT`=409, `CONCURRENCY_CONFLICT`=409, `FORBIDDEN`=403).
- Permissions: `manage_locations`, `manage_charities`, `view_employees`, `manage_employees`, `create_case` (social-workers list), profile = auth-only. All confirmed exactly as stated, including the extra `manage_configurations` permission (manager-only) for the dropdown-config admin routes, which was not in the task's "known context" list but is real and load-bearing.
- `DELETE /dropdown-options/{id}` is indeed hard-disabled and returns 403 — **with one caveat**: a nonexistent id still returns 404 first (the existence check runs before the unconditional forbid).

Notable findings not explicitly promised in the known context (documented above per-endpoint, flagged again here for visibility):
1. **No self-service protection on employee role/status/delete** — a manager can deactivate, re-role, or soft-delete their own account, or the last remaining manager, via the API as written. No such guard exists in `ChangeEmployeeRoleCommandHandler`, `ChangeEmployeeStatusCommandHandler`, or `SoftDeleteEmployeeCommandHandler`.
2. **Employee emails are permanently reserved** after soft-delete (`IgnoreQueryFilters()` on the uniqueness check) while **center/village names free up** on deletion — an intentional asymmetry, tested explicitly in both directions.
3. **Centers/villages have no `rowVersion`/optimistic concurrency at all** (unlike Charities/Employees/Profile, which all do) — last-write-wins on center/village renames.
4. `GET /employees/export` requires `manage_employees` while the plain `GET /employees` list only requires `view_employees` — a real permission gap between viewing and exporting the same data. `GET /charities/export` similarly requires `manage_charities` while `GET /charities` needs only authentication.
5. Charity export has **no filters** (always exports everything active); Employee export **reuses** the list's `search`/`role` filters — asymmetric between the two otherwise-parallel features.
6. `centerId` not found on `POST /locations/villages` yields `404 NOT_FOUND`, but the analogous "center doesn't exist" check on `POST /charities` yields `422 VALIDATION_ERROR` — the two modules are not consistent with each other on this point, worth flagging for frontend error-handling code that might otherwise assume one behavior applies everywhere.
7. `role`/`gender` fields with no server-side allow-list found: `gender` has no format/allow-list validation anywhere it appears (create employee, update employee, own-profile update) — treat as free text unless a dropdown-config constrains it client-side. `role` on invalid query-string filters silently no-ops rather than erroring.

Endpoint count covered: all endpoints listed in the task (locations: 6 routes incl. GET/POST/PUT/DELETE variants; charities: 5; employees: 9; profile: 1; dropdown-configs/options/dropdowns: 7) — every route in the provided list has a subsection.

---

## 19. Endpoint Details — Cases Core (List, Detail, Wizard Sections, Bookmarks)

Full per-endpoint detail for the case-reading and case-editing routes a `social_worker` actually uses in the field: `GET /cases`, `GET /cases/{id}`, `GET /cases/{id}/completion`, `GET /cases/{id}/family-members`, the bookmark routes, and all 9 wizard-section `PUT` endpoints (editable only on the worker's own assigned case — see §7.1/§9.4 in the web doc's edit-authorization rule, which applies identically here). `POST /cases` (create) is included for completeness even though `social_worker` lacks `create_case` and will always get `403` from it.


Source of truth: `src/Nahda.Api/Endpoints/CaseEndpoints.cs`, `src/Nahda.Api/Endpoints/CaseSectionEndpoints.cs`,
and the corresponding `Application/Features/*` command/query files under
`src/Modules/Nahda.Modules.Cases/`. Realistic values pulled from
`tests/Nahda.IntegrationTests/CaseCoreTests.cs`, `CaseBookmarkTests.cs`, `CaseSectionsTests.cs`, `FinancialEngineTests.cs`.

> **CORRECTION to provided "known context":** the case-list filter set is **NOT** `status, bookmarked,
> assignedTo, centerId, priority`. `ListCasesQuery` (and the `GET /api/v1/cases` route binding) only
> accepts **`status`** and **`bookmarked`** as filters, plus `page`/`limit`. There is no `assignedTo`,
> `centerId`, or `priority` filter on this endpoint today — the query's own XML doc says search
> (name/national-id/phone/charity/region/date) is "explicitly Phase 12" and out of scope; this list query
> "only supports the one filter Phase 6 needs." Do not document filters that don't exist.

---

#### GET /api/v1/cases

List cases, paginated, filtered by status and/or per-user bookmark.

**Permission:** `view_cases`

**Query parameters:**

| Name | Type | Required | Notes |
|---|---|---|---|
| `status` | string | No | Must be one of the 10 case statuses (`draft`, `pending_assignment`, `assigned`, `accepted`, `in_research`, `pending_review`, `returned_to_worker`, `pending_approval`, `approved`, `rejected`). Any other value → 422 `VALIDATION_ERROR` (message "حالة غير صحيحة"). Tested explicitly against a SQL-injection-style string, which is rejected as 422, not a crash. |
| `bookmarked` | boolean | No | `true` restricts the list to cases the **calling user** has bookmarked (per-actor; reuses the same list pipeline, not a separate endpoint). `false`/omitted = no bookmark filtering. |
| `page` | int | No | Default `1`. |
| `limit` | int | No | Default `20` (`PagedResult.DefaultPageSize`). Server clamps to max `100` (`PagedResult.MaxPageSize`) — `ClampPageSize` treats `<=0` as the default and anything above 100 is capped, it does not error. |

There is **no** `assignedTo`, `centerId`, or `priority` filter — confirmed absent from both the endpoint
route-parameter list and `ListCasesQuery`'s record shape.

Example URL:
```
GET /api/v1/cases?status=assigned&bookmarked=true&page=1&limit=20
```

**Headers:** `Authorization: Bearer <token>` only.

**Success response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "5b1e2a3c-...",
        "caseNumber": "C-2026-000123",
        "displayId": "123",
        "status": "assigned",
        "priority": "urgent",
        "beneficiaryFullName": "أحمد محمود علي",
        "nationalId": "29805142200015",
        "charityId": null,
        "registrationDate": "2026-09-18",
        "completionPercentage": 33.33,
        "createdAtUtc": "2026-09-18T09:00:00Z",
        "nextVisitDate": "2026-09-18",
        "nextVisitStartTimeUtc": "2026-09-18T08:00:00Z",
        "nextVisitLocation": "قرية كذا",
        "isBookmarked": true
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1,
    "hasNext": false,
    "hasPrev": false
  },
  "message": null
}
```
`CaseListItem` fields (exact source order): `id, caseNumber, displayId, status, priority,
beneficiaryFullName, nationalId, charityId, registrationDate, completionPercentage, createdAtUtc,
nextVisitDate, nextVisitStartTimeUtc, nextVisitLocation, isBookmarked`. `nextVisit*` fields are the
earliest not-yet-completed field visit (today or later, in practice never later than today per the field
visit validator) — flat scalars, not a nested object, by deliberate design (kept identical in shape to
the Dashboard's `WorkQueueItem` and Search's `CaseSearchResultItem`, enforced by contract tests).
Visibility is global: any authenticated user can see any case (confirmed "Nahda Backend Integration
Decisions" §4/§20 — not creator/assignee-scoped for list or GET-by-id).

**Errors:**
- `401 UNAUTHORIZED` — no/invalid token.
- `422 VALIDATION_ERROR` — invalid `status` value.

**rowVersion / concurrency:** N/A (read-only list).
**Idempotency-Key:** not applicable (GET).

---

#### POST /api/v1/cases

Create a new case (draft) with its beneficiary.

**Permission:** `create_case` (social_worker does **not** have this permission by default — OB-04 default "no").

**Request body:**
```json
{
  "beneficiary": {
    "fullName": "أحمد محمود علي",
    "nationalId": "29805142200015",
    "phonePrimary": "01012345678",
    "centerId": "00000000-0000-0000-0001-000000000001",
    "villageId": "8f2a...-village-guid",
    "address": "عنوان تجريبي"
  },
  "charityId": null,
  "priority": "urgent"
}
```

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| `beneficiary.fullName` | string | Yes | NotEmpty, max 255 | |
| `beneficiary.nationalId` | string | Yes | NotEmpty; also must decode successfully (14-digit Egyptian national ID format, valid century/month/day/governorate code) or 422 with field key `nationalId` | Digits normalized (Arabic-Indic → ASCII) before decode |
| `beneficiary.phonePrimary` | string? | No | max 20 | No `01\d{9}` regex here (unlike the beneficiary-section PUT) |
| `beneficiary.centerId` | Guid | Yes | NotEmpty; must exist (`centerId` 422 "المركز غير موجود") | |
| `beneficiary.villageId` | Guid | Yes | NotEmpty; must belong to `centerId` (`villageId` 422 "القرية غير تابعة لهذا المركز") | |
| `beneficiary.address` | string? | No | max 1000 | |
| `charityId` | Guid? | No | must exist if provided (`charityId` 422 "الجمعية غير موجودة") | |
| `priority` | string? | No | one of `low, medium, high, urgent`, else 422 | Defaults to `medium` server-side if null/omitted |

**Confirmed from `CreateCaseCommand.cs`:** the request shape has **no** fields for `age`, `gender`,
`birthGovernorate`, `status`, `caseNumber`, or `displayId` — these are 100% server-derived
(age/gender/birthGovernorate decoded from the national ID; status is hard-coded to `draft`; case number
and display ID come from atomic Postgres sequences). A mass-assignment integration test proves that
smuggling `age`, `gender`, `birthGovernorate`, `status`, `createdBy` in the raw JSON body has zero effect.

**Success response `200 OK`** (note: 200, not 201):
```json
{
  "success": true,
  "data": {
    "id": "5b1e2a3c-...",
    "caseNumber": "C-2026-000123",
    "status": "draft"
  },
  "message": null
}
```
`CreateCaseResult(Id, CaseNumber, Status)` — status is always the literal string `"draft"`.

**Errors:**
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` — actor lacks `create_case` (e.g. social_worker).
- `422 VALIDATION_ERROR` — missing/invalid fields, invalid national ID structure, nonexistent/mismatched center/village, nonexistent charity.
- `409 DUPLICATE_NATIONAL_ID` — a case with this national ID already exists:
```json
{
  "success": false,
  "error": {
    "code": "DUPLICATE_NATIONAL_ID",
    "message": "يوجد حالة مسجلة بالفعل بهذا الرقم القومي",
    "details": {
      "existingCaseNumber": ["C-2026-000045"],
      "existingCaseStatus": ["draft"]
    }
  }
}
```
(Note `details.existingCaseNumber`/`existingCaseStatus` are arrays with a single string, per FluentValidation-style dictionary-of-arrays shape, not bare strings.)

**rowVersion/concurrency:** N/A on create. Case number allocation uses a real Postgres sequence — never `MAX()+1` — proven collision-free under concurrent creation.
**Idempotency-Key:** none; not sent, not required (confirmed no idempotency mechanism referenced anywhere in this command).

**Frontend note:** BR-01 duplicate check is done both at the application layer (fast, friendly 409 with existing case's number/status for a "go to existing case" UX) and backstopped by a DB unique index for races — so under a true race the app might occasionally see a raw DB-constraint-style failure instead of the friendly 409, though the primary/documented path is the 409 shown above.

---

#### GET /api/v1/cases/{id}

Full case detail: case fields, beneficiary, completion, and the workflow block.

**Permission:** `view_cases` (global visibility — any authenticated user can view any case).

**Path params:** `id` (Guid, required).

Example: `GET /api/v1/cases/5b1e2a3c-1111-2222-3333-444455556666`

**Side effect:** every successful call records exactly one `CASE_VIEWED` audit event (not recorded on `ListCases`, and not recorded on a failed/404 lookup).

**Success response `200 OK`** — `CaseDetailsDto`, exact shape and field order from `GetCaseByIdQuery.cs`:
```json
{
  "success": true,
  "data": {
    "id": "5b1e2a3c-...",
    "caseNumber": "C-2026-000123",
    "displayId": "123",
    "status": "assigned",
    "priority": "urgent",
    "charityId": null,
    "registrationDate": "2026-09-18",
    "createdAtUtc": "2026-09-18T09:00:00Z",
    "updatedAtUtc": "2026-09-18T10:15:00Z",
    "rowVersion": 4,
    "beneficiary": {
      "fullName": "أحمد محمود علي",
      "nationalId": "29805142200015",
      "age": 28,
      "gender": "male",
      "birthGovernorate": "بني سويف",
      "phonePrimary": "01012345678",
      "phoneSecondary": null,
      "address": "عنوان تجريبي",
      "centerId": "00000000-0000-0000-0001-000000000001",
      "villageId": "8f2a...-village-guid",
      "rowVersion": 2
    },
    "completion": {
      "percentage": 33.33,
      "isReady": false
    },
    "workflow": {
      "currentStage": "assigned",
      "availableActions": ["accept_assignment", "reject_assignment"]
    }
  },
  "message": null
}
```

**Top-level `CaseDetailsDto` fields (exact order):** `id, caseNumber, displayId, status, priority,
charityId, registrationDate, createdAtUtc, updatedAtUtc, rowVersion, beneficiary, completion, workflow`.

- `rowVersion` at the **top level** is the **Case's own** row version (used for concurrency on the
  section PUTs that key off `caseRowVersion`/list sections). `beneficiary.rowVersion` is a **separate**,
  independently-versioned field used specifically for `PUT /beneficiary`'s `rowVersion` body field. These
  are two different counters on two different rows — do not conflate them.
- `beneficiary` (`CaseBeneficiaryDto`): `fullName, nationalId, age, gender, birthGovernorate,
  phonePrimary, phoneSecondary, address, centerId, villageId, rowVersion`. `age`/`gender`/`birthGovernorate`
  are always server-derived from the national ID — never client-editable, not present at all in any PUT
  request shape.
- `completion` (`CaseCompletionDto`): `percentage` (decimal, 0–100, 2 dp, average of per-section 0/100
  binary scores — see completion endpoint below for the section list), `isReady` (bool — true only once
  **every** counted section is at 100%).
- `workflow` (`CaseWorkflowDto`): `currentStage` (same value as `status`), `availableActions` (array of
  wire-value strings, purely a UX hint — every action endpoint independently re-validates; never trust
  this array for authorization). Wire values seen in `CaseWorkflow.ActionWireValue`: `assign`,
  `accept_assignment` (also covers "self-accept", same wire value for both `AcceptAssignment` and
  `SelfAcceptCase`), `reject_assignment`, `submit_worker_opinion`, `save_reviewer_draft`,
  `submit_reviewer_opinion`, `return_to_worker`, `approve`, `reject`, `return_for_completion`.
  Ownership-shaped actions (`accept_assignment`, `reject_assignment`, `submit_worker_opinion`) are hidden
  from this array entirely unless the caller is the actual assignee — even though the action might be
  technically valid for the role/status combination.

**Errors:**
- `401 UNAUTHORIZED`
- `404 CASE_NOT_FOUND` — nonexistent id (enumeration-safe: no distinction between "doesn't exist" and any historical visibility restriction, since visibility is now global).

**rowVersion/concurrency:** N/A itself (GET); this response is the canonical **source** of both `rowVersion` (case) and `beneficiary.rowVersion` for subsequent PUTs.
**Idempotency-Key:** none.

---

#### GET /api/v1/cases/{id}/completion

Readiness/completion check, independent of the full detail payload — lets a client check before attempting submission.

**Permission:** `view_cases`

**Path params:** `id` (Guid, required).

**Success response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "sections": [
      { "key": "beneficiary", "percentage": 100.0 },
      { "key": "family_members", "percentage": 0.0 },
      { "key": "housing", "percentage": 100.0 },
      { "key": "utilities", "percentage": 0.0 },
      { "key": "agriculture", "percentage": 0.0 },
      { "key": "financial", "percentage": 0.0 },
      { "key": "initial_needs", "percentage": 0.0 },
      { "key": "classification", "percentage": 0.0 },
      { "key": "assessed_needs", "percentage": 0.0 }
    ],
    "overallPercentage": 22.22,
    "isReady": false
  },
  "message": null
}
```
`CaseCompletionResult(Sections, OverallPercentage, IsReady)`. Each section is strictly binary: **0%** if
never saved, **100%** once saved at least once (no per-field weighting — the calculator's own doc
explicitly states the real per-field frontend weighting formula is unknown/unavailable and this is a
documented simplification, not a guess). `overallPercentage` = plain average of the 9 section
percentages, rounded to 2 dp (away-from-zero). `isReady` = true only when **all 9** sections are 100%.
Note the exact 9-key section inventory: `beneficiary` (always counted as visited — created atomically
with the case), `family_members`, `housing`, `utilities`, `agriculture`, `financial`, `initial_needs`,
`classification`, `assessed_needs`. Attachments/support/opinion are **not** counted (out of scope through this phase).

**Known limitation (worth surfacing in docs):** for list-type sections (family members, utilities,
initial/assessed needs), "visited" is row existence. A user who genuinely leaves a list section empty
(e.g., truly zero dependents) is indistinguishable from one who never opened it — both read as 0%. This
is a documented, accepted limitation, not a bug.

**Errors:**
- `401 UNAUTHORIZED`
- `404 CASE_NOT_FOUND`

**rowVersion/concurrency:** N/A.
**Idempotency-Key:** none.

---

#### GET /api/v1/cases/{id}/family-members

Read-only fetch of family members, including freshly computed (not stored) age/education-stage fields.

**Permission:** `view_cases` (not `edit_case` — any role that can see the case can read this).

**Path params:** `id` (Guid, required).

**Success response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "members": [
      {
        "id": "c1a2...",
        "name": "طفل الأسرة",
        "relation": "ابن",
        "nationalId": "32006152200011",
        "age": null,
        "gender": null,
        "isStudent": true,
        "educationStage": null,
        "grade": null,
        "university": null,
        "education": null,
        "job": null,
        "monthlyIncome": null,
        "takafulBeneficiary": false,
        "takafulAmount": null,
        "notes": null,
        "sortOrder": 1,
        "computedCurrentAge": 6,
        "computedCurrentEducationStage": "primary_1"
      }
    ],
    "caseRowVersion": 3
  },
  "message": null
}
```
`FamilyMemberResult` fields (exact order): `id, name, relation, nationalId, age, gender, isStudent,
educationStage, grade, university, education, job, monthlyIncome, takafulBeneficiary, takafulAmount,
notes, sortOrder, computedCurrentAge, computedCurrentEducationStage`.

- `computedCurrentAge`/`computedCurrentEducationStage` are **new, read-only, computed fresh on every
  read** — never stored, never written by any command. Non-null **only** when the member has a
  `nationalId` to decode a birth date from; otherwise both are `null` and the stored `age`/`grade`/
  `educationStage` remain authoritative. Education-stage codes are stable wire values like `kg1`, `kg2`,
  `primary_1`…`primary_6`, `prep_1`…`prep_3`, `secondary_1`…`secondary_3` — the KG1 admission cutoff is 1
  October (Egypt MOE rule), and members aged 18+ at cutoff get `null` (calculator only speaks to K-12).
- `caseRowVersion` here is the **Case's** row version (the same value as the top-level `rowVersion` on
  `GET /cases/{id}`), used as `caseRowVersion` in `PUT /family-members`.

**Errors:**
- `401 UNAUTHORIZED`
- `404 CASE_NOT_FOUND`

**rowVersion/concurrency:** exposes `caseRowVersion` for the next `PUT /family-members`; itself read-only.
**Idempotency-Key:** none.

---

#### POST /api/v1/cases/{id}/bookmark

Add the case to the calling user's personal bookmarks ("الحالات المحفوظة").

**Permission:** `view_cases` (deliberately **not** a new/separate permission — anyone who can see the case can bookmark it, including a reviewer or an unassigned social worker who cannot edit it).

**Path params:** `id` (Guid, required). **Body:** none (send no body / `null`).

**Success response `200 OK`:**
```json
{ "success": true, "data": { "bookmarked": true }, "message": null }
```
Idempotent: bookmarking an already-bookmarked case still returns `200` with `bookmarked: true` and never creates a duplicate row (unique `(user, case)` constraint backstops this).

**Errors:**
- `401 UNAUTHORIZED`
- `404 CASE_NOT_FOUND` — nonexistent/invisible case id (IDOR-safe: bookmarking never reveals whether a hidden case id exists — though today visibility is global, this 404 still applies to a truly nonexistent id).

**rowVersion/concurrency:** none — bookmarks are not versioned; this endpoint takes no `rowVersion`/`caseRowVersion` at all.
**Idempotency-Key:** none needed; the operation is naturally idempotent by design.

**Frontend note:** bookmarking never widens edit authorization — a reviewer can bookmark a case they still cannot PUT to any section (still 403 on section PUTs).

---

#### DELETE /api/v1/cases/{id}/bookmark

Remove the case from the calling user's bookmarks.

**Permission:** `view_cases`.

**Path params:** `id` (Guid, required). **Body:** none.

**Success response `200 OK`:**
```json
{ "success": true, "data": { "bookmarked": false }, "message": null }
```
Also idempotent/safe: removing a bookmark that was never set, or removing it twice, both return `200` with `bookmarked: false` — never an error.

**Errors:**
- `401 UNAUTHORIZED`
- `404 CASE_NOT_FOUND`

**rowVersion/concurrency:** none.
**Idempotency-Key:** none needed.

---

### Case Section PUT Endpoints (common notes)

All of the following live under `PUT /api/v1/cases/{caseId}/...`, require permission **`edit_case`**, and
share the same authorization rule (`CaseEditAuthorization.AuthorizeCaseDataEditAsync`):
- `manager` and `data_entry` may edit any case's data at any stage.
- `social_worker` may edit **only** a case currently assigned to them — otherwise `403 FORBIDDEN`
  ("لا يمكن تعديل بيانات حالة غير مسندة إليك"), even though they can *see* the case (visibility is global).
- `reviewer` never reaches the handler at all — `edit_case` was removed from the reviewer role in
  `RolePermissionMatrix`, so the ASP.NET policy itself returns `403` before any handler runs (confirmed:
  reviewer is rejected defense-in-depth inside the handler too, in case that permission is ever re-added).
- Validation (FluentValidation via MediatR pipeline) runs **before** authorization for every command in
  this codebase — so a malformed body on an invisible/nonexistent case yields `422`, not `404`. (Not an
  information leak: this 422 is identical whichever the true reason.)
- 404 `CASE_NOT_FOUND` for a nonexistent/invisible case id ("الحالة غير موجودة").
- `409 CONCURRENCY_CONFLICT` on a stale row-version mismatch.

**Concurrency shape — two kinds, confirmed from `ICaseSectionRepository.cs`:**
- **Singleton sections** (beneficiary, housing, agriculture, classification): one row per case. Body
  field is `rowVersion` (beneficiary) or `rowVersion` (housing/agriculture/classification) — and for
  housing/agriculture/classification it's **nullable** (`uint?`), because the very first PUT for a case
  that has never saved this section is a plain insert with nothing to version against yet (send `null`).
  Beneficiary's `rowVersion` is **non-nullable** (`uint`) because the beneficiary row always already
  exists (created atomically with the case) — there is no "first insert" case for it.
- **List sections** (family members, utilities+appliances, initial needs, assessed needs, financial):
  wholesale replace on every PUT. Body field is **`caseRowVersion`** (non-nullable `uint`), guarded by the
  **Case's own** row version, not a per-item version — because a list has no single row to version, and a
  per-item client-tracked version would break the intended idempotency of "PUT = full replace."

No section endpoint uses/needs an `Idempotency-Key` header.

---

#### PUT /api/v1/cases/{id}/beneficiary

Update editable beneficiary fields (CS1). Never exposes/accepts national ID or any server-derived field.

**Body:**
```json
{
  "fullName": "اسم محدث",
  "phonePrimary": "01055555555",
  "phoneSecondary": null,
  "religion": "مسلم",
  "education": "جامعي",
  "maritalStatus": "أعزب",
  "healthStatus": "جيد",
  "employmentStatus": "يعمل",
  "job": "مهندس",
  "monthlyIncome": 3000,
  "takafulBeneficiary": false,
  "takafulAmount": null,
  "centerId": "00000000-0000-0000-0001-000000000001",
  "villageId": "8f2a...-village-guid",
  "address": "عنوان",
  "headRelation": "الأب",
  "rowVersion": 2
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `fullName` | string | Yes | NotEmpty, max 255 |
| `phonePrimary` | string? | No | regex `^01\d{9}$` when present (11 digits, starts with 01) — stricter than create's max-length-only rule |
| `phoneSecondary` | string? | No | same regex when present |
| `religion`, `education`, `maritalStatus`, `healthStatus`, `employmentStatus`, `job`, `address`, `headRelation` | string? | No | no explicit length rule found beyond what's implied by column types (not further validated in the command validator) |
| `monthlyIncome` | decimal? | No | ≥ 0 when present |
| `takafulBeneficiary` | bool | Yes | — |
| `takafulAmount` | decimal? | No | ≥ 0 when present |
| `centerId` | Guid? | No | if present, must exist (422 `centerId`); if both center+village present, village must belong to that center (422 `villageId`) |
| `villageId` | Guid? | No | see above |
| `rowVersion` | uint | Yes | must match beneficiary's current row version or `409 CONCURRENCY_CONFLICT` |

Note: this section does **not** validate `nationalId` at all — there is no field for it in this request; national ID stays fixed from creation.

**Success `200 OK`** (`BeneficiarySectionResult`):
```json
{
  "success": true,
  "data": {
    "fullName": "اسم محدث",
    "phonePrimary": "01055555555",
    "phoneSecondary": null,
    "religion": "مسلم",
    "education": "جامعي",
    "maritalStatus": "أعزب",
    "healthStatus": "جيد",
    "employmentStatus": "يعمل",
    "job": "مهندس",
    "monthlyIncome": 3000,
    "takafulBeneficiary": false,
    "takafulAmount": null,
    "centerId": "00000000-0000-0000-0001-000000000001",
    "villageId": "8f2a...-village-guid",
    "address": "عنوان",
    "headRelation": "الأب",
    "rowVersion": 3
  },
  "message": null
}
```
No `nationalId` field present in the response at all (confirmed via `TryGetProperty` test asserting `false`).

**Errors:** `401`, `403 FORBIDDEN` (unassigned social_worker or reviewer), `404 CASE_NOT_FOUND`, `422 VALIDATION_ERROR`, `409 CONCURRENCY_CONFLICT`.

**rowVersion note:** uses the **beneficiary's own** `rowVersion` (from `GET /cases/{id}` → `data.beneficiary.rowVersion`), NOT the case's top-level `rowVersion`.

---

#### PUT /api/v1/cases/{id}/family-members

Wholesale replace of the family-member list (CS2).

**Body:**
```json
{
  "members": [
    {
      "name": "ابن",
      "relation": "ابن",
      "nationalId": null,
      "age": 15,
      "gender": "male",
      "isStudent": true,
      "educationStage": "إعدادي",
      "grade": "الثاني",
      "university": null,
      "education": null,
      "job": null,
      "monthlyIncome": null,
      "takafulBeneficiary": false,
      "takafulAmount": null,
      "notes": null,
      "sortOrder": 1
    }
  ],
  "caseRowVersion": 3
}
```

| Field (per member) | Type | Required | Validation |
|---|---|---|---|
| `name` | string | Yes | NotEmpty, max 255 |
| `relation` | string | Yes | NotEmpty, max 30 |
| `nationalId` | string? | No | exactly length 14 when present |
| `age` | int? | No | — |
| `gender` | string? | No | — |
| `isStudent` | bool | Yes | — |
| `educationStage`, `grade`, `university` | string? | No | **server-cleared to null** whenever `isStudent=false`, regardless of what's submitted (BR-04/BR-05) |
| `education`, `job`, `notes` | string? | No | not conditionally cleared |
| `monthlyIncome` | decimal? | No | ≥ 0 when present |
| `takafulBeneficiary` | bool | Yes | — |
| `takafulAmount` | decimal? | No | ≥ 0 when present |
| `sortOrder` | int | Yes | — |
| top-level `caseRowVersion` | uint | Yes | Case's row version; mismatch → 409 |

Empty `members: []` is valid (used to represent "no dependents").

**Success `200 OK`** (`FamilyMembersSectionResult` — same shape as the GET):
```json
{
  "success": true,
  "data": {
    "members": [
      { "id": "c1a2...", "name": "ابن", "relation": "ابن", "nationalId": null, "age": 15, "gender": "male",
        "isStudent": true, "educationStage": "إعدادي", "grade": "الثاني", "university": null, "education": null,
        "job": null, "monthlyIncome": null, "takafulBeneficiary": false, "takafulAmount": null, "notes": null,
        "sortOrder": 1, "computedCurrentAge": null, "computedCurrentEducationStage": null }
    ],
    "caseRowVersion": 4
  },
  "message": null
}
```
Note `caseRowVersion` in the response is the **new** (post-write, incremented) case row version — must be used for the next PUT.

**Errors:** `401`, `403`, `404 CASE_NOT_FOUND`, `422 VALIDATION_ERROR`, `409 CONCURRENCY_CONFLICT`.

**Frontend note:** this is a true wholesale replace — omitting a previously-saved member from the array **deletes** it. Sending stale student sub-fields when flipping `isStudent` to false is harmless (server clears them), but the client should not rely on that to "clean up" its own state — read back the response.

---

#### PUT /api/v1/cases/{id}/housing

Singleton upsert (CS3). First PUT for a case creates the row.

**Body:**
```json
{
  "description": "وصف",
  "ownership": "ملك",
  "buildingType": null,
  "walls": null,
  "roof": null,
  "floor": null,
  "entrance": null,
  "roomsCount": null,
  "bathroomCondition": null,
  "sanitation": null,
  "electricity": null,
  "water": null,
  "waterMotor": false,
  "transport": null,
  "internet": false,
  "rowVersion": null
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `description` | string? | No | no explicit max in validator |
| `ownership` | string? | No | max 50 |
| `buildingType` | string? | No | max 100 |
| `walls`, `roof`, `floor`, `entrance` | string? | No | max 50 each |
| `roomsCount` | string? | No | max 50 (stored as a **string**, not an int — confirmed from the record's `string? RoomsCount`) |
| `bathroomCondition` | string? | No | no explicit max |
| `sanitation` | string? | No | max 100 |
| `electricity`, `water`, `transport` | string? | No | max 50 each |
| `waterMotor` | bool | Yes | — |
| `internet` | bool | Yes | — |
| `rowVersion` | uint? | Yes (nullable) | `null` on first PUT for this case; the row's actual version thereafter — mismatch → 409 |

There is **no** "other" free-text field anywhere in this section (the codebase's own comment explicitly flags this as a documented, deliberate non-implementation — no such column exists in the accepted schema; do not invent one).

**Success `200 OK`** (`HousingSectionResult`) — same fields plus `rowVersion` (now non-null, e.g. `1`).

**Errors:** `401`, `403`, `404`, `422`, `409 CONCURRENCY_CONFLICT` (confirmed test: sending a wrong non-null `rowVersion` like `1` against a row whose real version differs → 409; sending the correct just-returned `rowVersion` → 200).

---

#### PUT /api/v1/cases/{id}/utilities

Wholesale replace of appliances + utilities together (CS4).

**Body:**
```json
{
  "appliances": [
    { "applianceKey": "fridge", "isPresent": true }
  ],
  "utilities": [
    { "name": "كهرباء", "isAvailable": true, "condition": "جيدة", "sourceOrMeter": "عداد رقم 123", "notes": null }
  ],
  "caseRowVersion": 3
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `appliances[].applianceKey` | string | Yes | NotEmpty, max 30; **no duplicate keys** within the same request (422 "لا يمكن تكرار نفس الجهاز أكثر من مرة") |
| `appliances[].isPresent` | bool | Yes | — |
| `utilities[].name` | string | Yes | NotEmpty, max 50; **no duplicate names** in the same request (422 "لا يمكن تكرار نفس المرفق أكثر من مرة") |
| `utilities[].isAvailable` | bool | Yes | — |
| `utilities[].condition` | string? | No | max 100 |
| `utilities[].sourceOrMeter` | string? | No | max 100 |
| `utilities[].notes` | string? | No | no explicit max |
| `caseRowVersion` | uint | Yes | — |

**Success `200 OK`** (`UtilitiesSectionResult`): `{ appliances: [...], utilities: [...], caseRowVersion }`.

**Errors:** `401`, `403`, `404`, `422 VALIDATION_ERROR` (including duplicate-key case — confirmed test), `409 CONCURRENCY_CONFLICT`.

---

#### PUT /api/v1/cases/{id}/agriculture

Singleton upsert (CS5) with server-side conditional field clearing — the most conditional-heavy section.

**Body:**
```json
{
  "hasLand": "yes",
  "landAreaFeddan": 3,
  "landType": "تمليك",
  "landRentAmount": null,
  "annualLandIncome": 5000,
  "cropType": "قمح",
  "hasLivestock": "yes",
  "selectedLivestock": ["cows", "other"],
  "livestockOther": "دواجن",
  "livestockDetails": "10 رؤوس",
  "notes": null,
  "visited": true,
  "rowVersion": null
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `hasLand` | string | Yes | one of `unanswered, yes, no` (422 otherwise) |
| `landAreaFeddan` | decimal? | No | ≥ 0 |
| `landType` | string? | No | one of the two literal Arabic strings `تمليك` (ownership) or `إيجار` (rent); no other value allowed |
| `landRentAmount` | decimal? | No | ≥ 0 |
| `annualLandIncome` | decimal? | No | ≥ 0 |
| `cropType` | string? | No | — |
| `hasLivestock` | string | Yes | one of `unanswered, yes, no` |
| `selectedLivestock` | string[]? | No | free-form keys; special key `"other"` (case-insensitive) triggers `livestockOther` requirement |
| `livestockOther` | string? | **Conditionally required** | required (NotEmpty) only when `selectedLivestock` contains `"other"` (case-insensitive) — 422 "يجب تحديد تفاصيل الماشية عند اختيار 'أخرى'" |
| `livestockDetails` | string? | No | — |
| `notes` | string? | No | — |
| `visited` | bool | Yes | — |
| `rowVersion` | uint? | Yes (nullable) | `null` on first save |

**Confirmed server-side field-clearing (matches "known context," field names verified exact):**
- `hasLand != "yes"` → server clears `landAreaFeddan`, `landType`, `landRentAmount`, `annualLandIncome`, `cropType` to `null`, **regardless of what the client sent** for them.
- `landType == "إيجار"` (rent) → `annualLandIncome` cleared to null; only `landRentAmount` kept.
- `landType == "تمليك"` (ownership) → `landRentAmount` cleared to null; only `annualLandIncome` kept.
- `hasLivestock != "yes"` → `selectedLivestockJson`/response `selectedLivestock`-equivalent, `livestockOther`, `livestockDetails` all cleared to null.
- Even when `hasLivestock == "yes"`, `livestockOther` is cleared to null unless `"other"` is actually among `selectedLivestock`.

**Success `200 OK`** (`AgricultureSectionResult`):
```json
{
  "success": true,
  "data": {
    "hasLand": "yes",
    "landAreaFeddan": 3,
    "landType": "تمليك",
    "landRentAmount": null,
    "annualLandIncome": 5000,
    "cropType": "قمح",
    "hasLivestock": "yes",
    "selectedLivestockJson": "[\"cows\",\"other\"]",
    "livestockOther": "دواجن",
    "livestockDetails": "10 رؤوس",
    "notes": null,
    "visited": true,
    "rowVersion": 1
  },
  "message": null
}
```
Note: the response field is literally `selectedLivestockJson` (a raw JSON-encoded string of the array), **not** a `selectedLivestock` array — confirmed from `AgricultureSectionResult`'s record definition. This is an inconsistency between the PUT request shape (`selectedLivestock: string[]`) and the read shape (`selectedLivestockJson: string`) — worth flagging to frontend devs explicitly as a gotcha.

**Errors:** `401`, `403`, `404`, `422 VALIDATION_ERROR` (invalid `hasLand`/`hasLivestock`/`landType`, missing conditional `livestockOther`), `409 CONCURRENCY_CONFLICT`.

**Frontend note:** the response's `selectedLivestockJson` must be JSON-parsed client-side to get the array back; it is not pre-parsed by the API.

---

#### PUT /api/v1/cases/{id}/initial-needs

Wholesale replace (CS7) — what the beneficiary initially requested, kept strictly separate from CS9 assessed needs.

**Body:**
```json
{
  "needs": [
    { "needType": "غذائي", "needCategory": "طعام", "description": "احتياج طعام شهري", "priorityLevel": "high", "details": null, "notes": null }
  ],
  "caseRowVersion": 3
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `needType` | string | Yes | NotEmpty, max 50 |
| `needCategory` | string? | No | max 50 |
| `description` | string? | No | — |
| `priorityLevel` | string | Yes | NotEmpty, max 30 (no fixed enum list enforced in this validator, unlike case-level `priority`) |
| `details`, `notes` | string? | No | — |
| `caseRowVersion` | uint | Yes | — |

**Success `200 OK`** (`InitialNeedsSectionResult`): `{ needs: [{ id, needType, needCategory, description, priorityLevel, details, notes }], caseRowVersion }`.

**Errors:** `401`, `403`, `404`, `422`, `409`.

---

#### PUT /api/v1/cases/{id}/classification

Singleton upsert (CS8) — social classification, multi-select main classification stored as JSONB.

**Body:**
```json
{
  "mainClassifications": ["فقر", "إعاقة"],
  "subClassification": "شديد الفقر",
  "needLevel": "high",
  "priorityLevel": "high",
  "vulnerabilityLevel": "medium",
  "notes": null,
  "rowVersion": null
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `mainClassifications` | string[] | Yes | NotEmpty (at least one) — 422 "يجب اختيار تصنيف رئيسي واحد على الأقل" |
| `subClassification` | string? | No | max 100 |
| `needLevel` | string | Yes | NotEmpty, max 30 (no fixed enum enforced) |
| `priorityLevel` | string | Yes | NotEmpty, max 30 |
| `vulnerabilityLevel` | string? | No | max 30 |
| `notes` | string? | No | — |
| `rowVersion` | uint? | Yes (nullable) | `null` on first save |

**Success `200 OK`** (`ClassificationSectionResult`):
```json
{
  "success": true,
  "data": {
    "mainClassificationsJson": "[\"فقر\",\"إعاقة\"]",
    "subClassification": "شديد الفقر",
    "needLevel": "high",
    "priorityLevel": "high",
    "vulnerabilityLevel": "medium",
    "notes": null,
    "rowVersion": 1
  },
  "message": null
}
```
Same request/response asymmetry as agriculture: request field is `mainClassifications` (array), response field is `mainClassificationsJson` (JSON string) — client must parse it.

**Errors:** `401`, `403`, `404`, `422 VALIDATION_ERROR` (empty `mainClassifications`), `409`.

---

#### PUT /api/v1/cases/{id}/assessed-needs

Wholesale replace (CS9) — what the assessment determined, kept strictly separate from CS7 initial needs.

**Body:**
```json
{
  "needs": [
    { "needType": "غذائي", "category": "طعام", "description": "تم تقييم الاحتياج", "priorityLevel": "high", "reason": "لا يوجد دخل كافٍ", "source": "field_visit", "status": "pending", "notes": null }
  ],
  "caseRowVersion": 3
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `needType` | string | Yes | NotEmpty, max 50 |
| `category` | string? | No | max 50 |
| `description` | string? | No | — |
| `priorityLevel` | string | Yes | NotEmpty, max 30 |
| `reason` | string? | No | — |
| `source` | string | Yes | NotEmpty, max 50 (no fixed enum enforced in validator — example value above is illustrative, not confirmed as a canonical enum) |
| `status` | string | Yes | NotEmpty, max 30 (same caveat — no fixed enum enforced here) |
| `notes` | string? | No | — |
| `caseRowVersion` | uint | Yes | — |

**Success `200 OK`** (`AssessedNeedsSectionResult`): `{ needs: [{ id, needType, category, description, priorityLevel, reason, source, status, notes }], caseRowVersion }`.

**Errors:** `401`, `403`, `404`, `422`, `409`.

**Unconfirmed:** no fixed allow-list for `source`/`status` values was found in the validator — do not invent an enum for these; treat as free-form strings validated only by max length + NotEmpty until a canonical list is found elsewhere (e.g. dropdown config, out of scope for this file).

---

#### PUT /api/v1/cases/{id}/financial

Replace the case's **manual** income/expense items only (CS6); auto-linked items are always server-recomputed.

**Body:**
```json
{
  "incomeItems": [
    { "label": "دخل إضافي", "amount": 500, "period": "شهري" }
  ],
  "expenseItems": [
    { "category": "الأكل والشرب", "amount": 800, "period": "شهري" },
    { "category": "المصروفات الدراسية", "amount": 300, "period": "شهري" },
    { "category": "الكهرباء، المياه، الغاز", "amount": 200, "period": "شهري" },
    { "category": "الإيجار", "amount": 0, "period": "شهري" },
    { "category": "القسط", "amount": 0, "period": "شهري" }
  ],
  "caseRowVersion": 3
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `incomeItems[].label` | string | Yes | NotEmpty, max 100 |
| `incomeItems[].amount` | decimal | Yes | ≥ 0 |
| `incomeItems[].period` | string? | No | max 20 |
| `expenseItems` | array | Yes | **must be exactly the 5 fixed categories, no more/fewer/other** — 422 "يجب إدخال جميع بنود المصروفات الثابتة الخمسة، ولا يمكن إضافة تصنيفات أخرى" if the submitted category set (as a hash-set) doesn't exactly equal the fixed set |
| `expenseItems[].category` | string | Yes | must be one of the 5 exact literal Arabic strings below |
| `expenseItems[].amount` | decimal | Yes | ≥ 0 |
| `expenseItems[].period` | string? | No | max 20 |
| `caseRowVersion` | uint | Yes | — |

**The exact 5 fixed expense category strings (`FixedExpenseCategories.All`, verbatim, order as declared):**
1. `"الأكل والشرب"` (Food and drink)
2. `"المصروفات الدراسية"` (School expenses)
3. `"الكهرباء، المياه، الغاز"` (Electricity, water, gas)
4. `"الإيجار"` (Rent)
5. `"القسط"` (Installment)

A 6th expense line, **"إيجار الأراضي الزراعية"** (agricultural land rental), is auto-computed/server-only and must never be submitted by the client — it is not one of the 5 allowed categories and will fail the exact-set-match rule if included.

**Auto-linked items — never client-submitted, always recomputed server-side on every write to this or related sections (beneficiary/agriculture/family-members):**
- **دخل رب الأسرة** (head-of-household income) = `Beneficiary.MonthlyIncome` (0 if null).
- **تكافل وكرامة** (Takaful) = beneficiary's `TakafulAmount` (if `TakafulBeneficiary`) + sum of every family member's `TakafulAmount` (if that member's own `TakafulBeneficiary` is true).
- **دخل الأرض الزراعية** (land income, INCOME item) — only when `HasLand == "yes"` and `LandType == "تمليك"`: `AnnualLandIncome / 12`, rounded to 2 dp (away-from-zero). This is the only place a period is annual→monthly-converted.
- **إيجار الأراضي الزراعية** (land rent, EXPENSE item) — only when `HasLand == "yes"` and `LandType == "إيجار"`: `LandRentAmount` as-is, unmodified.
- **معاش** (pension) — explicitly **NOT implemented**; no pension field exists anywhere in the schema. Documented gap, not a bug.
- **Debts total** — explicitly **NOT implemented**; no debt item type exists in the schema (`FinancialItemType` is Income/Expense only).

**Success `200 OK`** (`FinancialSectionResult`):
```json
{
  "success": true,
  "data": {
    "incomeItems": [
      { "label": "دخل رب الأسرة", "amount": 3000, "period": "شهري", "isAuto": true, "source": "beneficiary", "isFixed": false },
      { "label": "تكافل وكرامة", "amount": 0, "period": "شهري", "isAuto": true, "source": "beneficiary+family", "isFixed": false },
      { "label": "دخل الأرض الزراعية", "amount": 416.67, "period": "شهري", "isAuto": true, "source": "agriculture", "isFixed": false },
      { "label": "دخل إضافي", "amount": 500, "period": "شهري", "isAuto": false, "source": null, "isFixed": false }
    ],
    "expenseItems": [
      { "label": "إيجار الأراضي الزراعية", "amount": 0, "period": "شهري", "isAuto": true, "source": "agriculture", "isFixed": false },
      { "label": "الأكل والشرب", "amount": 800, "period": "شهري", "isAuto": false, "source": null, "isFixed": true },
      { "label": "المصروفات الدراسية", "amount": 300, "period": "شهري", "isAuto": false, "source": null, "isFixed": true },
      { "label": "الكهرباء، المياه، الغاز", "amount": 200, "period": "شهري", "isAuto": false, "source": null, "isFixed": true },
      { "label": "الإيجار", "amount": 0, "period": "شهري", "isAuto": false, "source": null, "isFixed": true },
      { "label": "القسط", "amount": 0, "period": "شهري", "isAuto": false, "source": null, "isFixed": true }
    ],
    "totalIncome": 3916.67,
    "totalExpenses": 1300,
    "netBalance": 2616.67,
    "incomePerMember": 1308.335,
    "classification": "relatively_stable",
    "caseRowVersion": 4
  },
  "message": null
}
```
Note `FinancialItemView` field names in each item: `label, amount, period, isAuto, source, isFixed` — the manual expense items come back with `isFixed: true`, manual income items with `isFixed: false`; auto items always have `source` populated (`"beneficiary"`, `"beneficiary+family"`, or `"agriculture"`), manual items have `source: null`.

`incomePerMember` = `netBalance / (dependentFamilyMemberCount + 1)`, rounded to 2 dp away-from-zero — the "+1" includes the head of household, a documented resolved ambiguity (the source doc didn't specify whether the head counts).

`classification` values: `"severe_deficit"` (netBalance < 0), `"critical_subsistence"` (0 ≤ netBalance ≤ 500), `"relatively_stable"` (netBalance > 500). The `500` threshold is `CriticalSubsistenceUpperBound`, a hard-coded constant matching BUSINESS_LOGIC.md BR-03's documented value.

**Errors:**
- `401`, `403`, `404`
- `422 VALIDATION_ERROR` — wrong/missing/extra expense categories, negative amounts, missing label.
- `409 CONCURRENCY_CONFLICT` — including the cross-section case: editing beneficiary/agriculture/family-members recomputes and **persists** the financial summary and **advances the Case's `rowVersion`**, so a stale `caseRowVersion` submitted to `PUT /financial` after such a cross-section edit correctly 409s, even though the client never touched `/financial` itself in between. This is a genuine, intentional behavior, not a bug — flag it to frontend devs as a real "your cached rowVersion silently went stale" scenario.

**Frontend note:** always re-fetch `rowVersion`/`caseRowVersion` from `GET /cases/{id}` (or the previous section response) immediately before this PUT, since edits to *other* sections (beneficiary income, agriculture land data, family Takaful flags) can bump the case's row version behind the scenes via the recompute.

---

## 20. Endpoint Details — Workflow Transitions, Field Visits, Support

Full per-endpoint detail for the 8 `Idempotency-Key`-bearing workflow transitions and the 3 field-visit/verification routes (§11's core screens) plus the 2 case-support routes. The routes this app's `social_worker` role can actually call are `accept`, `reject-assignment`, `opinions/worker`, the 3 field-visit/verification routes, and `GET /cases/{id}/support` — the rest (`assign`, `opinions/reviewer`, `return-to-worker`, `opinions/manager`, `return-for-completion`, `PUT approved-support`) are documented for completeness/shared models and always return `403` for this app's role.


All responses use the fixed envelope:
- Success: `{ "success": true, "data": {...}, "message": null }`
- Error: `{ "success": false, "error": { "code": "...", "message": "...", "details": { "field": ["..."] } } }` (`details` omitted, not `{}`, when there is nothing field-specific to report)

---

### 1. POST /api/v1/cases/{id}/assign

**Path params:** `id` (case guid, route param name internally `caseId`)
**Headers:** `Idempotency-Key: <uuid>` REQUIRED (missing/malformed → `400 IDEMPOTENCY_KEY_REQUIRED`)
**Permission:** `create_case`. Allowed actor roles per the workflow engine's own role table (defense-in-depth, not the actual gate): `data_entry`, `manager`, `reviewer`.
**Valid from statuses:** `draft`, `pending_assignment` → `assigned` (one unified action covering both of BACKEND_DOCUMENTATION.md §11.1's "إرسال لأخصائي" and "إسناد لأخصائي" rows).

### Request body
```json
{ "workerId": "5b1e...-guid", "caseRowVersion": 3 }
```
| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| workerId | guid | yes | `NotEmpty`; must resolve to an active `social_worker` (checked via `IUserLookupService.IsActiveSocialWorkerAsync`) — else `422 VALIDATION_ERROR` with `{"workerId":["الأخصائي غير موجود أو غير نشط"]}` | |
| caseRowVersion | uint | yes | must match current case `xmin` | concurrency anchor |

### Success response (200)
```json
{ "success": true, "data": { "status": "assigned", "caseRowVersion": 4 }, "message": null }
```
Shape: `CaseWorkflowActionResult(string Status, uint CaseRowVersion)`.

### Errors specific to this route
- `422 VALIDATION_ERROR` — `workerId` not an active social worker.
- `404 CASE_NOT_FOUND` — case doesn't exist or is invisible to caller (an invisible case is deliberately indistinguishable from nonexistent — §9.1).
- `422 INVALID_STATUS_TRANSITION` — case is currently in any status other than `draft`/`pending_assignment` (e.g. already `assigned`, `in_research`, `approved`, etc).
- `409 CONCURRENCY_CONFLICT` — stale `caseRowVersion`.
- `403 FORBIDDEN` — actor's role is not in the workflow engine's allow-list for `Assign` (defense-in-depth; the ASP.NET `create_case` policy is the real gate and returns 403 before the handler even runs for a role that lacks it).
- `400 IDEMPOTENCY_KEY_REQUIRED` — header missing/malformed.

### Frontend note
Any authenticated role holding `create_case` (currently `data_entry`, `manager`) can assign — visibility is global per the "Nahda Backend Integration Decisions" doc, so any `data_entry` user can act on any pre-shared-state case, not just its creator (integration test `A_Case_Is_Visible_And_Actionable_By_Any_DataEntry_User_Before_It_Reaches_A_Shared_State`).

---

### 2. POST /api/v1/cases/{id}/accept

**Headers:** `Idempotency-Key` REQUIRED.
**Permission:** `accept_reject_assignment`.
**Two behaviors behind one route** (server decides, never a client flag):
1. **AcceptAssignment** — case is `assigned` and caller is the assignee → `in_research`.
2. **SelfAcceptCase** (Rule #9) — case is `pending_assignment` with NO assignee (`AssignedToUserId == null`) → any `social_worker` may accept it, becoming the assignee in the same step → `in_research`.

Both share the SAME wire action name (`accept_assignment`) in `availableActions`; the distinction is a server-side implementation detail never surfaced to the client.

**Concurrency:** both paths take a Postgres row lock (`SELECT ... FOR UPDATE`) before checking state — a plain optimistic check on `caseRowVersion` is insufficient here because two racing self-accepts can both read the same "unassigned" state before either commits. Exactly one of two concurrent accept attempts on the same unassigned case succeeds; the other gets `409` or `422` (never a corrupted double-assignment) — proven in `Two_Social_Workers_Racing_To_Self_Accept_The_Same_Unassigned_Case_Only_One_Wins`.

### Request body
```json
{ "caseRowVersion": 4 }
```
| Field | Type | Required | Validation |
|---|---|---|---|
| caseRowVersion | uint | yes | concurrency anchor |

No FluentValidation validator is registered for this command (no extra field rules beyond the required uint).

### Success response (200)
```json
{ "success": true, "data": { "status": "in_research", "caseRowVersion": 5 }, "message": null }
```

### Errors specific to this route
- `404 CASE_NOT_FOUND` — case doesn't exist / invisible.
- `422 INVALID_STATUS_TRANSITION` — case is neither `assigned` (for AcceptAssignment) nor unassigned-`pending_assignment` (for SelfAccept) — e.g. attempting to accept a `draft` or `in_research` case.
- `403 FORBIDDEN` — case IS assigned but to someone else (`RequireAssignee` throws `ForbiddenAppException("هذه الحالة غير مسندة إليك")`) — NOT a 404; the assignment's existence is not hidden from a stranger social_worker (test `A_Different_Social_Worker_Cannot_Accept_Or_Reject_Someone_Elses_Assignment` and `Accepting_A_Case_Assigned_To_Somebody_Else_Is_Still_Rejected`).
- `409 CONCURRENCY_CONFLICT` — stale `caseRowVersion`, OR the loser of a self-accept race (row lock serializes; loser reads a rowVersion that's already stale by the time it acquires the lock).
- `400 IDEMPOTENCY_KEY_REQUIRED`.

### Frontend note
Confirmed contradiction risk vs the "known context": there is no dedicated 422 `OPINION_SLOT_LOCKED`/other special code here — a self-accept race loser gets plain `409 CONCURRENCY_CONFLICT` or `422 INVALID_STATUS_TRANSITION` depending on timing (both are asserted as acceptable outcomes in the test, not one specific code — treat this as "either" in docs, not a single deterministic code).

---

### 3. POST /api/v1/cases/{id}/reject-assignment

**Headers:** `Idempotency-Key` REQUIRED.
**Permission:** `accept_reject_assignment`.
**Valid from:** `assigned` → `pending_assignment` (clears `AssignedToUserId`).
**Actor must be the current assignee** (`RequireAssignee`).

### Request body
```json
{ "reason": "غير متاح حاليًا", "caseRowVersion": 4 }
```
| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| reason | string? | **optional** | `MaximumLength(1000)` | §11.1's side-effect column does not mark a reason mandatory here — contrast with `return-to-worker` which explicitly requires one. Documented explicitly as optional, not invented. |
| caseRowVersion | uint | yes | concurrency anchor | |

### Success response (200)
```json
{ "success": true, "data": { "status": "pending_assignment", "caseRowVersion": 5 }, "message": null }
```

### Errors specific to this route
- `404 CASE_NOT_FOUND`.
- `422 INVALID_STATUS_TRANSITION` — case not currently `assigned`.
- `403 FORBIDDEN` — caller is not the assignee.
- `409 CONCURRENCY_CONFLICT`.
- `422 VALIDATION_ERROR` — `reason` over 1000 chars.
- `400 IDEMPOTENCY_KEY_REQUIRED`.

### Frontend note
A rejected assignment leaves the case `pending_assignment` with NO assignee — this is exactly the state that unlocks the self-accept path on `/accept` for a different worker (see route 2 and `CreateUnassignedPendingCaseAsync` in tests).

---

### 4. POST /api/v1/cases/{id}/opinions/worker

**Headers:** `Idempotency-Key` REQUIRED.
**Permission:** `write_worker_opinion`.
**Valid from:** `in_research` OR `returned_to_worker` → `pending_review`.
**Actor must be the assignee** (`RequireAssignee`).
**Two prerequisites specific to this route:**
1. **Mobile-only.** `ClientType` (from JWT `client_type` claim, defaults `"web"`) must be `"mobile"`, else `403 SOCIAL_WORKER_WEB_BLOCKED`.
2. **Completion gate.** Case completion (via `CaseCompletionCalculator`, server-computed from actual section data — never a client-supplied `isReady`) must be 100% before a worker opinion may be submitted, else `422 VALIDATION_ERROR` with `{"completion":["لا يمكن إرسال الرأي قبل استيفاء جميع أقسام الحالة"]}`.

### Request body
```json
{ "decision": "accepted", "notes": "تمت الزيارة الميدانية", "caseRowVersion": 6 }
```
| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| decision | string | yes | must be `"accepted"` or `"rejected"` — else `422 VALIDATION_ERROR` `{"decision":["قيمة القرار غير صحيحة"]}` | wire values only these two |
| notes | string? | no | `MaximumLength(2000)` | |
| caseRowVersion | uint | yes | concurrency anchor | |

### Success response (200)
```json
{
  "success": true,
  "data": {
    "status": "pending_review",
    "caseRowVersion": 7,
    "opinionId": "guid",
    "decision": "accepted",
    "notes": "تمت الزيارة الميدانية",
    "isSubmitted": true
  },
  "message": null
}
```
Shape: `CaseOpinionActionResult(string Status, uint CaseRowVersion, Guid OpinionId, string Decision, string? Notes, bool IsSubmitted)` — this shape is shared by opinions/worker, opinions/reviewer, return-to-worker, and opinions/manager.

### Errors specific to this route
- `404 CASE_NOT_FOUND`.
- `403 FORBIDDEN` — caller isn't the assignee.
- `403 SOCIAL_WORKER_WEB_BLOCKED` — `client_type != "mobile"` (e.g. a `data_entry`/other role attempting this route also gets rejected earlier by the `write_worker_opinion` permission policy with plain `403 FORBIDDEN`, since only `social_worker` holds that permission — the web-blocked code is specifically for a legitimate social_worker token whose client_type claim isn't mobile).
- `422 VALIDATION_ERROR` — invalid `decision` value, OR case completion < 100% (`{"completion":[...]}`).
- `422 INVALID_STATUS_TRANSITION` — case not `in_research`/`returned_to_worker`.
- `422 OPINION_SLOT_LOCKED` — the worker opinion slot is already submitted/finalized (defense-in-depth; structurally the transition-rule check above should already have blocked re-submission in the normal flow — `UpsertOpinionAsync` throws this if `opinion.IsSubmitted` is already true for `OpinionSlot.Worker`).
- `409 CONCURRENCY_CONFLICT`.
- `400 IDEMPOTENCY_KEY_REQUIRED`.

### Frontend note
The 100%-completion gate is the most likely real-world 422 here (test `SubmitWorkerOpinion_Is_Blocked_Until_Completion_Reaches_100_Percent`). Show the frontend's own completion percentage indicator before allowing the submit button, but always let the backend be the source of truth (do not attempt to replicate `CaseCompletionCalculator` client-side to gate the button; use it only to disable/hint).

---

### 5. POST /api/v1/cases/{id}/opinions/reviewer

**Headers:** `Idempotency-Key` REQUIRED.
**Permission:** `write_reviewer_opinion`.
**Two Master-Plan commands, one route**, selected by `isSubmitted`:
- `isSubmitted = false` → `SaveReviewerDraft`: valid from `pending_review`, does **NOT** change case status (stays `pending_review`), just writes/updates the reviewer's opinion slot with `IsSubmitted = false`.
- `isSubmitted = true` → `SubmitReviewerOpinion`: valid from `pending_review` → `pending_approval`.

**Prerequisite:** the worker's opinion must already exist for this case (`MISSING_WORKER_OPINION` guard) — structurally this should be unreachable via the normal chain (only `SubmitWorkerOpinion` can even put the case into `pending_review`), kept purely as defense-in-depth (proven directly in test `Reviewer_Cannot_Submit_An_Opinion_Before_The_Worker_Opinion_Exists_DefenseInDepth`, which actually hits `INVALID_STATUS_TRANSITION` first because the case is still `draft` in that test — i.e. in practice you will see `INVALID_STATUS_TRANSITION` before you'd ever see `MISSING_WORKER_OPINION` through the real endpoint chain).

### Request body
```json
{ "decision": "accepted", "notes": "موافق", "isSubmitted": true, "caseRowVersion": 7 }
```
| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| decision | string | yes | must be `"accepted"` or `"rejected"` | |
| notes | string? | no | `MaximumLength(2000)` | |
| isSubmitted | bool | yes | — | `false` = draft save, `true` = final submit |
| caseRowVersion | uint | yes | concurrency anchor | |

### Success response (200)
Same `CaseOpinionActionResult` shape as route 4. `status` is `"pending_review"` (unchanged) when `isSubmitted=false`, `"pending_approval"` when `true`.

### Errors specific to this route
- `404 CASE_NOT_FOUND`.
- `403 FORBIDDEN` — role isn't `reviewer`.
- `422 VALIDATION_ERROR` — invalid `decision`.
- `422 INVALID_STATUS_TRANSITION` — case not currently `pending_review` (both draft-save and submit require this FromStatus).
- `422 OPINION_SLOT_LOCKED` — reviewer slot already submitted (`IsSubmitted=true` already) and a further write (draft or submit) is attempted.
- `422 MISSING_WORKER_OPINION` — defense-in-depth only, practically unreachable because `INVALID_STATUS_TRANSITION` fires first in every real path.
- `409 CONCURRENCY_CONFLICT`.
- `400 IDEMPOTENCY_KEY_REQUIRED`.

### Frontend note
A reviewer can save a draft (`isSubmitted:false`) repeatedly while the case stays in `pending_review` — each draft save re-validates `decision`/`notes` but does not advance the workflow. Only the `isSubmitted:true` call moves the case to `pending_approval` and, per `OPINION_SLOT_LOCKED`, closes further writes to that slot.

---

### 6. POST /api/v1/cases/{id}/return-to-worker

**Headers:** `Idempotency-Key` REQUIRED.
**Permission:** `write_reviewer_opinion`.
**Valid from:** `pending_review` → `returned_to_worker`.
Writes into the REVIEWER's opinion slot with a special `OpinionDecision.ReturnedToWorker` decision value (wire value `"returned_to_worker"`), reason stored as both the timeline note and `opinion.ReturnReason`.

### Request body
```json
{ "reason": "برجاء استكمال بيانات السكن", "caseRowVersion": 7 }
```
| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| reason | string | **yes, mandatory** | `NotEmpty` (`"سبب الإعادة إلزامي"`), `MaximumLength(1000)` | The ONE row in the whole transition table the source marks "سبب إجباري" explicitly — contrast with reject-assignment's optional reason. Empty string (`""`) is rejected (test `ReturnToWorker_Requires_A_NonEmpty_Reason`). |
| caseRowVersion | uint | yes | concurrency anchor | |

### Success response (200)
`CaseOpinionActionResult` — `status: "returned_to_worker"`, `decision: "returned_to_worker"`, `notes` = the reason, `isSubmitted: true`.

### Errors specific to this route
- `404 CASE_NOT_FOUND`.
- `403 FORBIDDEN` — role isn't `reviewer`.
- `422 VALIDATION_ERROR` — `reason` empty or missing, or over 1000 chars.
- `422 INVALID_STATUS_TRANSITION` — case not `pending_review`.
- `409 CONCURRENCY_CONFLICT`.
- `400 IDEMPOTENCY_KEY_REQUIRED`.
- Note: `OPINION_SLOT_LOCKED` is NOT independently guarded by the transition-rule prerequisite here in the same way as reviewer-submit, because `UpsertOpinionAsync` is still called against the reviewer slot and will throw `OPINION_SLOT_LOCKED` if that slot is already submitted — but under the normal chain the FromStatuses check (`pending_review`) already prevents reaching a state where the reviewer slot could already be locked AND status still `pending_review` simultaneously, so this is defense-in-depth only, same caveat as route 5.

### Frontend note
`returned_to_worker` re-opens the field-visit window (`FieldVisitAuthorization.AllowedStatuses` includes `ReturnedToWorker`) — the worker can log new field visits and resubmit their opinion (`opinions/worker` also accepts `FromStatuses` including `ReturnedToWorker`), forming the return loop.

---

### 7. POST /api/v1/cases/{id}/opinions/manager

**Headers:** `Idempotency-Key` REQUIRED.
**Permission:** `write_manager_approval`.
**Valid from:** ANY non-terminal status (i.e. anything except `approved`/`rejected`) → `approved` or `rejected`, decided by the boolean `approve` field. This is the documented manager-override: §11.1's "أي حالة → حسم فوري (مدير)" row, resolved deliberately to let a manager decide from any state, not only `pending_approval`.
**Row-locked** (`SELECT ... FOR UPDATE`) exactly like accept, guaranteeing exactly one of two concurrent conflicting decisions on the same case succeeds (test `Two_Concurrent_Manager_Decisions_Exactly_One_Succeeds`).
**Audit distinguishes normal vs. override decisions**: if the case was actually at `pending_approval` when decided, audit action is `CASE_APPROVED`/`CASE_REJECTED`; if decided from any other non-terminal state, it's recorded as `CASE_FORCE_APPROVED`/`CASE_FORCE_REJECTED`. Same endpoint, same command — only the audit label differs, computed server-side from the state the transition actually started in (not exposed on the HTTP response itself, only in the audit trail).

### Request body
```json
{ "approve": true, "notes": "معتمد", "caseRowVersion": 8 }
```
| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| approve | bool | yes | — | `true` = Approve, `false` = Reject. Wire format confirmed as documented. |
| notes | string? | no | `MaximumLength(2000)` | |
| caseRowVersion | uint | yes | concurrency anchor | |

### Success response (200)
`CaseOpinionActionResult` — `status: "approved"` or `"rejected"`, `decision: "approved"` or presumably the rejected wire value (see note below), `isSubmitted: true`.

**Unconfirmed / minor gap:** `DecisionWireValue` in `CaseWorkflowRepository` maps `OpinionDecision.Accepted→"accepted"`, `Rejected→"rejected"`, `ReturnedToWorker→"returned_to_worker"`, `Approved→"approved"` — there is **no explicit case for a manager's `OpinionDecision.Rejected`** in that switch beyond the generic `Rejected → "rejected"` entry (shared with the worker/reviewer "rejected" opinion decision). So a manager reject response's `decision` field reads `"rejected"` — same wire string as a worker/reviewer rejecting their own opinion. This is consistent, not a bug, but worth noting: `decision` alone does not tell you WHICH slot(role) made the call — that context comes from which endpoint you called.

### Errors specific to this route
- `404 CASE_NOT_FOUND`.
- `403 FORBIDDEN` — role isn't `manager`.
- `422 VALIDATION_ERROR` — `notes` over 2000 chars.
- `422 CASE_ALREADY_APPROVED` — case's current status is already `Approved` and a further Approve/Reject is attempted (specifically checked ahead of the generic `INVALID_STATUS_TRANSITION`, only for `Approve`/`Reject` actions from `Approved`) — also doubles as replay protection (test `A_Repeated_Approve_On_An_Already_Approved_Case_Is_Rejected_Replay_Protection`).
- `422 INVALID_STATUS_TRANSITION` — case's current status is `Rejected` (the other terminal state) — note `CASE_ALREADY_APPROVED` is raised ONLY when the prior status was specifically `Approved`, not `Rejected`; a further decision attempt on an already-`Rejected` case gets the generic `INVALID_STATUS_TRANSITION` instead.
- `409 CONCURRENCY_CONFLICT` — stale rowVersion, or the loser of the two-concurrent-decision race.
- `400 IDEMPOTENCY_KEY_REQUIRED`.

### Frontend note
This is the one workflow route where `INVALID_STATUS_TRANSITION` essentially never fires for a "normal" reason except hitting `Rejected` — because the transition rule for Approve/Reject allows ANY non-terminal state as source. Do not gate the manager's Approve/Reject buttons on `availableActions`/case status the way you would for worker/reviewer actions; the backend intentionally allows an early/override decision from `draft` all the way through `pending_approval`.

---

### 8. POST /api/v1/cases/{id}/return-for-completion

**Headers:** `Idempotency-Key` REQUIRED.
**Permission:** `write_manager_approval`.
**Valid from:** `pending_approval` → `pending_review` ONLY (no manager-override here; unlike opinions/manager, this uses a normal, single-source-state transition rule).
**Effect:** clears (deletes) the REVIEWER's opinion slot row entirely, keeps the worker's opinion slot untouched — forcing the reviewer to re-review. Not a "decision", just a completion loop-back.

### Request body
```json
{ "caseRowVersion": 9 }
```
| Field | Type | Required | Validation |
|---|---|---|---|
| caseRowVersion | uint | yes | concurrency anchor |

No FluentValidation validator registered — no extra fields to validate.

### Success response (200)
```json
{ "success": true, "data": { "status": "pending_review", "caseRowVersion": 10 }, "message": null }
```
Shape: `CaseWorkflowActionResult` (NOT `CaseOpinionActionResult` — this route does not touch an opinion of its own, it deletes one).

### Errors specific to this route
- `404 CASE_NOT_FOUND`.
- `403 FORBIDDEN` — role isn't `manager`.
- `422 INVALID_STATUS_TRANSITION` — case is not currently `pending_approval` (e.g. attempting this from `pending_review`, `in_research`, or a terminal state).
- `409 CONCURRENCY_CONFLICT`.
- `400 IDEMPOTENCY_KEY_REQUIRED`.

### Frontend note
After this call, `GET /cases/{id}` will show the reviewer opinion slot as absent/null (deleted, not just unsubmitted) — the reviewer UI must treat this exactly like a case that has never been reviewed, not like a "draft to resume."

---

### 9. POST /api/v1/cases/{id}/field-visits (FV1)

**Headers:** NO `Idempotency-Key` required (Phase 11 explicitly out of scope for §12's idempotency mechanism — a duplicate POST is left to client-side dedup).
**Permission:** `write_worker_opinion` (reused deliberately — no dedicated `write_field_visit` permission exists in the closed catalogue).
**Full authorization chain (`FieldVisitAuthorization.AuthorizeAsync`), run in this order:**
1. Mobile-only — `client_type` must be `"mobile"`, else `403 SOCIAL_WORKER_WEB_BLOCKED`. Checked FIRST (caller-only property, no DB round trip needed, fails fast).
2. Case visibility (`CaseEditAuthorization.AuthorizeAsync`) — invisible/nonexistent case → `404 CASE_NOT_FOUND`.
3. Assignee-only — caller must literally be `AssignedToUserId`, else `404 CASE_NOT_FOUND` (NOT 403 — non-disclosure; a case assigned to someone else must look identical to a nonexistent one to a non-assignee worker, confirmed by test `A_Worker_Cannot_Record_A_Visit_On_Another_Workers_Case` expecting 404+`CASE_NOT_FOUND`, NOT 403).
4. Status window — case must currently be `in_research` or `returned_to_worker`, else `422 INVALID_STATUS_TRANSITION`. `assigned` is explicitly EXCLUDED (worker must have accepted first).

**Server-authoritative fields:** `caseId` from route, `socialWorkerId` from JWT — the request body has NO member for either, so a client sending `caseId`/`socialWorkerId`/`id`/`rowVersion` in the JSON body simply has nowhere to bind (structurally impossible mass assignment, proven in `Fv1_Ignores_Client_Supplied_CaseId_SocialWorkerId_And_Id`).

### Request body
```json
{
  "visitDate": "2026-09-18",
  "startTimeUtc": null,
  "endTimeUtc": null,
  "latitude": 30.0444,
  "longitude": 31.2357,
  "locationDescription": "بجوار المسجد",
  "outcome": "تمت الزيارة وتم التحقق من السكن",
  "status": null,
  "notes": "ملاحظات الزيارة",
  "description": "تم الاطلاع على السكن",
  "photoAttachmentIds": ["b3f...guid"]
}
```
| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| visitDate | date (`yyyy-MM-dd`) | yes | must be ≤ UTC-today+1 day (tolerance for timezone-ahead workers) — else `"تاريخ الزيارة لا يمكن أن يكون في المستقبل"` | |
| startTimeUtc | datetimeoffset? | no | — | |
| endTimeUtc | datetimeoffset? | no | must be ≥ `startTimeUtc` when both present | |
| latitude | double? | no | -90..90; must be finite (rejects NaN/Infinity); **all-or-nothing with longitude** — sending one without the other → `"يجب إرسال خط العرض وخط الطول معًا"` | |
| longitude | double? | no | -180..180; must be finite; paired with latitude | |
| locationDescription | string? | no | `MaximumLength(500)` | |
| outcome | string | yes | `NotEmpty`, `MaximumLength(2000)` | |
| status | string? | no | must be `"in_progress"` or `"completed"` if present | defaults server-side to `"completed"` when null |
| notes | string? | no | `MaximumLength(2000)` | |
| description | string? | no | `MaximumLength(2000)` | |
| photoAttachmentIds | guid[]? | no | ≤ 50 items, no duplicates; each id must reference an EXISTING attachment on the SAME case with Phase-10 status `complete` — else `422 VALIDATION_ERROR` naming the specific bad ids in `photoAttachmentIds` | defaults to `[]` if omitted |

### Success response (200)
```json
{
  "success": true,
  "data": {
    "id": "guid",
    "caseId": "guid",
    "visitDate": "2026-09-18",
    "startTimeUtc": null,
    "endTimeUtc": null,
    "location": { "latitude": 30.0444, "longitude": 31.2357, "description": "بجوار المسجد" },
    "outcome": "تمت الزيارة وتم التحقق من السكن",
    "status": "completed",
    "notes": "ملاحظات الزيارة",
    "description": "تم الاطلاع على السكن",
    "photoAttachmentIds": ["b3f...guid"],
    "socialWorkerId": "guid",
    "rowVersion": 1
  },
  "message": null
}
```
`location` is `null` in the response when neither lat/lon nor description was supplied (test `A_Visit_Without_Any_Location_Is_Accepted_Because_Gps_Is_Optional`).

### Errors specific to this route
- `403 SOCIAL_WORKER_WEB_BLOCKED` — non-mobile client.
- `404 CASE_NOT_FOUND` — case invisible/nonexistent, OR caller isn't the assignee (same code, non-disclosure).
- `422 INVALID_STATUS_TRANSITION` — case status outside `{in_research, returned_to_worker}` (includes `assigned` — accepted-but-not-yet — and `pending_review`/`pending_approval`/terminal states).
- `422 VALIDATION_ERROR` — any `FieldVisitInputValidator` rule failure (outcome missing, future date, bad GPS, bad status enum, too many/duplicate photo ids), OR an unlinkable photo id (message names the exact offending id(s), e.g. `"مرفقات غير صالحة أو غير مكتملة الرفع: {ids}"`) — note the message deliberately does NOT distinguish "doesn't exist" vs "wrong case" vs "not complete status", all three collapse to the same validation message for non-disclosure.
- `401 Unauthorized` — no/invalid token (standard).

### Frontend note
No `Idempotency-Key` — a double-tap "save visit" on flaky mobile connectivity creates two visit rows; the client (mobile app) is responsible for its own submit-button debounce/dedup. GPS is fully optional; if supplying it, both lat AND lon are required together — sending only one is a 422, not a silent drop.

---

### 10. PUT /api/v1/field-visits/{id} (FV2)

**Path params:** `id` = the VISIT's own guid, NOT the case id — this route carries no case id in its path at all.
**Headers:** no `Idempotency-Key` (PUT-replace is naturally idempotent).
**Permission:** `write_worker_opinion`.
**Ownership resolution order:** the visit is looked up FIRST by id; if it doesn't exist OR its `SocialWorkerId != callerId`, the response is `404 NOT_FOUND` (generic `ErrorCodes.NotFound`, not `CASE_NOT_FOUND`) — both cases are indistinguishable (test `Fv2_On_Another_Workers_Visit_Returns_404` and `Fv2_On_A_Nonexistent_Visit_Returns_The_Same_404`). Only once ownership is confirmed does the full `FieldVisitAuthorization` chain re-run against the visit's OWN `caseId` (mobile-only, visibility, assignee, status window) — so a visit on a case that has since moved out of the research window can no longer be updated either.
**`caseId` and `socialWorkerId` are never reassignable** — the update handler explicitly never touches those two fields.

### Request body
```json
{
  "visitDate": "2026-09-18",
  "startTimeUtc": null,
  "endTimeUtc": null,
  "latitude": null,
  "longitude": null,
  "locationDescription": null,
  "outcome": "نتيجة محدّثة",
  "status": "in_progress",
  "notes": null,
  "description": null,
  "photoAttachmentIds": [],
  "rowVersion": 1
}
```
Same field table as FV1 (`IFieldVisitInput`), plus:
| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| rowVersion | uint | **yes** | must match the VISIT row's own `xmin` (NOT the case's) — stale → `409 CONCURRENCY_CONFLICT` | |

### Success response (200)
Same `FieldVisitResult` shape as FV1, with a NEW (bumped) `rowVersion`.

### Errors specific to this route
- `404 NOT_FOUND` — visit doesn't exist, OR exists but belongs to a different worker (same code/message either way).
- `403 SOCIAL_WORKER_WEB_BLOCKED` — non-mobile client (checked after ownership resolves, against the visit's real case).
- `404 CASE_NOT_FOUND` — theoretically possible if the visit's underlying case became invisible, but since ownership already required matching `SocialWorkerId`, this is effectively unreachable in practice; the ownership 404 fires first for any IDOR attempt.
- `422 INVALID_STATUS_TRANSITION` — the visit's case has since left the `in_research`/`returned_to_worker` window (e.g. moved to `pending_review`) — test `A_Visit_Cannot_Be_Logged_Once_The_Case_Has_Left_The_Worker` demonstrates the equivalent on FV1; the same authorization chain applies here since FV2 re-runs it.
- `422 VALIDATION_ERROR` — same `FieldVisitInputValidator` rules as FV1, plus bad photo linkage.
- `409 CONCURRENCY_CONFLICT` — stale `rowVersion` (the VISIT's own token).

### Frontend note
Cannot move a visit to another case, cannot reassign it to another worker — `visit.CaseId`/`visit.SocialWorkerId` are deliberately never touched by `apply(visit)`. The `rowVersion` here is the VISIT's, distinct from `caseRowVersion` used everywhere else in this group — do not confuse the two when wiring optimistic-concurrency retry logic.

---

### 11. PUT /api/v1/cases/{id}/field-verification (FV3)

**Headers:** no `Idempotency-Key` (full-replace semantics make it naturally idempotent).
**Permission:** `write_worker_opinion`.
**Same authorization chain** as FV1 (`FieldVisitAuthorization`): mobile-only → case visibility → assignee-only (404 non-disclosure) → status window (`in_research`/`returned_to_worker`).
**Replace semantics:** deletes ALL existing `case_verified_fields` rows for the case and writes the submitted set, in one transaction anchored on the Case's own `rowVersion` (there is no per-row id/version — the whole set is one unit, same pattern as other Phase-7 child-collection replaces).
**Server-computed fields — the whole security point of this endpoint:** the client sends ONLY `fieldLabel`, `verifiedValue`, `differenceReason`. `originalValue` and `isDifferent` are ALWAYS computed server-side from the case's real, current data and can never be spoofed (test `Fv3_Ignores_A_Client_Supplied_IsDifferent_And_OriginalValue` sends forged `originalValue`/`isDifferent` in the body and they are silently ignored — no error, just discarded, because those fields don't even exist on `VerifiedFieldInput`).

### Request body
```json
{
  "fields": [
    { "fieldLabel": "beneficiary_address", "verifiedValue": "عنوان مختلف تمامًا", "differenceReason": "انتقلت الأسرة" }
  ],
  "caseRowVersion": 7
}
```
| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| fields[].fieldLabel | string | yes | `NotEmpty`; must be one of the closed 12-label allow-list (see below) — else `422 VALIDATION_ERROR` `"اسم الحقل غير مدعوم للتحقق الميداني"` | |
| fields[].verifiedValue | string? | no | `MaximumLength(2000)` | |
| fields[].differenceReason | string? | conditionally required | `MaximumLength(2000)`; **mandatory when the SERVER-computed diff says `isDifferent=true`** — else `422 VALIDATION_ERROR` at `fields[i].differenceReason`: `"سبب الاختلاف مطلوب عند وجود فرق بين القيمة الأصلية والقيمة المتحققة"`. Conversely if the server computes NO difference, any client-supplied reason is silently discarded (stored as null) — never an error. | |
| fields (array) | — | no (defaults `[]`) | no duplicate `fieldLabel` values in the same request — else `422 VALIDATION_ERROR` `"لا يمكن إرسال نفس الحقل أكثر من مرة"` | |
| caseRowVersion | uint | yes | anchors the Case's own `xmin` (not a per-field version) | |

**The 12 allow-listed `fieldLabel` values** (closed, compiled-in list — `VerifiableFields`, a documented judgment call since the source doesn't enumerate them):
`beneficiary_full_name`, `beneficiary_national_id`, `beneficiary_phone_primary`, `beneficiary_address`, `beneficiary_marital_status`, `beneficiary_job`, `beneficiary_monthly_income`, `housing_ownership`, `housing_building_type`, `housing_rooms_count`, `financial_total_income`, `family_members_count`.

**Diff semantic:** trim-then-exact-ordinal string comparison (case-sensitive, no culture folding — deliberate for Arabic text so no alef-variant normalization silently hides a real difference). A missing/blank original normalizes to `""`, so "was blank, worker found a value" is a real reportable difference.

### Success response (200)
```json
{
  "success": true,
  "data": {
    "fields": [
      {
        "fieldLabel": "beneficiary_address",
        "originalValue": "عنوان أصلي",
        "verifiedValue": "عنوان مختلف تمامًا",
        "isDifferent": true,
        "differenceReason": "انتقلت الأسرة"
      }
    ],
    "caseRowVersion": 8
  },
  "message": null
}
```

### Errors specific to this route
- `403 SOCIAL_WORKER_WEB_BLOCKED` — non-mobile.
- `404 CASE_NOT_FOUND` — invisible/nonexistent case, or caller not the assignee (non-disclosure — same as FV1; test `A_Worker_Cannot_Write_Field_Verification_On_Another_Workers_Case`).
- `422 INVALID_STATUS_TRANSITION` — case outside the `in_research`/`returned_to_worker` window.
- `422 VALIDATION_ERROR` — unknown `fieldLabel`, duplicate labels in one request, a difference with no reason (or reason is all-whitespace, which normalizes to null and is treated as missing — test `Fv3_Rejects_A_Difference_With_No_Reason` sends `"   "` as the reason and gets rejected).
- `409 CONCURRENCY_CONFLICT` — stale `caseRowVersion`.

### Frontend note
This is a full REPLACE, not a merge/upsert — submitting a subset of fields DROPS whatever verified-field rows existed for the labels you don't include (test `Fv3_Replaces_The_Previous_Verification_Set`). The frontend must always resend the complete current set (fetch-then-edit-then-PUT-the-whole-thing), never a delta. Also: a `differenceReason` you supply is pointless/wasted if your `verifiedValue` happens to match the original — the server discards it silently rather than erroring, so don't rely on the reason round-tripping unless the value actually differs.

---

### 12. GET /api/v1/cases/{id}/support

**Headers:** none special.
**Permission:** `view_cases` (every authenticated role).
**No workflow gating** — purely a read, works at any case status.

### Success response (200)
```json
{
  "success": true,
  "data": {
    "recommendations": [
      {
        "id": "guid",
        "supportType": "زي مدرسي",
        "supportCategory": null,
        "beneficiary": "الأسرة",
        "proposedAmount": 500.0,
        "frequency": "شهري",
        "duration": null,
        "reason": "احتياج فعلي",
        "justification": "تقرير الأخصائي",
        "priorityLevel": "high",
        "notes": null
      }
    ],
    "approved": {
      "approvedSupportType": "كرتونة مواد غذائية",
      "approvedAmount": 300.0,
      "beneficiary": "الأسرة",
      "frequency": "شهري",
      "duration": null,
      "approvedAtUtc": "2026-09-18T10:00:00Z",
      "approvalNotes": "اعتماد لجنة البت",
      "approvedByUserId": "guid",
      "rowVersion": 1
    }
  },
  "message": null
}
```
`approved` is `null` when the manager has never recorded a decision (test `Worker_Can_Submit_Proposed_Support_Items_And_Read_Them_Back`).

### Errors specific to this route
- `404 CASE_NOT_FOUND` — case doesn't exist / invisible.

---

### 13. PUT /api/v1/cases/{id}/support-recommendations

**Headers:** none special (no `Idempotency-Key`).
**Permission:** `edit_case` (NOT `write_worker_opinion`/`write_manager_approval` — this is a Case-DATA edit, gated the same as other Phase 7/8 section replaces).
**Authorization:** `CaseEditAuthorization.AuthorizeCaseDataEditAsync` — `manager`/`data_entry` may edit any case; `social_worker` only if it's their assigned case; `reviewer` never reaches this (no `edit_case` permission at all → 403 at the ASP.NET policy layer, confirmed by test `Reviewer_Cannot_Submit_Proposed_Support_Items`).
**Full replace** of the case's proposed-support list, anchored on `caseRowVersion`.

### Request body
```json
{
  "items": [
    {
      "supportType": "زي مدرسي",
      "supportCategory": null,
      "beneficiary": "الأسرة",
      "proposedAmount": 500,
      "frequency": "شهري",
      "duration": null,
      "reason": "احتياج فعلي",
      "justification": "تقرير الأخصائي",
      "priorityLevel": "high",
      "notes": null
    }
  ],
  "caseRowVersion": 3
}
```
| Field | Type | Required | Validation |
|---|---|---|---|
| items[].supportType | string | yes | `NotEmpty`, `MaximumLength(100)` |
| items[].supportCategory | string? | no | `MaximumLength(100)` |
| items[].beneficiary | string | yes | `NotEmpty`, `MaximumLength(255)` |
| items[].proposedAmount | decimal | yes | `>= 0` |
| items[].frequency | string? | no | `MaximumLength(30)` |
| items[].duration | string? | no | `MaximumLength(50)` |
| items[].reason | string | yes | `NotEmpty` |
| items[].justification | string | yes | `NotEmpty` |
| items[].priorityLevel | string | yes | `NotEmpty`, `MaximumLength(30)` (no closed enum enforced at this layer) |
| items[].notes | string? | no | none |
| caseRowVersion | uint | yes | concurrency anchor |

### Success response (200)
```json
{
  "success": true,
  "data": {
    "items": [ { "id": "guid", "supportType": "زي مدرسي", "...": "..." } ],
    "caseRowVersion": 4
  },
  "message": null
}
```
Each item gets a server-generated `id` (`Guid.NewGuid()`), even on replace — old ids are NOT preserved across a replace.

### Errors specific to this route
- `404 CASE_NOT_FOUND`.
- `403 FORBIDDEN` — `reviewer` lacks `edit_case` entirely (blocked at the ASP.NET policy, before the handler); a `social_worker` on a case not assigned to them gets `403` from `AuthorizeCaseDataEditAsync` itself (`"لا يمكن تعديل بيانات حالة غير مسندة إليك"`).
- `422 VALIDATION_ERROR` — any per-item field rule violation.
- `409 CONCURRENCY_CONFLICT` — stale `caseRowVersion`.

### Frontend note
This is the PROPOSED list only — completely independent of the manager's approved decision (BR-04/AS-03; verified by test `Manager_Can_Record_Approved_Support_Independently_Of_The_Proposed_List` — approving one item does not remove/alter it from the recommendations list). Replacing the proposed list never touches `approved-support`.

---

### 14. PUT /api/v1/cases/{id}/approved-support

**Headers:** none special.
**Permission:** `write_manager_approval` (manager only — confirmed by test `DataEntry_Cannot_Record_Approved_Support` → 403).
**Authorization:** `CaseEditAuthorization.AuthorizeAsync` (visibility only, not the case-data-edit chain — this is a manager decision, not a routine field edit).
**Singleton row per case** — first call CREATES the `CaseApprovedSupport` row (no `rowVersion` needed/checked on create — `apply(approved)` called before the entity is tracked with any expected xmin); subsequent calls UPDATE it and DO require the correct `rowVersion` or `409 CONCURRENCY_CONFLICT` (test `Approved_Support_Is_Concurrency_Guarded_On_Its_Own_RowVersion` sends `rowVersion: null` on the second call against an existing row — anchors `expectedRowVersion ?? 0`, which will never match a real xmin, guaranteeing conflict on any update after the first write unless the real value is echoed back).
**This does NOT go through the workflow engine at all** — it's not a case-status transition, so no `INVALID_STATUS_TRANSITION`/`OPINION_SLOT_LOCKED`/etc apply here; it's a plain data write available at any case status.
**Recorded via `IAuditWriter`** synchronously (audit action `CASE_SUPPORT_APPROVED`) — same transaction-critical treatment as Approve/Reject, since this is also a money decision.

### Request body
```json
{
  "approvedSupportType": "كرتونة مواد غذائية",
  "approvedAmount": 300,
  "beneficiary": "الأسرة",
  "frequency": "شهري",
  "duration": null,
  "approvalNotes": "اعتماد لجنة البت",
  "rowVersion": null
}
```
| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| approvedSupportType | string | yes | `NotEmpty`, `MaximumLength(100)` | |
| approvedAmount | decimal | yes | `>= 0` | |
| beneficiary | string | yes | `NotEmpty`, `MaximumLength(255)` | |
| frequency | string? | no | `MaximumLength(30)` | |
| duration | string? | no | `MaximumLength(50)` | |
| approvalNotes | string? | no | `MaximumLength(2000)` | |
| rowVersion | uint? | conditionally required | omit/`null` on first call (creating); **required = the real current value on any subsequent call** or you get `409` | This is the APPROVED-SUPPORT row's own xmin — distinct from `caseRowVersion` |

### Success response (200)
```json
{
  "success": true,
  "data": {
    "approvedSupportType": "كرتونة مواد غذائية",
    "approvedAmount": 300.0,
    "beneficiary": "الأسرة",
    "frequency": "شهري",
    "duration": null,
    "approvedAtUtc": "2026-09-18T10:00:00Z",
    "approvalNotes": "اعتماد لجنة البت",
    "approvedByUserId": "guid",
    "rowVersion": 1
  },
  "message": null
}
```

### Errors specific to this route
- `404 CASE_NOT_FOUND`.
- `403 FORBIDDEN` — role lacks `write_manager_approval`.
- `422 VALIDATION_ERROR` — any field rule violation.
- `409 CONCURRENCY_CONFLICT` — `rowVersion` doesn't match the existing singleton row's xmin (including the common client bug of always sending `null`/omitting it after the first write).

### Frontend note
There is exactly ONE approved-support row per case, always overwritten in place by a subsequent PUT — this is NOT a list/history; each call REPLACES the prior manager decision wholesale (no append, no versioned history of past approvals beyond the audit log). The frontend must always GET `/support` first to read the current `approved.rowVersion` before PUTting an update, exactly like any other rowVersion-guarded resource — sending `rowVersion: null` a second time is not "unset", it produces a guaranteed conflict against a non-null existing row.

---

### Cross-cutting notes confirmed against source (matches "known context")

- All 8 workflow-transition routes (assign, accept, reject-assignment, opinions/worker, opinions/reviewer, return-to-worker, opinions/manager, return-for-completion) require `Idempotency-Key`; field-visits POST/PUT and field-verification PUT do not. Confirmed directly in `CaseWorkflowEndpoints.MapCaseWorkflowEndpoints`'s use of `ExecuteIdempotentAsync` for all 8, vs. `FieldVisitEndpoints` calling `mediator.Send` directly with no wrapper.
- Idempotency cache is keyed `(key, actorId)` — confirmed via `guard.TryGetCachedResponseAsync(key, actorId, ...)` and the regression test `One_Users_Idempotency_Key_Never_Replays_Another_Users_Response`.
- Decision wire format confirmed: `"decision":"accepted"|"rejected"` for worker/reviewer opinions; `"approve": true|false` boolean for manager. Return-to-worker has no `decision` field at all (uses `reason` only), internally stored as `OpinionDecision.ReturnedToWorker`.
- Support-recommendations uses `edit_case` (not workflow permissions) — confirmed in `CaseSupportEndpoints.cs` line 42, and in `ReplaceSupportRecommendationsCommandHandler` calling `AuthorizeCaseDataEditAsync` (the Phase 7/8-style section-edit chain), not the workflow chain.
- GET /support uses `view_cases` — confirmed line 32.
- approved-support uses `write_manager_approval` — confirmed line 55, and does NOT run through `AuthorizeCaseDataEditAsync`/the workflow engine at all (plain `AuthorizeAsync` visibility check only).

### Points worth flagging as unconfirmed / minor nuance beyond the known context

1. **`/accept` self-accept race loser's exact error code is non-deterministic** — the test only asserts "409 or 422", not one specific code. Document as "returns either `409 CONCURRENCY_CONFLICT` or `422 INVALID_STATUS_TRANSITION` depending on timing," not a single guaranteed code.
2. **`opinions/manager` reject from an already-`Rejected` case** gets plain `422 INVALID_STATUS_TRANSITION`, NOT `CASE_ALREADY_APPROVED` — the special code is deliberately scoped to the `Approved` terminal state only (see `BeginTransitionAsync`'s explicit `oldStatus == CaseStatus.Approved` check). Worth calling out since "CASE_ALREADY_APPROVED" sounds like it might also fire for "already rejected," but it does not.
3. **`opinions/manager`'s `decision` response field does not distinguish which role produced a `"rejected"` value** — worth flagging to frontend devs building an audit/history view: don't infer "who rejected" from the `decision` string alone.
4. **FV1/FV2's photo-linkage error message intentionally does not disclose WHY an id failed** (nonexistent vs wrong-case vs wrong-status all collapse into one message) — by design, not an omission.
5. No dedicated FluentValidation validator class exists for `AcceptAssignmentCommand`, `ReturnForCompletionCommand`, or `RecordFieldVisitCommand`/`UpdateFieldVisitCommand` beyond what's noted (the latter two DO have the shared `FieldVisitInputValidator<T>`).

---

## 21. Endpoint Details — Attachments, Search, Dashboard, Notifications, Audit Logs

Full per-endpoint detail supplementing §13 (Attachments), §12 (Push Notifications), and the search/dashboard/audit routes this app's work-queue and case-list screens depend on.

Structured per-endpoint reference (parameter tables, field tables, full error catalogues). Reuses existing narrative from §11/§13 — does not repeat it. All values confirmed by reading source under `E:\موسسه\src`. Standard success envelope: `ApiResponse<T> { success, data, message }`. Standard error envelope: `ApiErrorResponse { success:false, error: { code, message, details? } }` — `details` is a `Dictionary<string,string[]>` of FluentValidation field errors, omitted (not `{}`) when empty. Standard paged shape: `{ items, page, limit, total, totalPages, hasNext, hasPrev }` (`PagedResult<T>`, default limit 20, max 100, `ClampPageSize` silently clamps out-of-range `limit` rather than erroring; `page<1` silently resets to 1 for most endpoints — Search/Dashboard-stats/Attachments-list clamp; Work-queue/Notifications/Audit-logs instead **reject** `page<=0` or `limit<=0` with 422 via FluentValidation `GreaterThan(0)`, confirmed below).

---

### POST /api/v1/attachments/init

**Auth:** Bearer JWT. **Permission:** `EditCase`. **Rate limit:** `Moderate` policy (named tier, applied per-route — confirmed in `AttachmentEndpoints.cs` line 53).

**Headers beyond Authorization:** none required. `Content-Type: application/json`.

**Path/query params:** none.

**Request body** (`InitUploadRequest`):

| Field | Type | Required | Notes |
|---|---|---|---|
| `caseId` | guid | yes | `NotEmpty` |
| `documentType` | string | yes | `NotEmpty`, max 50 chars |
| `fileName` | string | yes | `NotEmpty`, max 255 chars. Original name, kept for display only — never used to build the storage key or determine the extension. |
| `mimeType` | string | yes | `NotEmpty`, max 100 chars. Checked against closed allow-list (`ResolveMimeType`); case/parameter-insensitive (`Image/JPEG; charset=binary` normalizes fine). |
| `fileSize` | long (bytes) | yes | `GreaterThan(0)`. Declared value only — re-verified against real storage size at commit; declaring a small size and uploading a bigger file buys nothing. |
| `description` | string | no | max 2000 chars |

Fields deliberately **not bindable** even if sent: `attachmentId`, `objectKey`/`filePath`, `uploadedBy`, `uploadedByUserId`, `status`, `createdAt` — the record has no such members, so extra JSON properties simply have nowhere to bind (mass-assignment defense).

**Allow-list (closed, 8 extensions / 7 canonical MIME types — `jpg`+`jpeg` share `image/jpeg`):**

| Extension | Canonical MIME type stored |
|---|---|
| jpg / jpeg | image/jpeg |
| png | image/png |
| heic (also accepts `heif` in the extension-alias table, but canonical output is `heic`) | image/heic |
| webp | image/webp |
| pdf | application/pdf |
| doc | application/msword |
| docx | application/vnd.openxmlformats-officedocument.wordprocessingml.document |

Max size: **10,485,760 bytes (10 MB)** — `AttachmentFilePolicy.MaxFileSizeBytes`.

**Example request:**
```
POST /api/v1/attachments/init
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "caseId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "documentType": "national_id_copy",
  "fileName": "id_front.jpg",
  "mimeType": "image/jpeg",
  "fileSize": 842311,
  "description": "صورة البطاقة الشخصية للمستفيد"
}
```

**Success 200** (`InitUploadResult`):
```json
{
  "success": true,
  "data": {
    "attachmentId": "9c1e2b6a-1111-4a2b-8f3d-000000000001",
    "caseId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "uploadUrl": "https://storage.example.com/nahda-attachments/3fa85f64.../9c1e2b6a....jpg?X-Amz-Signature=...",
    "httpMethod": "PUT",
    "objectKey": "3fa85f64-5717-4562-b3fc-2c963f66afa6/9c1e2b6a-1111-4a2b-8f3d-000000000001.jpg",
    "mimeType": "image/jpeg",
    "fileName": "id_front.jpg",
    "maxFileSizeBytes": 10485760,
    "uploadUrlExpiresAtUtc": "2026-09-18T10:45:00Z",
    "status": "pending"
  },
  "message": null
}
```
Note: `uploadUrlExpiresAtUtc` TTL is **30 minutes** (`UploadUrlTtl`) — longer than the 15-minute download TTL, intentionally, to tolerate slow mobile uploads of a 10MB file.

**Errors:**

| HTTP | Code | Trigger |
|---|---|---|
| 401 | (no body / standard auth challenge) | missing/invalid JWT |
| 403 | — | caller lacks `EditCase` permission for their role |
| 404 | `CASE_NOT_FOUND` | `caseId` does not exist, or exists but is invisible/not-editable to caller (IDOR: never 403 for this reason) |
| 422 | `VALIDATION_ERROR` | any FluentValidation rule above fails; `details` keyed by PascalCase property name (`CaseId`, `DocumentType`, `FileName`, `MimeType`, `FileSize`, `Description`) |
| 422 | `UNSUPPORTED_FILE_TYPE` | `mimeType` not on allow-list OR `fileName`'s extension not on allow-list (checked independently — a valid mimeType with a mismatched/unsupported extension in the name still fails here) |
| 422 | `FILE_TOO_LARGE` | `fileSize` > 10,485,760 |
| 429 | (rate-limit problem body) | `Moderate` policy exceeded |
| 503 | `STORAGE_UNAVAILABLE` | presigned-PUT minting fails at the storage provider; the already-written `pending` row is harmless and self-cleans after 48h |

**Concurrency:** N/A (creates a new row; no `rowVersion` on the request).
**Idempotency-Key:** not required/supported on this route — each call mints a new `attachmentId`; there is no dedup on repeated `/init` calls with identical bodies (the client is expected to call `/init` once per intended upload).

**Frontend note:** the row is persisted as `pending` **before** the presigned URL is minted (write-ahead), so a client that receives a 200 here is guaranteed a durable record even if the network drops before the PUT — retry the whole `/init` → `/commit` cycle from scratch if the upload never completed and the URL later expires; do not attempt to resume a `pending` row from `/init`'s prior response after 30 minutes.

---

### POST /api/v1/attachments/{id}/commit

**Auth:** Bearer JWT. **Permission:** `EditCase`. No named rate-limit override (falls back to global per-IP limit).

**Path params:**

| Param | Type | Required | Example |
|---|---|---|---|
| `id` | guid | yes | `/api/v1/attachments/9c1e2b6a-1111-4a2b-8f3d-000000000001/commit` |

**Headers beyond Authorization:** none. No `Idempotency-Key` needed or supported — idempotency is achieved via the server-assigned `attachmentId` itself plus the "already complete ⇒ no-op success" rule.

**Request body** (`CommitUploadRequest`) — **entirely optional**, may be omitted or `{}`:

| Field | Type | Required | Notes |
|---|---|---|---|
| `checksum` | string? | no | max 128 chars. Client-computed MD5 hex digest over the uploaded bytes. Compared to the storage provider's ETag **only** when the ETag is a comparable single-part MD5 (`IsChecksumComparable`) — not compared at all for multi-part ETags. |

**Example request:**
```json
POST /api/v1/attachments/9c1e2b6a-1111-4a2b-8f3d-000000000001/commit
Authorization: Bearer <jwt>
Content-Type: application/json

{ "checksum": "5d41402abc4b2a76b9719d911017c592" }
```

**Success 200 — first (real) commit** (`CommitUploadResult`):
```json
{
  "success": true,
  "data": {
    "attachmentId": "9c1e2b6a-1111-4a2b-8f3d-000000000001",
    "caseId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "status": "complete",
    "scanStatus": "not_scanned",
    "mimeType": "image/jpeg",
    "fileSizeBytes": 842311,
    "checksum": "5d41402abc4b2a76b9719d911017c592",
    "fileName": "id_front.jpg",
    "uploadedAtUtc": "2026-09-18T10:32:07Z",
    "rowVersion": 1,
    "alreadyComplete": false
  }
}
```

**Success 200 — replay of an already-completed commit:** identical shape except `"alreadyComplete": true`; no re-verification against storage is performed on this path (avoids turning a cheap retry into a storage round trip).

**Full error catalogue:**

| HTTP | Code | Trigger |
|---|---|---|
| 401 | — | missing/invalid JWT |
| 403 | — | caller lacks `EditCase` for the case |
| 404 | `CASE_NOT_FOUND` | (a) `id` does not exist at all, or (b) exists but its case is not editable/visible to caller — both collapse to the same code/message so existence cannot be inferred |
| 422 | `VALIDATION_ERROR` (FluentValidation) | `AttachmentId` empty (route-bound, effectively unreachable via HTTP) or `Checksum` > 128 chars |
| 422 | `VALIDATION_ERROR` (business, same code different message) | "لم يتم العثور على الملف المرفوع، برجاء إعادة الرفع" — client committed without ever completing the PUT (storage has no object at `objectKey`); attachment **stays `pending`**, eligible for retry or 48h orphan cleanup |
| 422 | `VALIDATION_ERROR` | "حجم الملف المرفوع لا يطابق الحجم المُعلن عنه" — real storage size differs from the size declared at `/init` |
| 422 | `VALIDATION_ERROR` | "بصمة التحقق للملف لا تطابق الملف المرفوع" — client-supplied checksum present, ETag comparable, and they don't match |
| 422 | `FILE_TOO_LARGE` | real storage-reported size > 10 MB (catches a client that declared a small size at `/init` then PUT something bigger) |
| 422 | `UNSUPPORTED_FILE_TYPE` | real magic bytes at the object's first 64 bytes don't sniff to any allowed type, OR sniffed type doesn't match the MIME type declared/validated at `/init` |
| 503 | `STORAGE_UNAVAILABLE` | storage read (metadata or header bytes) fails at the provider level |

**Concurrency:** `rowVersion` (`uint`, Postgres `xmin`) is **returned** in the response for downstream metadata-edit optimistic-concurrency use, but `/commit` itself takes no `rowVersion` input and cannot 409 — there is no metadata-edit endpoint for attachments in this set, so `CONCURRENCY_CONFLICT`/409 is **not** applicable to any of these five attachment routes (unconfirmed whether a future metadata-PATCH route would use it; none exists today).

**Frontend note:** on the replay path (`alreadyComplete: true`) the response is **not re-verified**, so if the underlying file was somehow corrupted between the first successful commit and a later replay, the client would not learn about it from this call — that's a deliberate performance/idempotency tradeoff, not a bug.

---

### GET /api/v1/attachments/{id}/download

**Auth:** Bearer JWT. **Permission:** `ViewCases`. No rate-limit override on this specific route (global default applies — narrative in §11 confirms 15-min TTL, this is the structured detail).

**Path params:**

| Param | Type | Required | Example |
|---|---|---|---|
| `id` | guid | yes | `GET /api/v1/attachments/9c1e2b6a-1111-4a2b-8f3d-000000000001/download` |

**Query params:** none. **Request body:** none (GET).

**Success 200** (`DownloadUrlResult`):
```json
{
  "success": true,
  "data": {
    "attachmentId": "9c1e2b6a-1111-4a2b-8f3d-000000000001",
    "caseId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "downloadUrl": "https://storage.example.com/nahda-attachments/3fa85f64.../9c1e2b6a....jpg?X-Amz-Signature=...&response-content-disposition=attachment%3B%20filename%3D%22id_front.jpg%22",
    "fileName": "id_front.jpg",
    "mimeType": "image/jpeg",
    "fileSizeBytes": 842311,
    "expiresAtUtc": "2026-09-18T11:00:00Z",
    "expiresInSeconds": 900
  }
}
```
`mimeType` and `fileSizeBytes` are typed nullable (`string?`, `long?`) at the contract level — will be non-null for any attachment that reached `complete` status (the only status this endpoint ever returns a URL for), so treat them as effectively always-present in practice but code defensively against `null`.

**Full error catalogue:**

| HTTP | Code | Trigger |
|---|---|---|
| 401 | — | missing/invalid JWT |
| 403 | — | caller lacks `ViewCases` |
| 404 | `CASE_NOT_FOUND` (message: "الحالة غير موجودة") | `id` does not exist |
| 404 | `CASE_NOT_FOUND` (message: "المرفق غير متاح للتحميل") | attachment exists but its case is not visible to the caller **right now** — re-checked on every single call, not cached from upload time; a user who lost visibility after uploading gets 404 even though they created it |
| 404 | `CASE_NOT_FOUND` (message: "المرفق غير متاح للتحميل") | attachment status is not `complete` (e.g. still `pending`) — same code/message as the visibility case, deliberately indistinguishable |
| 503 | `STORAGE_UNAVAILABLE` | presigned GET minting fails at the storage provider |

**Concurrency:** N/A — read-only, no request body, no `rowVersion` accepted.
**Idempotency-Key:** N/A (GET; also explicitly documented as minting a **fresh** URL on every call — never cached or reused, no stored/reusable link anywhere in the system).

**Frontend note:** never persist/cache a `downloadUrl` beyond the current screen render — it is single-use-window (15 min) and re-fetching costs nothing but a normal authorized request; do not attempt to "refresh" an expired URL client-side (there is no refresh mechanism), just call this endpoint again.

---

### DELETE /api/v1/attachments/{id}

**Auth:** Bearer JWT. **Permission:** `EditCase`. No rate-limit override.

**Path params:**

| Param | Type | Required | Example |
|---|---|---|---|
| `id` | guid | yes | `DELETE /api/v1/attachments/9c1e2b6a-1111-4a2b-8f3d-000000000001` |

**Request body:** none.

**Success 200** (`DeleteAttachmentResult`):
```json
{
  "success": true,
  "data": {
    "attachmentId": "9c1e2b6a-1111-4a2b-8f3d-000000000001",
    "caseId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "deleted": true
  }
}
```
`deleted` is always `true` on a 200 — there is no "already deleted, no-op" 200 path; a second delete of the same id returns 404 (see below), so this operation is **not** idempotent the way commit/mark-all-read are.

**Full error catalogue:**

| HTTP | Code | Trigger |
|---|---|---|
| 401 | — | missing/invalid JWT |
| 403 | — | caller lacks `EditCase` for the case (includes reviewer role, which never has edit rights, and social_worker on a case not assigned to them) |
| 404 | `CASE_NOT_FOUND` | `id` does not exist, OR exists but case is not editable/visible to caller (IDOR — same code for "never existed", "not yours to edit", and "deleted already") |
| 503 | `STORAGE_UNAVAILABLE` | the storage-object delete step fails after the metadata row was already deleted — **note:** the DB row is deleted first (in its own transaction, alongside the `AttachmentDeleted` outbox row), and only then is the object deleted from storage; if this 503 occurs, the metadata row is **already gone** even though the client sees an error — the object then becomes an orphan the cleanup job's sibling logic must eventually reconcile. **Genuine gotcha:** a client seeing 503 here should NOT assume the delete failed to take effect — re-querying `GET /cases/{id}/attachments` is the only way to confirm. |

**Concurrency:** no `rowVersion` accepted on the delete request — deletion is unconditional once the edit-authorization and existence checks pass (no optimistic-concurrency check against a client-supplied version for this route).

**Frontend note:** ordering risk above (row deleted before object) means a 503 from this endpoint is ambiguous about outcome — always re-fetch the attachment list after any 503 from this route before showing a retry affordance, to avoid a duplicate-looking retry against an already-gone row (which would then just 404).

---

### GET /api/v1/cases/{id}/attachments

**Auth:** Bearer JWT. **Permission:** `ViewCases`. Mounted at `/api/v1/cases/{caseId:guid}/attachments`, **not** under `/attachments` — deliberately a separate request from case details, never embedded in that payload.

**Path params:**

| Param | Type | Required | Example |
|---|---|---|---|
| `caseId` (route name; user-facing path is `{id}`) | guid | yes | `/api/v1/cases/3fa85f64-5717-4562-b3fc-2c963f66afa6/attachments` |

**Query params:**

| Param | Type | Required | Default | Max | Notes |
|---|---|---|---|---|---|
| `page` | int | no | 1 | — | not independently validated; any value is passed through, non-positive values reset to 1 in the handler (`request.Page < 1 ? 1 : request.Page`) — **no 422 for `page=0` or negative**, unlike work-queue/notifications/audit-logs |
| `limit` | int | no | 20 | 100 | clamped via `PagedResult.ClampPageSize`, not rejected |

Example: `GET /api/v1/cases/3fa85f64-5717-4562-b3fc-2c963f66afa6/attachments?page=1&limit=20`

**Success 200** (`PagedResult<AttachmentListItem>`):
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "9c1e2b6a-1111-4a2b-8f3d-000000000001",
        "caseId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "documentType": "national_id_copy",
        "fileName": "id_front.jpg",
        "description": "صورة البطاقة الشخصية للمستفيد",
        "status": "complete",
        "scanStatus": "not_scanned",
        "fileSizeBytes": 842311,
        "mimeType": "image/jpeg",
        "uploadedByUserId": "1c2d3e4f-0000-0000-0000-000000000009",
        "uploadedByName": "أحمد محمود",
        "uploadedAtUtc": "2026-09-18T10:32:07Z",
        "rowVersion": 1
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1,
    "hasNext": false,
    "hasPrev": false
  }
}
```
**No download URL is ever present in this list response** — fetch each one individually via `GET /attachments/{id}/download`.

**Full error catalogue:**

| HTTP | Code | Trigger |
|---|---|---|
| 401 | — | missing/invalid JWT |
| 403 | — | caller lacks `ViewCases` |
| 404 | `CASE_NOT_FOUND` | case does not exist or is not visible to caller — returns 404 rather than an empty page, specifically so an empty page can never be used to confirm a case id exists |

**Concurrency / Idempotency-Key:** N/A (read-only list).

**Frontend note:** `uploadedByName` can theoretically be stale/null-ish for a deleted user account depending on repository join semantics — not explicitly documented as nullable in the record signature (`string?`), so treat it as possibly `null` defensively even though typical data will have it populated.

---

### GET /api/v1/search/cases

**Auth:** Bearer JWT. **Permission:** `ViewCases`. **Rate limit:** `Moderate` (applied at the `/search` group level).

**Query params — CONFIRMED EXACT CASING from `SearchEndpoints.cs`:**

| Param | Type | Required | Match type | Notes |
|---|---|---|---|---|
| `q` | string | no | general — tried as name/contains AND (if all-digit after normalization) also as exact national_id/phone | min 2 chars if provided |
| `name` | string | no | contains (ILIKE, escaped) | min 2 chars if provided |
| `national_id` | string | no | **exact** | snake_case confirmed in source — **not** `nationalId` |
| `charity` | string | no | contains | min 2 chars if provided |
| `region` | string | no | contains | min 2 chars if provided |
| `phone` | string | no | exact | no minimum length (short exact query is legitimate, just matches nothing) |
| `date` | date (`YYYY-MM-DD`) | no | exact day match against `registrationDate` | `DateOnly?` |
| `page` | int | no | — | default 1, clamped not rejected |
| `limit` | int | no | — | default 20, max 100, clamped not rejected |

**Confirms known context:** `national_id` is indeed snake_case in the querystring, exactly as documented — verified directly against the `MapGet("/cases", ...)` lambda parameter list (`string? national_id`) in `SearchEndpoints.cs` line 42. All other params (`q`, `name`, `charity`, `region`, `phone`, `date`, `page`, `limit`) are plain lowercase/camelCase-irrelevant single words. **No contradiction found.**

Arabic/Indic digit normalization (٠-٩, ۰-۹) applies automatically to `national_id`/`phone`/the digit-branch of `q`, stripping spaces and hyphens, before exact match.

**Example request:**
```
GET /api/v1/search/cases?national_id=29805142200551&page=1&limit=20
Authorization: Bearer <jwt>
```
```
GET /api/v1/search/cases?q=%D9%85%D8%AD%D9%85%D8%AF&page=1&limit=20
```

**Success 200** (`PagedResult<CaseSearchResultItem>`) — item shape identical to `GET /cases`:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "caseNumber": "C-2026-000481",
        "displayId": "481",
        "status": "pending_review",
        "priority": "normal",
        "beneficiaryFullName": "محمد أحمد علي",
        "nationalId": "29805142200551",
        "charityId": "b2c3d4e5-0000-0000-0000-000000000002",
        "registrationDate": "2026-08-01",
        "completionPercentage": 62.5,
        "createdAtUtc": "2026-08-01T09:12:44Z",
        "nextVisitDate": null,
        "nextVisitStartTimeUtc": null,
        "nextVisitLocation": null,
        "isBookmarked": false
      }
    ],
    "page": 1, "limit": 20, "total": 1, "totalPages": 1, "hasNext": false, "hasPrev": false
  }
}
```

**Full validation / error catalogue:**

| HTTP | Code | Field key(s) in `details` | Trigger |
|---|---|---|---|
| 401 | — | — | missing/invalid JWT |
| 403 | — | — | caller lacks `ViewCases` |
| 422 | `VALIDATION_ERROR` | `Q`, `Name`, `Charity`, `Region` | value present but < 2 chars after trim — message: "يجب إدخال حرفين على الأقل للبحث" |
| 422 | `VALIDATION_ERROR` | any of `Q`,`Name`,`Charity`,`Region`,`NationalId`,`Phone` | value > 200 chars after trim — "نص البحث طويل جدًا" |
| 422 | `VALIDATION_ERROR` | any of the six string fields | contains a C0 control character (non-whitespace) — "نص البحث يحتوي على رموز غير مسموح بها" — this specifically prevents a raw Postgres/Npgsql exception (NUL byte) from ever reaching a 500 |

**Important:** `details` keys use FluentValidation's **default PascalCase property names** (`Q`, `Name`, `NationalId`, `Charity`, `Region`, `Phone`) — deliberately **not** rewritten to the snake_case query-param spelling (`national_id`). A frontend mapping `422` field errors back to form inputs must map `NationalId` → the `national_id` input, not assume identical casing.

**Concurrency / Idempotency-Key:** N/A (read-only).

**Frontend note:** `national_id` and `phone` have **no minimum length** — sending `national_id=1` is valid and simply returns zero matches (empty page), unlike the four contains-fields which 422 below 2 chars. Slow queries (≥500ms) are logged server-side but never surfaced to the client — a >500ms response is not an error and returns normally.

---

### GET /api/v1/dashboard/stats

**Auth:** Bearer JWT. **Permission:** `ViewCases`. **Rate limit:** `Moderate`. **No parameters of any kind** — identity/role come solely from the JWT.

**Success 200** shape is `IReadOnlyDictionary<string,long>` — a flat object of camelCase KPI keys, **varying by the caller's role** (`DashboardCards.ByRole`). Cached 30s per user+role (`IDashboardStatsCache`); on cache outage the live DB result is served, never a failure.

**reviewer:**
```json
{
  "success": true,
  "data": {
    "awaitingMyReview": 7,
    "totalCases": 214,
    "reviewedByMe": 58,
    "acceptedCases": 140,
    "rejectedCases": 12,
    "returnedToWorker": 4
  }
}
```

**manager:**
```json
{
  "success": true,
  "data": {
    "awaitingMyApproval": 5,
    "totalCases": 214,
    "acceptedCases": 140,
    "rejectedCases": 12,
    "totalEmployees": 23,
    "totalCharities": 9
  }
}
```

**data_entry:**
```json
{
  "success": true,
  "data": {
    "createdByMe": 31,
    "totalCases": 214,
    "missingDocuments": 6,
    "pendingReview": 18,
    "approvedCharities": 9
  }
}
```

**social_worker (undocumented in source spec — reconstructed as "all-roles" fields only, per code comment):**
```json
{
  "success": true,
  "data": {
    "totalCases": 47,
    "acceptedCases": 30,
    "rejectedCases": 3
  }
}
```
Note `approvedCharities` (data_entry) and `totalCharities` (manager) are the **same underlying `COUNT(charities)` value** exposed under two different field names per role — not two different counts. An unrecognized/malformed role claim returns an **empty `{}`** object rather than 500 or 403.

**Full error catalogue:**

| HTTP | Code | Trigger |
|---|---|---|
| 401 | — | missing/invalid JWT |
| 403 | — | caller lacks `ViewCases` |

(No 422 possible — no parameters to validate.)

**Concurrency / Idempotency-Key:** N/A.

**Frontend note:** because the shape differs by role, do not use one shared TypeScript/Dart model for all roles' stats — either type it as a loose `Record<string, number>`/`Map<String,int>` or branch on the known role→field-set table above. A field absent for the current role is genuinely **absent from the JSON**, not `null` or `0`.

---

### GET /api/v1/dashboard/work-queue

**Auth:** Bearer JWT. **Permission:** `ViewCases`. **Rate limit:** `Moderate`.

**Query params:**

| Param | Type | Required | Default | Max | Validation |
|---|---|---|---|---|---|
| `page` | int | no | 1 | — | **`GreaterThan(0)` — rejects `page<=0` with 422**, unlike attachments-list/search which silently clamp |
| `limit` | int | no | 20 | 100 | **`GreaterThan(0)` — rejects `limit<=0` with 422**; still clamped to 100 max via `PagedResult` on the accepted path |

No filter parameters — role+identity from JWT fully determine content:
- reviewer → cases in `pending_review`
- manager → cases in `pending_approval`
- social_worker → cases `assigned`/`in_research`/`returned_to_worker` **and** assigned to that user
- data_entry → cases they created still `draft`/`pending_assignment`, or with an incomplete attachment upload

**Example:** `GET /api/v1/dashboard/work-queue?page=1&limit=20`

**Success 200** (`PagedResult<WorkQueueItem>`) — item shape is **identical field set to `GET /cases`/search results** (`WorkQueueItem` record matches `CaseSearchResultItem` field-for-field):
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "caseNumber": "C-2026-000481",
        "displayId": "481",
        "status": "pending_review",
        "priority": "high",
        "beneficiaryFullName": "محمد أحمد علي",
        "nationalId": "29805142200551",
        "charityId": "b2c3d4e5-0000-0000-0000-000000000002",
        "registrationDate": "2026-08-01",
        "completionPercentage": 62.5,
        "createdAtUtc": "2026-08-01T09:12:44Z",
        "nextVisitDate": "2026-09-20",
        "nextVisitStartTimeUtc": "2026-09-20T08:00:00Z",
        "nextVisitLocation": "مركز الجمعية - الفرع الرئيسي",
        "isBookmarked": true
      }
    ],
    "page": 1, "limit": 20, "total": 1, "totalPages": 1, "hasNext": false, "hasPrev": false
  }
}
```

**Full error catalogue:**

| HTTP | Code | Field | Trigger |
|---|---|---|---|
| 401 | — | — | missing/invalid JWT |
| 403 | — | — | caller lacks `ViewCases` |
| 422 | `VALIDATION_ERROR` | `Page` | `page <= 0` — "رقم الصفحة يجب أن يكون أكبر من صفر" |
| 422 | `VALIDATION_ERROR` | `Limit` | `limit <= 0` — "عدد العناصر يجب أن يكون أكبر من صفر" |

**Concurrency / Idempotency-Key:** N/A.

**Frontend note (genuine gotcha):** this endpoint's `page`/`limit` validation is **stricter** than `GET /cases/{id}/attachments` and `GET /search/cases`, which silently clamp bad pagination instead of 422ing. A generic "pagination" hook shared across screens must be prepared to handle a 422 here that the same inputs would not trigger against the attachments-list or search endpoints. There is also **no live push** for this list (no websocket/SSE) — despite older docs mentioning an EventBus, that refers to a frontend-only in-browser bus; the client must poll/refresh this endpoint itself.

---

### GET /api/v1/notifications

**Auth:** Bearer JWT only — **no permission policy** (any authenticated user of any role).

**Query params:**

| Param | Type | Required | Default | Max | Validation |
|---|---|---|---|---|---|
| `page` | int | no | 1 | — | `GreaterThan(0)` — 422 if `<=0` |
| `limit` | int | no | 20 | 100 | `GreaterThan(0)` — 422 if `<=0`; clamped to 100 on the accepted path |

**Success 200** (`NotificationListResult` = `{ page: PagedResult<NotificationListItem>, unreadCount: long }`) — confirmed exact shape:
```json
{
  "success": true,
  "data": {
    "page": {
      "items": [
        {
          "id": "e1e2e3e4-0000-0000-0000-000000000010",
          "title": "تم إسناد حالة جديدة إليك",
          "subtitle": "الحالة رقم C-2026-000481",
          "icon": "case_assigned",
          "isRead": false,
          "caseId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "createdAtUtc": "2026-09-18T09:00:00Z"
        }
      ],
      "page": 1, "limit": 20, "total": 1, "totalPages": 1, "hasNext": false, "hasPrev": false
    },
    "unreadCount": 4
  }
}
```
Confirms known context field list (`id`,`title`,`subtitle`,`icon`,`isRead`,`caseId`,`createdAtUtc`) exactly — no `userId` field is ever present (deliberately omitted, every row belongs to the caller by construction). `icon` is nullable (`string?`). `unreadCount` is the caller's total unread **across all pages**, not scoped to the current page — correct value for a UI badge.

**Full error catalogue:**

| HTTP | Code | Field | Trigger |
|---|---|---|---|
| 401 | — | — | missing/invalid JWT |
| 422 | `VALIDATION_ERROR` | `Page` | `page <= 0` |
| 422 | `VALIDATION_ERROR` | `Limit` | `limit <= 0` |

**Concurrency / Idempotency-Key:** N/A.

---

### PUT /api/v1/notifications/mark-all-read

**Auth:** Bearer JWT only. **No request body** (explicitly — sending one is simply ignored, there's no bound parameter for it).

**Success 200** (`MarkAllNotificationsReadResult`):
```json
{ "success": true, "data": { "markedCount": 4 } }
```
`markedCount: 0` is a normal 200, not an error — fully idempotent, safe to retry blindly after a dropped connection.

**Full error catalogue:**

| HTTP | Code | Trigger |
|---|---|---|
| 401 | — | missing/invalid JWT |

(No 422 possible — no input.)

**Concurrency / Idempotency-Key:** not required — operation is naturally idempotent via its own semantics (no unread rows ⇒ 0 marked, not an error).

---

### PUT /api/v1/notifications/{id}/read

**Auth:** Bearer JWT only.

**Path params:**

| Param | Type | Required | Example |
|---|---|---|---|
| `id` | guid | yes | `/api/v1/notifications/e1e2e3e4-0000-0000-0000-000000000010/read` |

**No request body.**

**Success 200:** `{ "success": true, "data": null }` — `ApiResponse<object?>` with `data: null`. Marking an already-read notification again also returns this same 200 (idempotent — no distinguishing flag, unlike commit's `alreadyComplete`).

**Full error catalogue:**

| HTTP | Code | Trigger |
|---|---|---|
| 401 | — | missing/invalid JWT |
| 404 | `NOT_FOUND` (generic code — no notification-specific error code exists in the catalogue) | `id` does not exist, OR belongs to a different user — both return the identical 404/message ("الإشعار المطلوب غير موجود") to prevent an existence oracle |

**Concurrency / Idempotency-Key:** ownership + update happen inside a single repository WHERE clause (no read-then-write race window); no `rowVersion` involved; idempotent, no header needed.

---

### POST /api/v1/notifications/device-tokens

**Auth:** Bearer JWT only.

**Request body** (`RegisterDeviceTokenRequest`):

| Field | Type | Required | Validation |
|---|---|---|---|
| `token` | string | yes | `NotEmpty`, min 10 chars, max 512 chars — message "رمز الجهاز غير صحيح" if too short, "رمز الجهاز أطول من المسموح" if too long |
| `platform` | string | yes | must be exactly `android` or `ios` (case-sensitive ordinal match against `DevicePlatform.All`) — message "المنصة يجب أن تكون android أو ios" |

No `userId` field — owner always comes from the JWT.

**Example:**
```json
POST /api/v1/notifications/device-tokens
{
  "token": "fGZ8k...redacted-163-char-fcm-token...Qw1",
  "platform": "android"
}
```

**Success 200:** `{ "success": true, "data": null }`. Re-registering the same token updates the existing row (no duplicate created); one user may register multiple tokens (one per device).

**Full error catalogue:**

| HTTP | Code | Field | Trigger |
|---|---|---|---|
| 401 | — | — | missing/invalid JWT |
| 422 | `VALIDATION_ERROR` | `Token` | empty, or shorter than 10 chars, or longer than 512 chars |
| 422 | `VALIDATION_ERROR` | `Platform` | anything other than exactly `android` or `ios` (e.g. `Android`, `web`, empty) |

Note: request-record defaults (`request.Token ?? string.Empty`, `request.Platform ?? string.Empty`) mean an omitted field in the JSON body becomes an empty string, which then fails `NotEmpty`/`Must(IsValid)` — surfaces as ordinary 422, not a JSON binding error.

**Concurrency / Idempotency-Key:** not needed — upsert semantics on `(userId, token)` make repeated calls naturally idempotent.

**Frontend note:** Web Push is explicitly out of scope — this route exists for the Flutter mobile app only; a web client should not call it.

---

### GET /api/v1/audit-logs

**Auth:** Bearer JWT. **Permission:** `ViewCases` — **note this supersedes an earlier Phase-14 manager-only restriction**; the currently shipped code gates on `ViewCases`, which all four roles hold. (If your documentation elsewhere states "manager-only", that is now stale per the code comment referencing the "Nahda Backend Integration Decisions" doc §20 decision to open visibility to everyone who can view cases.) This endpoint has **no row-level visibility scoping** — unlike every case-derived list — by design, since a filtered audit trail isn't a real audit trail; access is gated only at the door by the one permission check.

**Query params:**

| Param | Type | Required | Notes |
|---|---|---|---|
| `actorId` | guid | no | filters to a specific actor |
| `entityType` | string | no | max 50 chars; documented examples: `case`, `user`, `attachment`, `refresh_token` (not an enum-validated closed list at the code level — any string ≤50 chars passes validation, but only meaningful values will match rows) |
| `entityId` | guid | no | **requires `entityType` to also be present** — otherwise 422 |
| `from` | ISO-8601 datetime (`DateTimeOffset?`) | no | inclusive range start |
| `to` | ISO-8601 datetime (`DateTimeOffset?`) | no | inclusive range end; **must be `>= from`** when both present, else 422 |
| `page` | int | no | default 1; `GreaterThan(0)` — 422 if `<=0` |
| `limit` | int | no | default 20, max 100; `GreaterThan(0)` — 422 if `<=0`, then clamped to 100 |

All filters AND-combined.

**Example:**
```
GET /api/v1/audit-logs?entityType=case&entityId=3fa85f64-5717-4562-b3fc-2c963f66afa6&from=2026-08-01T00:00:00Z&to=2026-09-18T23:59:59Z&page=1&limit=20
```

**Success 200** (`PagedResult<AuditLogListItem>`) — confirmed exact field list:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "f1f2f3f4-0000-0000-0000-000000000020",
        "actorId": "1c2d3e4f-0000-0000-0000-000000000009",
        "actorName": "أحمد محمود",
        "action": "case.status_changed",
        "entityType": "case",
        "entityId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "oldValue": "{\"status\":\"pending_review\"}",
        "newValue": "{\"status\":\"approved\"}",
        "ipAddress": "10.0.4.12",
        "userAgent": "Mozilla/5.0 (...)",
        "requestId": "a1a2a3a4-0000-0000-0000-000000000099",
        "createdAtUtc": "2026-09-18T09:05:12Z"
      }
    ],
    "page": 1, "limit": 20, "total": 1, "totalPages": 1, "hasNext": false, "hasPrev": false
  }
}
```
`actorId`/`actorName` are both nullable (`Guid?`/`string?`) — `null` for system-originated actions (e.g. a scheduled job). `requestId` is `Guid?` (not string). `oldValue`/`newValue` are raw JSON **strings** (not nested objects) as stored — PII-minimal by the writer's own discipline (role names, statuses, field-name lists — never passwords/tokens/national IDs/phone numbers/financial values).

**Full error catalogue:**

| HTTP | Code | Field | Trigger |
|---|---|---|---|
| 401 | — | — | missing/invalid JWT |
| 403 | — | — | caller lacks `ViewCases` |
| 422 | `VALIDATION_ERROR` | `Page` | `page <= 0` |
| 422 | `VALIDATION_ERROR` | `Limit` | `limit <= 0` |
| 422 | `VALIDATION_ERROR` | `EntityType` | > 50 chars |
| 422 | `VALIDATION_ERROR` | `ToUtc` | `to` present, `from` present, and `to < from` — "تاريخ النهاية يجب أن يكون بعد تاريخ البداية" |
| 422 | `VALIDATION_ERROR` | `EntityType` | `entityId` supplied without `entityType` — "يجب تحديد نوع الكيان عند الفلترة بمعرّف الكيان" (error reported against `EntityType`, not `EntityId`) |

**Concurrency / Idempotency-Key:** N/A — append-only, read-only resource; no write/delete endpoint exists for audit logs at all.

**Frontend note:** the `entityId`-requires-`entityType` validation error is attached to the `EntityType` field key in `details`, not `EntityId` — a form that maps 422 field errors 1:1 to the input the user actually filled in (`entityId`) needs a special case, otherwise the error message will appear to "point at the wrong field."

---

### Cross-cutting notes for this group

- **Rate limiting:** `attachments/init` and both `dashboard/*` + `search/cases` routes carry the named `Moderate` policy at code level; `attachments/commit`, `download`, `delete`, `cases/{id}/attachments`, and all `notifications/*`/`audit-logs` routes rely on the global default limiter only (no named override found in source).
- **IDOR convention (404-not-403) applies uniformly** across: attachment case-visibility failures, notification-ownership failures (`N3`), and case-visibility failures surfaced through search/dashboard (though those simply omit rows rather than erroring, since they're always list-shaped).
- **No endpoint in this group requires or supports an `Idempotency-Key` header.** Only `/attachments/{id}/commit`'s own status-based no-op logic and `/notifications/mark-all-read`'s natural idempotency provide retry-safety; `DELETE /attachments/{id}` is explicitly **not** idempotent (second call 404s).
- **`rowVersion`/optimistic concurrency** appears only on `AttachmentListItem` and `CommitUploadResult` as an **output** field (`uint`, Postgres `xmin`) — no endpoint documented here accepts a client-supplied `rowVersion` as an input, so `409 CONCURRENCY_CONFLICT` does not occur on any of these 13 routes today.

### Ambiguities flagged (unconfirmed)

1. Whether `AuditLogEndpoints`'s narrative doc-comment claim ("every user who can view the case can view its audit log") is fully reconciled with older documentation that may still say manager-only — **the shipped code is `Permission.ViewCases`**, treat that as authoritative over any older doc text.
2. `AttachmentListItem.UploadedByName` nullability under a deleted-user scenario is not explicitly exercised in the read code I reviewed — flagged as a defensive assumption, not directly confirmed by a repository implementation read.
3. `entityType` free-text values (`case`, `user`, `attachment`, `refresh_token`) are documentation examples in code comments, not an enforced enum at the validator level — any string ≤ 50 chars passes validation regardless of whether it corresponds to real data.
