# Class Diagram Documentation

## 1. Overview
This document presents the class diagram of the complete bus management system, including both the mobile application (BusApp) and the administrative dashboard (BusAdmin). The system is built using Flutter/Dart and follows an object-oriented design pattern.

## 2. Core Domain Models

### 2.1 User-Related Classes

```mermaid
classDiagram
    class User {
        +String id
        +String email
        +String role
        +DateTime createdAt
        +authenticate()
        +logout()
    }
    
    class Driver {
        +String firstName
        +String lastName
        +String licenseNumber
        +DateTime licenseExpiration
        +String vehicleRegistrationPlate
        +String busId
        +Uint8List licenseImageFront
        +Uint8List licenseImageBack
        +Uint8List greyCardImageFront
        +Uint8List greyCardImageBack
        +String busName
        +Uint8List busPhoto
        +updateProfile()
        +startTrip()
        +endTrip()
        +updateLocation()
    }
    
    class Administrator {
        +String name
        +String accessLevel
        +manageUsers()
        +generateReports()
        +monitorSystem()
    }
    
    User <|-- Driver
    User <|-- Administrator
```

### 2.2 Vehicle and Route Classes

```mermaid
classDiagram
    class Bus {
        +String id
        +String busName
        +String registrationPlate
        +Uint8List photo
        +String driverId
        +DateTime createdAt
        +updateStatus()
        +assignDriver()
    }
    
    class Route {
        +String id
        +String driverId
        +String busId
        +String startStation
        +String endStation
        +DateTime startTime
        +DateTime endTime
        +List~Position~ positions
        +startRoute()
        +endRoute()
        +updatePosition()
    }
    
    class Position {
        +String id
        +String busId
        +String routeId
        +double latitude
        +double longitude
        +double speed
        +double heading
        +DateTime timestamp
        +updatePosition()
    }
    
    class Station {
        +String id
        +String name
        +String municipality
        +double latitude
        +double longitude
        +DateTime createdAt
        +updateInfo()
    }
    
    Bus "1" -- "1" Driver
    Bus "1" -- "*" Position
    Route "1" -- "*" Position
    Route "*" -- "2" Station
```

## 3. Provider Classes

### 3.1 Mobile Application Providers

```mermaid
classDiagram
    class RealtimeProvider {
        -SupabaseClient _client
        +Stream~Position~ positionStream
        +startLocationUpdates()
        +stopLocationUpdates()
        +updatePosition()
    }
    
    class SettingsProvider {
        -String _currentLanguage
        -ThemeMode _themeMode
        +changeLanguage()
        +toggleTheme()
        +savePreferences()
    }
```

### 3.2 Admin Dashboard Providers

```mermaid
classDiagram
    class AuthProvider {
        -User _currentUser
        +login()
        +logout()
        +checkAuthStatus()
    }
    
    class BusManagementProvider {
        -List~Bus~ _buses
        +addBus()
        +updateBus()
        +deleteBus()
        +assignDriver()
    }
```

## 4. Service Classes

```mermaid
classDiagram
    class SupabaseService {
        -SupabaseClient _client
        +initializeSupabase()
        +getAuthUser()
        +queryData()
        +streamRealTimeData()
    }
    
    class LocationService {
        +getCurrentLocation()
        +startLocationUpdates()
        +stopLocationUpdates()
    }
```

## 5. Class Relationships

### 5.1 Key Relationships
- **User -> Driver/Administrator**: Inheritance relationship where Driver and Administrator extend the base User class
- **Bus -> Driver**: One-to-one relationship where each bus is assigned to one driver
- **Route -> Bus**: One-to-one relationship for active routes
- **Route -> Station**: Many-to-many relationship through route stations
- **Bus -> Position**: One-to-many relationship for tracking history

### 5.2 Provider Dependencies
- RealtimeProvider depends on SupabaseService for real-time updates
- SettingsProvider manages app-wide configurations
- AuthProvider handles user authentication state
- BusManagementProvider manages bus fleet operations

## 6. Implementation Notes

1. **Data Persistence**
   - All model classes implement toJson() and fromJson() methods
   - Database operations are handled through SupabaseService
   - Real-time updates use Supabase's real-time subscriptions

2. **State Management**
   - Provider pattern is used for state management
   - ChangeNotifier is implemented by provider classes
   - Providers are scoped to their respective widget trees

3. **Security**
   - Row Level Security (RLS) policies in Supabase
   - Role-based access control
   - Secure image handling for documents

4. **Real-time Features**
   - Location updates every 5 seconds
   - Real-time bus position tracking
   - Live route status updates

## 7. Future Considerations

1. **Scalability**
   - Consider implementing caching for frequently accessed data
   - Optimize real-time updates for large fleet sizes
   - Implement pagination for large data sets

2. **Maintainability**
   - Keep provider responsibilities focused and specific
   - Maintain clear separation between UI and business logic
   - Document all class relationships and dependencies

3. **Extensions**
   - Plan for additional user roles
   - Consider adding support for multiple fleets
   - Prepare for integration with other transportation systems
