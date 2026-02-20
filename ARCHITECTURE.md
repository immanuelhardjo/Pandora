# Pandora Architecture Documentation

## Overview

Pandora is a **MicroApp Container** built with **Clean Architecture** principles, following industry-standard design patterns for maintainability, testability, and scalability. Persistence is powered by **SwiftData**, and all cross-module boundaries are enforced through **protocol abstractions**.

---

## 🏗️ Architecture Layers

### 1. **Presentation Layer** (UI)
- **Location**: `MicroApp/`, `Shared/Components/`
- **Responsibility**: User interface and user interactions
- **Pattern**: MVVM (Model-View-ViewModel)
- **Components**:
  - **Views**: SwiftUI views (HubView, ReeeeeView, etc.)
  - **ViewModels**: Observable state managers (@Observable classes)
  - **Components**: Reusable UI components (PandoraButton, PandoraCard)

### 2. **Domain Layer** (Business Logic)
- **Location**: `MicroApp/{FeatureName}/Domain/`
- **Responsibility**: Business rules and application logic specific to each MicroApp
- **Pattern**: Use Case / Interactor pattern
- **Components**:
  - **Use Cases**: Single-responsibility business operations
  - **Domain Models**: Core entities (e.g., ReeeeeModel as SwiftData `@Model`)
  - **Protocols**: Defining contracts within the MicroApp
- **Note**: Each MicroApp owns its business logic for true modularity

### 3. **Data Layer** (Persistence)
- **Location**: `Core/Repository/` (protocol + generic impl) + `MicroApp/{FeatureName}/Data/` (factories)
- **Responsibility**: Data access and persistence via SwiftData
- **Pattern**: Repository pattern with Type Erasure
- **Components**:
  - **Core Protocol**: Generic `Repository` protocol requiring `PersistentModel`
  - **Generic Implementation**: `SwiftDataRepository<T>` backed by `ModelContext`
  - **Type-Erased Wrapper**: `AnyRepository<T>` for crossing abstraction boundaries
  - **MicroApp Factories**: Feature-specific repository factories (e.g., `ReeeeeRepositoryFactory`)

### 4. **Infrastructure Layer** (Core Services)
- **Location**: `Core/`
- **Responsibility**: Cross-cutting concerns shared across all modules
- **Components**:
  - **Navigation**: Router (Coordinator pattern)
  - **DI Container**: Dependency injection via Service Locator + `@Injected` wrapper
  - **Registry**: `MicroAppRegistry` for decoupled MicroApp discovery
  - **Protocols**: `MicroAppProvider`, `UseCase`, `Repository` interfaces
  - **Theme**: Design system and styling constants

---

## 🎨 Design Patterns Used

### 1. **MVVM (Model-View-ViewModel)**
- **Where**: All Views and ViewModels
- **Why**: Separation of UI logic from business logic
- **Example**: `HubView` + `HubViewModel`, `ReeeeeView` + `ReeeeeViewModel`

### 2. **Repository Pattern**
- **Where**: `Core/Repository/`, `MicroApp/*/Data/`
- **Why**: Abstract data persistence for testability and swappability
- **Implementation**: `Repository` protocol → `SwiftDataRepository<T>` → `AnyRepository<T>`
- **Key**: ViewModel and UseCases depend on `AnyRepository<T>`, never on the concrete class

### 3. **Use Case / Interactor Pattern**
- **Where**: `MicroApp/*/Domain/UseCase/`
- **Why**: Encapsulate single business operations
- **Example**: `SaveReeeeeRecordUseCase`, `DetectFreefallUseCase`

### 4. **Dependency Injection (DI)**
- **Where**: `Core/DependencyInjection/`
- **Why**: Loose coupling, better testability
- **Pattern**: Service Locator + Property Wrapper
- **Example**: `DIContainer`, `@Injected` property wrapper

### 5. **Coordinator Pattern**
- **Where**: `Core/Navigation/Router.swift`
- **Why**: Centralized navigation logic
- **Features**: 
  - Type-safe routing via `AppRoute` enum
  - Deep link support (`pandora://microapp/{id}`)
  - Navigation history tracking

### 6. **Factory Pattern**
- **Where**: Throughout (Factories for ViewModels, Repositories, Router, etc.)
- **Why**: Centralized object creation with proper dependency wiring
- **Examples**: `RouterFactory`, `HubViewModelFactory`, `ReeeeeViewModelFactory`, `ReeeeeRepositoryFactory`

### 7. **Strategy Pattern**
- **Where**: `MicroAppProvider` protocol
- **Why**: Pluggable MicroApp implementations with identical interface
- **Example**: Different MicroApps implement `MicroAppProvider` and are discovered at runtime

### 8. **Type Erasure**
- **Where**: `AnyMicroApp`, `AnyRepository<T>`
- **Why**: Store heterogeneous types in homogeneous collections; cross abstraction boundaries
- **Example**: `AnyMicroApp` wraps any `MicroAppProvider` with associated types

### 9. **Registry Pattern**
- **Where**: `Core/Registry/MicroAppRegistry.swift`
- **Why**: Decouple MicroApp discovery from the Hub module
- **Flow**: `PandoraApp` registers concrete MicroApps → `HubViewModel` reads via `MicroAppRegistryProtocol`

### 10. **Protocol-Oriented Design**
- **Where**: Throughout the entire codebase
- **Why**: Flexibility, testability, abstraction
- **Examples**: `RouterProtocol`, `HubViewModelProtocol`, `Repository`, `MotionServiceProtocol`, `AudioServiceProtocol`, `MicroAppRegistryProtocol`

### 11. **Composition Root**
- **Where**: `PandoraApp.swift`
- **Why**: Single place that knows about all concrete types
- **What it does**: Registers MicroApps, creates ModelContainer, wires core dependencies

---

## 📁 Project Structure

```
Pandora/
├── App/
│   └── PandoraApp.swift              # Composition root: registration, ModelContainer, DI
│
├── Core/                              # Infrastructure & Core Services (SHARED ONLY)
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
├── MicroApp/                          # Feature Modules (SELF-CONTAINED)
│   ├── Hub/                           # Hub MicroApp (launcher)
│   │   ├── Presentation/
│   │   │   ├── HubView.swift
│   │   │   ├── HubViewModel.swift
│   │   │   └── Components/
│   │   │       └── HubCard.swift
│   │   └── HubMicroApp.swift
│   │
│   └── Reeeee/                        # Reeeee (Yeet) MicroApp — FULLY MODULAR
│       ├── Domain/                    # Business Logic Layer
│       │   ├── Model/
│       │   │   └── ReeeeeModel.swift  # @Model class (SwiftData)
│       │   └── UseCase/
│       │       └── ReeeeeUseCases.swift
│       ├── Data/                      # Data Layer
│       │   └── ReeeeeRepository.swift # Factory → AnyRepository<ReeeeeModel>
│       ├── Presentation/              # Presentation Layer
│       │   ├── ReeeeeView.swift
│       │   └── ReeeeeViewModel.swift  # + MotionServiceProtocol, AudioServiceProtocol
│       └── ReeeeeMicroApp.swift       # Entry point + ReeeeeContainerView
│
├── Shared/                            # Shared UI Resources
│   └── Components/
│       ├── PandoraButton.swift
│       ├── PandoraCard.swift
│       └── ViewModifiers.swift
│
└── Resources/
    └── Assets.xcassets/
```

---

## 🔄 Data Flow

### Persistence: SwiftData Pipeline

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

### MicroApp Discovery

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
NavigationStack → destinationView(for:)
    ↓
MicroApp.makeView()                     ← renders feature
```

### Example: Loading Reeeee History

```
ReeeeeView
    ↓  @State viewModel
ReeeeeViewModel.loadHistory()
    ↓  repository.fetchAll()
AnyRepository<ReeeeeModel>
    ↓  delegates to SwiftDataRepository
ModelContext.fetch(FetchDescriptor<ReeeeeModel>)
    ↓  returns [ReeeeeModel]
ViewModel.history = records
    ↓  @Observable triggers UI update
ReeeeeView re-renders history list
```

---

## 🔀 Dependency Direction

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

**Key boundary rules:**
- ViewModel → `AnyRepository<T>` (never `SwiftDataRepository`)
- ViewModel → `MotionServiceProtocol` (never `CMMotionManager`)
- ViewModel → `AudioServiceProtocol` (never `AudioService`)
- HubViewModel → `MicroAppRegistryProtocol` (never `MicroAppRegistry`)
- UseCases → `AnyRepository<T>` (never concrete)
- Only `Data/` factories and `PandoraApp` touch concrete types

---

## 🧪 Testability

### Unit Testing Strategy

Every dependency in the Reeeee module is injectable via protocol:

| Dependency | Protocol | Concrete | Mock Example |
|---|---|---|---|
| Persistence | `AnyRepository<ReeeeeModel>` | `SwiftDataRepository` | In-memory array |
| Motion | `MotionServiceProtocol` | `CMMotionManager` | Simulated freefall |
| Audio | `AudioServiceProtocol` | `AudioService` | No-op player |
| Registry | `MicroAppRegistryProtocol` | `MicroAppRegistry` | Pre-loaded list |

### Mocking Example

```swift
// Mock repository backed by an in-memory array
@MainActor
class MockReeeeeRepository {
    var records: [ReeeeeModel] = []
    
    func save(_ entity: ReeeeeModel) throws { records.append(entity) }
    func fetchAll() throws -> [ReeeeeModel] { records }
    func deleteAll() throws { records.removeAll() }
}

// Mock motion service for simulating throws
class MockMotionService: MotionServiceProtocol {
    var isAccelerometerAvailable = true
    var accelerometerUpdateInterval: TimeInterval = 0.01
    
    private var handler: ((CMAccelerometerData?, Error?) -> Void)?
    
    func startAccelerometerUpdates(to queue: OperationQueue,
                                   withHandler handler: @escaping (CMAccelerometerData?, Error?) -> Void) {
        self.handler = handler
    }
    
    func stopAccelerometerUpdates() { handler = nil }
    
    // Test helper: simulate freefall / impact
    func simulateAcceleration(_ data: CMAccelerometerData) {
        handler?(data, nil)
    }
}

// Usage in tests:
let vm = ReeeeeViewModel(
    repository: AnyRepository(mockRepo),
    motionManager: MockMotionService(),
    audioService: MockAudioService()
)
```

---

## 🎯 SOLID Principles

### Single Responsibility
- Each class has one reason to change
- `Router` → navigation only, `SwiftDataRepository` → persistence only, `ReeeeeViewModel` → Reeeee state only

### Open/Closed
- Open for extension, closed for modification
- New MicroApps extend `MicroAppProvider` and register in `PandoraApp` — no existing code changes

### Liskov Substitution
- Any `MotionServiceProtocol` implementation works in the ViewModel
- Any `AnyRepository<ReeeeeModel>` works regardless of backing store

### Interface Segregation
- `MotionServiceProtocol` exposes only what the ViewModel needs (4 members), not the full `CMMotionManager` API
- `MicroAppRegistryProtocol` exposes only `registeredApps`, not mutation methods

### Dependency Inversion
- ViewModel depends on `AnyRepository<T>`, `MotionServiceProtocol`, `AudioServiceProtocol`
- Never on `SwiftDataRepository`, `CMMotionManager`, or `AudioService`

---

## 🚀 Adding a New MicroApp

### Step-by-Step

#### 1. Create the module structure:

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

#### 2. Define your SwiftData model:

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

#### 3. Create the MicroApp entry point:

```swift
struct NewFeatureMicroApp: MicroAppProvider {
    let metadata = MicroAppMetadata(
        id: "com.pandora.newfeature",
        name: "New Feature",
        iconName: "star",
        tintColor: .blue
    )
    
    // Declare your SwiftData models here
    var modelTypes: [any PersistentModel.Type] {
        [NewFeatureModel.self]
    }
    
    func makeView() -> some View {
        NewFeatureContainerView()
    }
}
```

#### 4. Register in `PandoraApp.swift` (one line):

```swift
private static func registerMicroApps() {
    let registry = MicroAppRegistry.shared
    registry.register(ReeeeeMicroApp())
    registry.register(NewFeatureMicroApp())  // ← add this
}
```

**That's it.** The ModelContainer schema, Hub discovery, and navigation all wire up automatically.

#### 5. Benefits:
- ✅ **Zero changes** to Hub, Router, or any other MicroApp
- ✅ **SwiftData schema** auto-collected via `modelTypes`
- ✅ **Discovery** auto-collected via `MicroAppRegistry`
- ✅ **Delete the folder** to remove the feature entirely

---

## 🔐 Best Practices

### 1. Always use protocol abstractions at boundaries
```swift
// ✅ Good — depends on abstraction
class ViewModel {
    let repository: AnyRepository<MyModel>
    let motionService: MotionServiceProtocol
}

// ❌ Bad — depends on concrete
class ViewModel {
    let repository: SwiftDataRepository<MyModel>
    let motionManager: CMMotionManager
}
```

### 2. Use factories for object creation
```swift
// ✅ Good
let router = RouterFactory.makeRouter()
let repo = ReeeeeRepositoryFactory.makeRepository(modelContext: context)

// ❌ Bad
let router = Router()
let repo = SwiftDataRepository<ReeeeeModel>(modelContext: context)
```

### 3. Register MicroApps only in the composition root
```swift
// ✅ Good — PandoraApp.swift (composition root)
private static func registerMicroApps() {
    MicroAppRegistry.shared.register(ReeeeeMicroApp())
}

// ❌ Bad — HubViewModel directly instantiates MicroApps
private func registerDefaultMicroApps() {
    microApps.append(AnyMicroApp(ReeeeeMicroApp()))
}
```

### 4. Let MicroApps declare their own schemas
```swift
// ✅ Good — MicroApp declares its models
var modelTypes: [any PersistentModel.Type] { [ReeeeeModel.self] }

// ❌ Bad — PandoraApp hardcodes all schemas
let schema = Schema([ReeeeeModel.self, FooModel.self, BarModel.self])
```

### 5. Handle errors gracefully
```swift
// ✅ Good
do {
    try repository.save(record)
} catch {
    print("⚠️ Failed to save: \(error)")
}
```

---

## 📚 Key Technologies

| Technology | Purpose |
|---|---|
| **SwiftUI** | Declarative UI framework |
| **SwiftData** | Persistence via `@Model`, `ModelContainer`, `ModelContext` |
| **Observation** | Modern state management (`@Observable` macro) |
| **Async/Await** | Modern concurrency for UseCases |
| **NavigationStack** | Type-safe navigation with `NavigationPath` |
| **CoreMotion** | Accelerometer data (behind `MotionServiceProtocol`) |
| **AVFoundation** | Audio playback (behind `AudioServiceProtocol`) |

---

## 📝 Notes

- This architecture is **scalable**: Add MicroApps with one registration line
- This architecture is **testable**: Every dependency is injectable via protocol
- This architecture is **maintainable**: Clear separation of concerns, no cross-module coupling
- This architecture is **decoupled**: Hub doesn't know about Reeeee; Reeeee doesn't know about Hub
- This architecture follows **industry standards**: SOLID, Clean Architecture, Repository Pattern

### ⚠️ Key Architectural Decisions

**1. MicroApps are self-contained** — each owns Domain, Data, and Presentation layers.

**2. PandoraApp is the composition root** — the only file that knows about all concrete types. Adding a new MicroApp requires editing only this file.

**3. SwiftData schemas are collected dynamically** — each MicroApp declares `modelTypes`, and `PandoraApp` builds the `ModelContainer` by aggregating them through the registry.

**4. Concrete types are hidden behind abstractions** — `AnyRepository<T>` hides `SwiftDataRepository`, `MotionServiceProtocol` hides `CMMotionManager`, `MicroAppRegistryProtocol` hides `MicroAppRegistry`.

---

**Last Updated**: February 21, 2026  
**Author**: Enhanced by GitHub Copilot  
**Version**: 3.0.0
