# Pandora Architecture Documentation

## Overview

Pandora is a **MicroApp Container** built with **Clean Architecture** principles, following industry-standard design patterns for maintainability, testability, and scalability.

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
  - **Domain Models**: Core entities (e.g., ReeeeeModel)
  - **Protocols**: Defining contracts within the MicroApp
- **Note**: Each MicroApp owns its business logic for true modularity

### 3. **Data Layer** (Persistence)
- **Location**: `Core/Repository/` (protocols) + `MicroApp/{FeatureName}/Data/` (implementations)
- **Responsibility**: Data access and persistence
- **Pattern**: Repository pattern
- **Components**:
  - **Core Protocols**: Generic Repository protocol in Core
  - **Generic Implementations**: UserDefaultsRepository<T> in Core (reusable)
  - **MicroApp Repositories**: Feature-specific repository factories in each MicroApp

### 4. **Infrastructure Layer** (Core Services)
- **Location**: `Core/`
- **Responsibility**: Cross-cutting concerns
- **Components**:
  - **Navigation**: Router (Coordinator pattern)
  - **DI Container**: Dependency injection
  - **Protocols**: MicroAppProvider interfaces
  - **Theme**: Design system and styling

---

## 🎨 Design Patterns Used

### 1. **MVVM (Model-View-ViewModel)**
- **Where**: All Views and ViewModels
- **Why**: Separation of UI logic from business logic
- **Example**: `HubView` + `HubViewModel`

### 2. **Repository Pattern**
- **Where**: `Core/Repository/`
- **Why**: Abstract data persistence layer for testability
- **Example**: `UserDefaultsRepository<T>`

### 3. **Use Case / Interactor Pattern**
- **Where**: `Core/UseCase/`
- **Why**: Encapsulate single business operations
- **Example**: `SaveReeeeeRecordUseCase`

### 4. **Dependency Injection (DI)**
- **Where**: `Core/DependencyInjection/`
- **Why**: Loose coupling, better testability
- **Pattern**: Service Locator + Property Wrapper
- **Example**: `DIContainer`, `@Injected` property wrapper

### 5. **Coordinator Pattern**
- **Where**: `Core/Navigation/Router.swift`
- **Why**: Centralized navigation logic
- **Features**: 
  - Type-safe routing
  - Deep link support
  - Navigation history tracking

### 6. **Factory Pattern**
- **Where**: Throughout (Factories for ViewModels, Repositories, etc.)
- **Why**: Centralized object creation
- **Example**: `RouterFactory`, `HubViewModelFactory`

### 7. **Strategy Pattern**
- **Where**: `MicroAppProvider` protocol
- **Why**: Pluggable MicroApp implementations
- **Example**: Different MicroApps implement the same protocol

### 8. **Type Erasure**
- **Where**: `AnyMicroApp` wrapper
- **Why**: Store heterogeneous MicroApps in collections
- **Pattern**: Type-erased wrapper around protocol with associated type

### 9. **Protocol-Oriented Design**
- **Where**: Throughout the codebase
- **Why**: Flexibility, testability, abstraction
- **Examples**: `RouterProtocol`, `HubViewModelProtocol`, `Repository`

---

## 📁 Project Structure

```
Pandora/
├── App/
│   └── PandoraApp.swift              # Entry point with DI setup
│
├── Core/                              # Infrastructure & Core Services (SHARED ONLY)
│   ├── DependencyInjection/
│   │   └── DIContainer.swift         # DI container & @Injected wrapper
│   ├── Navigation/
│   │   └── Router.swift              # Coordinator pattern navigation
│   ├── Protocol/
│   │   ├── MicroAppProvider.swift    # MicroApp interface & type erasure
│   │   └── UseCase.swift             # Generic UseCase protocol
│   ├── Repository/
│   │   └── Repository.swift          # Generic repository protocol & base implementation
│   └── Theme/
│       └── PandoraTheme.swift        # Design system constants
│
├── MicroApp/                          # Feature Modules (SELF-CONTAINED)
│   ├── Hub/                           # Hub MicroApp
│   │   ├── Presentation/
│   │   │   ├── HubCard.swift
│   │   │   ├── HubView.swift
│   │   │   └── HubViewModel.swift
│   │   └── HubMicroApp.swift
│   │
│   └── Reeeee/                        # Reeeee (Yeet) MicroApp - FULLY MODULAR
│       ├── Domain/                    # Business Logic Layer
│       │   ├── Model/
│       │   │   └── ReeeeeModel.swift
│       │   └── UseCase/
│       │       ├── DetectFreefallUseCase.swift
│       │       ├── DetectImpactUseCase.swift
│       │       ├── SaveReeeeeRecordUseCase.swift
│       │       ├── FetchReeeeeHistoryUseCase.swift
│       │       └── CalculatePhysicsMetricsUseCase.swift
│       ├── Data/                      # Data Layer
│       │   └── ReeeeeRepository.swift
│       ├── Presentation/              # Presentation Layer
│       │   ├── ReeeeeView.swift
│       │   └── ReeeeeViewModel.swift
│       └── ReeeeeMicroApp.swift       # Entry point & registration
│
├── Shared/                            # Shared Resources
│   └── Components/                    # Reusable UI components
│       ├── PandoraButton.swift
│       ├── PandoraCard.swift
│       └── ViewModifiers.swift
│
└── Resources/
    └── Assets.xcassets/
```

---

## 🔄 Data Flow

### Example: Loading Reeeee History (Within Reeeee MicroApp)

```
Reeeee MicroApp Module:
├─ View (ReeeeeView)
│   ↓
├─ ViewModel (ReeeeeViewModel)
│   ↓
├─ Use Case (FetchReeeeeHistoryUseCase)    ← Business logic
│   ↓
├─ Repository (ReeeeeRepository)            ← Data access
│   ↓
└─ Data Source (UserDefaults)               ← Persistence

All contained within MicroApp/Reeeee/ module!
```

### Example: Navigation

```
View (HubView)
    ↓
Router.navigateToMicroApp(id)
    ↓
SwiftUI NavigationStack
    ↓
Destination View (ReeeeeView)
```

---

## 🧪 Testability

### Unit Testing Strategy

1. **ViewModels**: Test business logic without UI
   - Mock repositories via protocols
   - Test state changes and data transformations

2. **Use Cases**: Test in isolation
   - Mock dependencies (repositories, services)
   - Verify business rules

3. **Repositories**: Test data operations
   - Mock UserDefaults
   - Verify encoding/decoding

4. **Router**: Test navigation logic
   - Verify path changes
   - Test deep link handling

### Mocking Example

```swift
// Mock repository for testing
class MockReeeeeRepository: Repository {
    var mockData: [ReeeeeModel] = []
    
    func fetchAll() async throws -> [ReeeeeModel] {
        return mockData
    }
    
    // ... other methods
}
```

---

## 🎯 SOLID Principles

### Single Responsibility
- Each class has one reason to change
- Example: `Router` only handles navigation

### Open/Closed
- Open for extension, closed for modification
- Example: New MicroApps extend `MicroAppProvider` without changing core

### Liskov Substitution
- Subtypes can replace base types
- Example: Any `Repository` implementation works the same

### Interface Segregation
- Clients depend only on methods they use
- Example: Specific use case protocols

### Dependency Inversion
- Depend on abstractions, not concretions
- Example: ViewModels depend on `Repository` protocol, not UserDefaults

---

## 🚀 Adding a New MicroApp

### Modular Structure (Recommended)

Create a self-contained module:

```
MicroApp/NewFeature/
├── Domain/
│   ├── Model/
│   │   └── NewFeatureModel.swift
│   └── UseCase/
│       └── NewFeatureUseCases.swift
├── Data/
│   └── NewFeatureRepository.swift
├── Presentation/
│   ├── NewFeatureView.swift
│   └── NewFeatureViewModel.swift
└── NewFeatureMicroApp.swift
```

1. **Create the MicroApp Entry Point**:
```swift
struct NewFeatureMicroApp: MicroAppProvider {
    let metadata = MicroAppMetadata(
        id: "com.pandora.newfeature",
        name: "New Feature",
        iconName: "star",
        tintColor: .blue
    )
    
    func makeView() -> some View {
        NewFeatureView()
    }
}
```

2. **Register in HubViewModel**:
```swift
private func registerDefaultMicroApps() {
    let newApp = AnyMicroApp(NewFeatureMicroApp())
    registerMicroApp(newApp)
}
```

3. **Benefits of This Structure**:
   - ✅ **True Modularity**: Each MicroApp is independent
   - ✅ **Easy to Test**: Test the entire feature in isolation
   - ✅ **Easy to Remove**: Delete the folder, done!
   - ✅ **Team Scalability**: Different teams can own different MicroApps
   - ✅ **Reusable Core**: Core module stays generic and clean

---

## 🔐 Best Practices

### 1. Always use protocols for dependencies
```swift
// ✅ Good
protocol RouterProtocol { ... }
class ViewModel {
    let router: RouterProtocol
}

// ❌ Bad
class ViewModel {
    let router = Router()
}
```

### 2. Use factories for object creation
```swift
// ✅ Good
let router = RouterFactory.makeRouter()

// ❌ Bad
let router = Router()
```

### 3. Keep ViewModels testable
```swift
// ✅ Good - Dependencies injected
class ViewModel {
    init(repository: Repository) { ... }
}

// ❌ Bad - Hard dependency
class ViewModel {
    let repository = UserDefaultsRepository()
}
```

### 4. Use async/await for async operations
```swift
// ✅ Good
func loadData() async throws {
    let data = try await repository.fetchAll()
}
```

### 5. Handle errors gracefully
```swift
// ✅ Good
do {
    try await useCase.execute(request)
} catch {
    // Show error to user
    self.error = error
}
```

---

## 📚 Key Technologies

- **SwiftUI**: Declarative UI framework
- **Observation Framework**: Modern state management (@Observable)
- **Async/Await**: Modern concurrency
- **NavigationStack**: Type-safe navigation
- **CoreMotion**: Sensor data access
- **UserDefaults**: Local persistence

---

## 🔮 Future Enhancements

1. **Networking Layer**: Add API services with Repository pattern
2. **Core Data**: Enhanced local persistence
3. **Combine**: Reactive programming for complex flows
4. **Unit Tests**: Comprehensive test coverage
5. **CI/CD**: Automated testing and deployment
6. **Localization**: Multi-language support
7. **Analytics**: Event tracking and monitoring

---

## 📝 Notes

- This architecture is **scalable**: Easy to add new features
- This architecture is **testable**: Mock dependencies easily
- This architecture is **maintainable**: Clear separation of concerns
- This architecture follows **industry standards**: SOLID, Clean Architecture, etc.

### ⚠️ Key Architectural Decision: Modular MicroApps

**Each MicroApp is self-contained** with its own Domain, Data, and Presentation layers:

**Why?**
- **True Modularity**: Features can be developed, tested, and shipped independently
- **Team Scalability**: Different teams can own different MicroApps without conflicts
- **Easy Removal**: Delete a folder, and the MicroApp is gone
- **Clear Boundaries**: Business logic stays within its feature context
- **Reusable Core**: Core module only contains truly shared infrastructure

**What goes in Core vs MicroApp?**
- ✅ **Core**: Generic protocols, DI container, Router, Theme, base Repository implementation
- ✅ **MicroApp**: Feature-specific use cases, repositories, models, views, viewmodels

**Example**: `ReeeeeUseCases` lives in `MicroApp/Reeeee/Domain/UseCase/` because it's specific to the Reeeee feature, not shared infrastructure.

---

**Last Updated**: February 17, 2026
**Author**: Enhanced by GitHub Copilot
**Version**: 2.0.0
