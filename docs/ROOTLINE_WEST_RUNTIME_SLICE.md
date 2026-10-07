# Rootline West Bounded Runtime Slice

**Status:** IMPLEMENTED CANDIDATE / NOT MERGED / NOT PLAYER-ACCEPTED

**Base:** production schema-v2 persistence candidate PR #219 at `e1bc3c356a68c47990dd08998467adecd6c0e0f2`.

## Scope

This is the first gameplay consumer of the neutral `routeNetwork` persistence domain.

Exactly one route is player-active in this tranche:

`rootline-west`

## Player loop

1. Discover Rootline West through the existing air-navigation route-discovery system.
2. While physically on the discovered corridor, press **R** to deliberately engage lane assist.
3. Favorable-direction travel receives the bounded prototype benefit.
4. Reverse travel receives no lane benefit.
5. Leaving the corridor releases the ship to ordinary free flight.
6. At high altitude near the known corridor, detect **UPPER WAKE TRACE**.
7. Press **F** while the evidence is in range to rechart Rootline West:
   `OPEN → SHIFTED`.
8. Shifted state removes the ordinary lane-assist benefit at the old corridor.
9. The route condition, clue, and bounded `LOCAL_ROUTE_ASSISTANCE` precedent persist through schema v2.
10. Returning to Wake Dock after the report yields one visible acknowledgement.

## State separation

- Knowledge remains `airNavigation.discoveredRoutes`.
- Objective condition remains `routeNetwork.operationalStates`.
- Lane engagement is transient runtime state and is deliberately not persisted.

## Prototype balance

Current assistance factors remain implementation-test values:
- OPEN: 1.25×
- PROVISIONAL: 1.10×
- SHIFTED/CLOSED: 1.0×

These are not final canon travel speeds.

## Non-goals

No:
- additional route-state gameplay;
- High Sky unlock;
- Auroral routes;
- cave/subsurface content;
- faction reputation system;
- Act II expansion;
- new art admission;
- change to Chapter 1 story progression.

## Acceptance boundary

Automated tests may establish mechanics, persistence wiring, and regression safety.

They do not establish:
- player readability;
- final travel feel;
- visual acceptance;
- final balance.

Human review is still required for the lane/trace/status presentation.
