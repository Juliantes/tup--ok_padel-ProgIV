# UI contract — `/club` (club owner)

**Component shell:** `src/app/club/club-owner.ts`  
**Route:** `club.routes.ts` → path `club`  
**i18n prefix:** `CLUB_OWNER.*` in `public/assets/i18n/es.json` (and en if present)

## Layout regions

1. **Club switcher** (if `clubs.length > 1`) — tabs/chips.
2. **Hero** — club name, address, WhatsApp contact link (not booking).
3. **Date strip** — `buildScheduleDateOptions()`; selects ISO date.
4. **Court pills** — all courts from `listCourts` fallback.
5. **Schedule grid** — table: time column + one column per court.

## Overlays (same route, FR-012)

| Overlay | Trigger | Purpose |
|---------|---------|---------|
| Court form dialog | FAB or “Gestionar canchas” | Create/edit/delete court |
| Time slots panel | Per-court action from pill or grid header | CRUD `OwnerTimeSlot` |
| Walk-in dialog | Click `available` cell | Confirm booking + optional guest fields |
| Cancel confirm | Click `booked` cell (walk-in) | FR-011 |

Dialogs use Angular Material (`MatDialog`); panel may be `MatSidenav` or bottom sheet on narrow viewports.

## Cell interaction rules

- `available`: primary button “Reservar” / confirm in app — **no** WhatsApp (FR-013).
- `booked`: show occupied state; action “Liberar” if API returns cancellable walk-in (use `match_id` from cell).
- `blocked` / `empty`: no booking CTA; optional hint to configure slots.

## Error presentation

- Use `readApiErrorMessage(error)` for HTTP failures (FR-010).
- Optimistic UI **not** used for booking/cancel; refresh schedule on success (FR-008).

## Accessibility

- Grid headers `scope="col"` / `scope="row"` (existing pattern).
- Dialogs: focus trap, `role="alert"` on errors.

## Tests (constitution II)

| File | Covers |
|------|--------|
| `club-owner.spec.ts` | Grid states, dialog open, API mocks |
| `club-schedule.utils.spec.ts` | Unchanged helpers |
| New `*.spec.ts` per dialog if standalone components |
