# Pandora

A **MicroApp Container Platform** for iOS built with **SwiftUI** and **SwiftData**.

Pandora is a modular application where self-contained feature modules (MicroApps) are discovered, registered, and launched from a central Hub. Each MicroApp owns its own Domain, Data, and Presentation layers — and can be added or removed with a single line of code.

---

## ✨ Features

- **Modular MicroApp system** — plug-and-play feature modules
- **Clean Architecture** — Domain / Data / Presentation separation per module
- **SwiftData persistence** — dynamic schema collection from MicroApps
- **Protocol-driven boundaries** — every cross-module dependency is abstracted
- **Composition Root** — single entry point wires all concrete types
- **Type-safe navigation** — Coordinator pattern with deep link support

### Current MicroApps

| MicroApp | Description | Architecture |
|---|---|---|
| **Hub** | Launcher & discovery dashboard | Simplified MVVM |
| **Reeeee** | Phone throw tracker with physics | Full Clean Architecture |

---

## 📁 Project Structure

```
Pandora/
├── App/
│   └── PandoraApp.swift              # Composition root: registration, ModelContainer, DI
│
├── Core/                              # Shared Infrastructure
│   ├── DependencyInjection/
│   │   └── DIContainer.swift         # DI container & @Injected wrapper
│   ├── Navigation/
│   │   └── Router.swift              # Coordinator pattern navigation
│   ├── Protocol/
│   │   ├── MicroAppProvider.swift    # MicroApp interface, metadata, AnyMicroApp
│   │   └── UseCase.swift             # Generic UseCase protocols
│   ├── Registry/
│   │   └── MicroAppRegistry.swift    # Decoupled MicroApp discovery registry
│   ├── Repository/
│   │   └── Repository.swift          # Repository protocol, SwiftDataRepository<T>, AnyRepository<T>
│   └── Theme/
│       └── PandoraTheme.swift        # Design system constants
│
├── MicroApp/                          # Self-Contained Feature Modules
│   ├── Hub/                           # Hub MicroApp (launcher)
│   │   ├── Presentation/
│   │   │   ├── HubView.swift
│   │   │   ├── HubViewModel.swift
│   │   │   └── Components/
│   │   │       └── HubCard.swift
│   │   └── HubMicroApp.swift
│   │
│   └── Reeeee/                        # Reeeee MicroApp (phone throw tracker)
│       ├── Domain/
│       │   ├── Model/
│       │   │   └── ReeeeeModel.swift  # @Model class (SwiftData)
│       │   └── UseCase/
│       │       └── ReeeeeUseCases.swift
│       ├── Data/
│       │   └── ReeeeeRepository.swift # Factory → AnyRepository<ReeeeeModel>
│       ├── Presentation/
│       │   ├── ReeeeeView.swift
│       │   └── ReeeeeViewModel.swift  # + MotionServiceProtocol, AudioServiceProtocol
│       └── ReeeeeMicroApp.swift       # Entry point + ReeeeeContainerView
│
├── Shared/
│   └── Components/
│       ├── PandoraButton.swift
│       ├── PandoraCard.swift
│       └── ViewModifiers.swift
│
└── Resources/
    └── Assets.xcassets/
```

---

## 🏗️ Architecture

### Layers

| Layer | Location | Responsibility |
|---|---|---|
| **Presentation** | `MicroApp/*/Presentation/`, `Shared/Components/` | UI, ViewModels, user interactions |
| **Domain** | `MicroApp/*/Domain/` | Business rules, use cases, models |
| **Data** | `Core/Repository/`, `MicroApp/*/Data/` | Persistence via SwiftData |
| **Infrastructure** | `Core/` | Navigation, DI, registry, protocols, theme |

### Dependency Direction

All dependencies point **inward** — outer layers depend on inner layers, never the reverse.

```
┌──────────────────────────────────────────────┐
│  Presentation (Views, ViewModels)            │
│    ↓ depends on                              │
│  ┌────────────────────────────────────────┐  │
│  │  Domain (UseCases, Models)             │  │
│  │    ↓ depends on                        │  │
│  │  ┌──────────────────────────────────┐  │  │
│  │  │  Core (Protocols, Abstractions)  │  │  │
│  │  └──────────────────────────────────┘  │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

**Boundary rules:**
- ViewModel → `AnyRepository<T>` (never `SwiftDataRepository`)
- ViewModel → `MotionServiceProtocol` (never `CMMotionManager`)
- ViewModel → `AudioServiceProtocol` (never `AudioService`)
- HubViewModel → `MicroAppRegistryProtocol` (never `MicroAppRegistry`)
- Only `Data/` factories and `PandoraApp` touch concrete types

---

## 🎨 Design Patterns

| Pattern | Where | Why |
|---|---|---|
| **MVVM** | All Views + ViewModels | Separate UI from business logic |
| **Repository** | `Core/Repository/`, `MicroApp/*/Data/` | Abstract persistence layer |
| **Use Case / Interactor** | `MicroApp/*/Domain/UseCase/` | Single-responsibility business ops |
| **Dependency Injection** | `Core/DependencyInjection/` | Loose coupling, testability |
| **Coordinator** | `Core/Navigation/Router.swift` | Centralized navigation + deep links |
| **Factory** | Throughout | Controlled object creation with DI |
| **Strategy** | `MicroAppProvider` protocol | Pluggable feature implementations |
| **Type Erasure** | `AnyMicroApp`, `AnyRepository<T>` | Heterogeneous collections |
| **Registry** | `Core/Registry/MicroAppRegistry.swift` | Decoupled MicroApp discovery |
| **Composition Root** | `PandoraApp.swift` | Single place knowing all concretes |
| **Protocol-Oriented** | Throughout | Flexibility, testability, abstraction |

---

## 🔄 Data Flow

### SwiftData Persistence Pipeline

```
PandoraApp (creates ModelContainer from MicroApp-declared schemas)
    ↓  .modelContainer(modelContainer)
SwiftUI Environment (injects ModelContext)
    ↓  @Environment(\.modelContext)
ReeeeeContainerView (bridges environment → ViewModel)
    ↓  ReeeeeRepositoryFactory.makeRepository(modelContext:)
AnyRepository<ReeeeeModel> (type-erased abstraction)
    ↓  injected into ViewModel
ReeeeeViewModel (calls repository.save / fetchAll / deleteAll)
    ↓
SwiftDataRepository<ReeeeeModel> (concrete, talks to ModelContext)
    ↓
SQLite (managed by SwiftData)
```

### MicroApp Discovery Flow

```
PandoraApp.registerMicroApps()          ← composition root
    ↓  MicroAppRegistry.shared.register(ReeeeeMicroApp())
MicroAppRegistry (shared singleton)
    ↓  conforms to MicroAppRegistryProtocol
HubViewModel(registry:)                 ← injected via protocol
    ↓  reads registry.registeredApps
HubView                                 ← displays cards
    ↓  user taps a card
Router.navigateToMicroApp(id)
    ↓
NavigationStack → MicroApp.makeView()   ← renders feature
```

---

## 🚀 Adding a New MicroApp

### 1. Create the module structure

```
MicroApp/NewFeature/
├── Domain/
│   ├── Model/
│   │   └── NewFeatureModel.swift      ← @Model class
│   └── UseCase/
│       └── NewFeatureUseCases.swift
├── Data/
│   └── NewFeatureRepository.swift     ← Factory → AnyRepository<NewFeatureModel>
├── Presentation/
│   ├── NewFeatureView.swift
│   └── NewFeatureViewModel.swift
└── NewFeatureMicroApp.swift           ← MicroAppProvider conformance
```

### 2. Define your SwiftData model

```swift
import SwiftData

@Model
final class NewFeatureModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
```

### 3. Create the MicroApp entry point

```swift
struct NewFeatureMicroApp: MicroAppProvider {
    let metadata = MicroAppMetadata(
        id: "com.pandora.newfeature",
        name: "New Feature",
        iconName: "star",
        tintColor: .blue
    )
    
    var modelTypes: [any PersistentModel.Type] {
        [NewFeatureModel.self]
    }
    
    func makeView() -> some View {
        NewFeatureContainerView()
    }
}
```

### 4. Register in `PandoraApp.swift` (one line)

```swift
private static func registerMicroApps() {
    let registry = MicroAppRegistry.shared
    registry.register(ReeeeeMicroApp())
    registry.register(NewFeatureMicroApp())  // ← add this
}
```

**That's it.** Schema, discovery, and navigation wire up automatically.

- ✅ **Zero changes** to Hub, Router, or any other MicroApp
- ✅ **SwiftData schema** auto-collected via `modelTypes`
- ✅ **Delete the folder** to remove the feature entirely

---

## 🧪 Testability

Every dependency is injectable via protocol:

| Dependency | Protocol | Concrete | Mock |
|---|---|---|---|
| Persistence | `AnyRepository<ReeeeeModel>` | `SwiftDataRepository` | In-memory array |
| Motion | `MotionServiceProtocol` | `CMMotionManager` | Simulated freefall |
| Audio | `AudioServiceProtocol` | `AudioService` | No-op player |
| Registry | `MicroAppRegistryProtocol` | `MicroAppRegistry` | Pre-loaded list |

### Mock Example

```swift
@MainActor
class MockReeeeeRepository {
    var records: [ReeeeeModel] = []
    func save(_ entity: ReeeeeModel) throws { records.append(entity) }
    func fetchAll() throws -> [ReeeeeModel] { records }
    func deleteAll() throws { records.removeAll() }
}

class MockMotionService: MotionServiceProtocol {
    var isAccelerometerAvailable = true
    var accelerometerUpdateInterval: TimeInterval = 0.01
    func startAccelerometerUpdates(to queue: OperationQueue,
                                   withHandler handler: @escaping (CMAccelerometerData?, Error?) -> Void) {}
    func stopAccelerometerUpdates() {}
}

// Usage:
let vm = ReeeeeViewModel(
    repository: AnyRepository(mockRepo),
    motionManager: MockMotionService(),
    audioService: MockAudioService()
)
```

---

## 🎯 SOLID Principles

| Principle | Application |
|---|---|
| **Single Responsibility** | `Router` → navigation only, `SwiftDataRepository` → persistence only |
| **Open/Closed** | New MicroApps extend `MicroAppProvider` — no existing code changes |
| **Liskov Substitution** | Any `MotionServiceProtocol` implementation works in the ViewModel |
| **Interface Segregation** | `MotionServiceProtocol` exposes 4 members, not the full `CMMotionManager` API |
| **Dependency Inversion** | ViewModels depend on `AnyRepository<T>`, never `SwiftDataRepository` |

---

## 🔐 Best Practices

### Use protocol abstractions at boundaries
```swift
// ✅ Good
class ViewModel {
    let repository: AnyRepository<MyModel>
    let motionService: MotionServiceProtocol
}

// ❌ Bad
class ViewModel {
    let repository: SwiftDataRepository<MyModel>
    let motionManager: CMMotionManager
}
```

### Register MicroApps only in the composition root
```swift
// ✅ Good — PandoraApp.swift
MicroAppRegistry.shared.register(ReeeeeMicroApp())

// ❌ Bad — HubViewModel knows concrete types
microApps.append(AnyMicroApp(ReeeeeMicroApp()))
```

### Let MicroApps declare their own schemas
```swift
// ✅ Good — MicroApp declares its models
var modelTypes: [any PersistentModel.Type] { [ReeeeeModel.self] }

// ❌ Bad — PandoraApp hardcodes all schemas
let schema = Schema([ReeeeeModel.self, FooModel.self, BarModel.self])
```

---

## 📚 Key Technologies

| Technology | Purpose |
|---|---|
| **SwiftUI** | Declarative UI framework |
| **SwiftData** | Persistence via `@Model`, `ModelContainer`, `ModelContext` |
| **Observation** | Modern state management (`@Observable` macro) |
| **NavigationStack** | Type-safe navigation with `NavigationPath` |
| **CoreMotion** | Accelerometer data (behind `MotionServiceProtocol`) |
| **AVFoundation** | Audio playback (behind `AudioServiceProtocol`) |

---

## ⚠️ Key Architectural Decisions

1. **MicroApps are self-contained** — each owns Domain, Data, and Presentation layers.

2. **PandoraApp is the composition root** — the only file that knows about all concrete types. Adding a new MicroApp requires editing only this file.

3. **SwiftData schemas are collected dynamically** — each MicroApp declares `modelTypes`, and `PandoraApp` builds the `ModelContainer` by aggregating them through the registry.

4. **Concrete types are hidden behind abstractions** — `AnyRepository<T>` hides `SwiftDataRepository`, `MotionServiceProtocol` hides `CMMotionManager`, `MicroAppRegistryProtocol` hides `MicroAppRegistry`.

5. **Right-sized architecture per module** — Hub uses simplified MVVM (no business logic), Reeeee uses full Clean Architecture (complex physics + persistence).

---

## 🔮 Future Enhancements

- Unit tests for all modules
- CI/CD pipeline
- Extract MicroApps to Swift Packages
- Networking layer with Repository pattern
- Analytics and telemetry
- Localization support

---

**Version**: 3.0.0  
**Last Updated**: February 21, 2026
