# API v1 extension (proposal) — owner time slots & walk-in bookings

**Owner:** ok_padel  
**Consumer:** `ClubsApiService` (+ tests + Swagger)

## Time slots (nested)

Base: `/api/v1/clubs/:club_id/courts/:court_id/time_slots`

| Method | Path | Description |
|--------|------|-------------|
| GET | `.../time_slots` | List slots for court (all days) |
| POST | `.../time_slots` | Create slot |
| PATCH | `.../time_slots/:id` | Update slot |
| DELETE | `.../time_slots/:id` | Delete slot |

**Authorization:** `require_club_owner!` + court belongs to `club_id` owned by user.

**POST/PATCH body (JSON):**

```json
{
  "day_of_week": 1,
  "start_time": "10:00",
  "end_time": "11:30",
  "is_available": true
}
```

**422:** overlapping slot (`TimeSlot` validation `:overlapping`), invalid times.

**Response item:**

```json
{
  "time_slot": {
    "id": 1,
    "court_id": 10,
    "day_of_week": 1,
    "start_time": "10:00",
    "end_time": "11:30",
    "is_available": true
  }
}
```

List wrapper: `{ "time_slots": [ ... ] }`.

### Bulk replace (generator)

**POST** `.../time_slots/bulk`

Replaces **all** time slots for the given weekdays on that court with consecutive slots from open to close.

**Body:**

```json
{
  "open_time": "08:00",
  "close_time": "23:00",
  "duration_minutes": 90,
  "day_of_weeks": [1, 2, 3, 4, 5]
}
```

| Field | Rules |
|-------|--------|
| `open_time`, `close_time` | `HH:MM`; `open_time` < `close_time` (same calendar day) |
| `duration_minutes` | Integer > 0 |
| `day_of_weeks` | 1–7 unique integers, each 0–6 |

**Generation:** For each day, create slots `[open, open+dur)`, … while `end <= close`. Partial remainder dropped. All `is_available: true`.

**422 without changes** if future non-cancelled matches on slots to delete.

**Success 201:** `{ "time_slots": [ ... ] }` — all slots for the court (same as GET).

## Walk-in booking (owner)

**POST** `/api/v1/clubs/:club_id/walk_in_bookings`

**Body:**

```json
{
  "court_id": 10,
  "time_slot_id": 5,
  "date": "2026-11-04",
  "walk_in_guest_name": "Juan",
  "walk_in_guest_phone": "+54911..."
}
```

`walk_in_guest_*` optional; omit or null allowed.

**Success 201:** `WalkInBookingResponse` (match summary as in `data-model.md`).

**422 examples:**

- Slot not available / court inactive
- Slot already booked for date
- Date weekday mismatch with slot

**DELETE** `/api/v1/clubs/:club_id/walk_in_bookings/:match_id`

- Cancels walk-in match (status → `cancelled`) if owner authorized and business rules allow.
- **404** foreign club/match; **422** if not cancellable.

## Schedule cell (optional enhancement)

If tooltip needs guest label without second fetch, extend `cells[]` with optional:

```json
{
  "walk_in_guest_name": "Juan"
}
```

Only when state is `booked` and match is walk-in. **Defer** if match detail fetch is enough for v1.

## Migration (ok_padel)

```ruby
add_column :matches, :walk_in_guest_name, :string
add_column :matches, :walk_in_guest_phone, :string
# optional: add_column :matches, :walk_in, :boolean, default: false, null: false
```

Index/uniqueness: consider unique partial index on `(time_slot_id, date)` for non-cancelled matches to enforce concurrency (research edge case).
