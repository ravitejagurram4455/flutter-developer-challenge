# Trip Planner

TUI Mobility Hub Flutter code challenge: browse destinations, pick two cities and
see the cheapest route, its legs and total price, and the route on a map.

Built with Flutter 3.47.9 and Dart 3.13.7.

## Run it

Start the API first, from the supplied `api` directory:

```bash
cd api
python3 simple_server.py          # or the FastAPI option in api/README.md
```

Then run the app. The base URL is set with `API_BASE_URL` and defaults to
`http://localhost:8000`.

| Target | Command |
| --- | --- |
| iOS simulator | `flutter run -d <simulator-id>` |
| macOS | `flutter run -d macos` |
| Web | `flutter run -d chrome` |
| Android emulator | `flutter run -d <emulator-id> --dart-define=API_BASE_URL=http://10.0.2.2:8000` |
| Physical device | `flutter run -d <device-id> --dart-define=API_BASE_URL=http://<your-computer-LAN-IP>:8000` |

Cleartext HTTP is allowed on Android in debug builds only, so a release build
needs an HTTPS API. On iOS, `NSAllowsLocalNetworking` permits local connections.

```bash
flutter analyze
flutter test
```

Tests need neither the API nor the sample dataset.

## Architecture

Feature-first, with dependencies pointing inward:

```text
lib/
  core/                  config, failures, HTTP client, theme
  features/trip_planner/
    domain/              entities, TripRepository, RouteFinder, DijkstraRouteFinder
    data/                DTOs and parsing, remote data source, repository
    presentation/        cubit, screen, widgets
```

- **Domain** is pure Dart. Its only package imports are `equatable` and
  `collection`, so route finding runs with no network or UI.
- **Data** parses JSON into DTOs, validates them and maps them to entities. It
  turns every expected error into a sealed `Failure`.
- **Presentation** has one `TripPlannerCubit` with a sealed state (`Loading`,
  `LoadFailure`, `Ready`) and a sealed route result (none selected, found, not
  found). The UI switches over them exhaustively. The cubit also remembers the
  selected cities, so a reload or retry keeps them while they are still in the
  data.
- Dependencies are passed through constructors and wired in `app.dart` with
  `RepositoryProvider` and `BlocProvider`.

## Cheapest-route algorithm

Dijkstra's algorithm with a priority queue, over a directed graph.

- **Time:** O((V + E) log E) for V cities and E connections. Since E ≤ V² when
  parallel connections are collapsed, log E is at most about 2 log V.
- **Space:** O(V + E).
- **Parallel connections and cycles:** only the cheapest way to reach a city is
  kept, so both are handled without special cases.
- **Ties:** routes compare by price, then by number of legs. The fewer-legs rule
  also means a zero-price cycle can never improve a route.
- **Negative prices:** Dijkstra can't guarantee a correct answer with them. The
  finder throws, and the repository rejects them earlier as a `DataFailure`, so
  the user sees the error state with a retry option.

## Key decisions

- **Prices are integer cents.** They are converted when parsed and summed as
  integers, so totals have no floating-point error. Amounts are rounded to 2
  decimal places.
- **No currency symbol**, because the API doesn't provide a currency.
- **One malformed record fails the whole load.** Skipping it could silently hide
  the cheapest route. Out-of-range coordinates count as malformed.
- **Only `/connections` is required.** Both requests run in parallel. If
  `/cities` fails, routes still work: every city comes from the connections, the
  carousel shows image placeholders, and a notice offers a retry.
- **The city list comes from the data.** It combines `/cities` with any city that
  only appears in `/connections`; those cities show an image fallback.
- **Each leg uses its own coordinates**, so no per-city coordinates are needed.
  The map appears only once there is a route, so no initial view is hard-coded.
- **Image URLs are resolved against the base URL**, whether relative or absolute
  on a loopback host, so they also work on an emulator or device.
- **The route updates as soon as both cities are valid**, so there is no search
  button. If both are the same city, the UI explains that and shows no route.
- **The map is passed to the screen as a builder**, so widget tests replace it and
  never request tiles.
- **Routes across the antimeridian stay in view.** flutter_map draws each leg the
  short way, for example Los Angeles→Tokyo across the Pacific. The camera fits a
  path whose longitudes follow those legs, built by `routePath`, because
  `LatLngBounds` would clamp it to ±180° and centre the map on the wrong side of
  the world.

## Assumptions

- Connections are directed. In the sample, London→Tokyo and Tokyo→London have
  different prices, and Porto has no outbound flights.
- All prices share one currency and have at most 2 meaningful decimal places.
- City names are identifiers: the route finder matches them exactly. The text
  fields match them case-insensitively.
- A trip from a city to itself is not a route, even if a cycle exists.

## Dependencies

| Package | Why |
| --- | --- |
| `flutter_bloc` | Cubit state management and dependency providers |
| `equatable` | Value equality for states and entities |
| `http` | Small HTTP client, with `MockClient` for tests; `dio`'s extras aren't needed |
| `collection` | `PriorityQueue` for Dijkstra |
| `flutter_map` | OpenStreetMap map with no API key |
| `latlong2` | Coordinate type required by `flutter_map` |
| `flutter_svg` | Renders the API's SVG images, with an error fallback |
| `bloc_test` (dev) | Concise cubit tests |
| `mocktail` (dev) | Mocks without code generation |

## Trade-offs

- **Straight map lines:** legs are straight on the map, not great-circle arcs, so
  long flights don't show the true flight path.
- **Full reload on retry:** retrying after a missing `/cities` reloads both
  endpoints, with a short loading state, rather than fetching only the images.
- **Public OSM tiles:** fine for a demo, and the app identifies itself and shows
  attribution, but production use needs a tile provider suited to the traffic.

## With more time

- Draw legs as great-circle arcs.
- Show the map and carousel side by side on wide screens.
- Add real currency support if the API provides it.
- Add an integration test suite to the repo and run it in CI.

## Verification

Run on Flutter 3.47.9 / Dart 3.13.7:

- `flutter analyze`: no issues.
- `flutter test`: 106 tests, all passed.
- Debug builds for web, macOS, the iOS simulator and Android succeed.

End to end against the running API, using a temporary driver that isn't part of
this repo:

| Target | Result |
| --- | --- |
| iOS simulator (FastAPI) | Swipe, no route, same city, and London→Sydney = 320 passed. Map tiles seen. |
| iOS simulator (different dataset) | A 3-leg route beat the direct flights, with a decimal total, non-ASCII names and identical coordinates. A negative price showed the error state. |
| Android emulator (`10.0.2.2`) | Same flow passed. Images and map tiles seen. |
| macOS | Same flow passed. Map not visually checked. |
| Web (Chrome, headless) | App loaded with API data and images. Route flow and map not exercised. |

After the review fixes, the app was relaunched on the iOS simulator: it loaded
normally, and with `/cities` returning 500 it still loaded, with the notice and
image placeholders. The antimeridian camera fit was checked by rendering the map
in a test. The full route flow was not repeated by hand.

Not verified: a physical device, Linux and Windows, or a release build.
