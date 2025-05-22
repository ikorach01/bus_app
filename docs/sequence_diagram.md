# Sequence Diagram Documentation

## 1. Overview
This document presents the sequence diagrams for key interactions within the bus management system. The diagrams illustrate the flow of operations between different components of both the mobile application (BusApp) and administrative dashboard (BusAdmin).

## 2. Driver Registration and Vehicle Information Submission

```mermaid
sequenceDiagram
    participant D as Driver
    participant UI as Mobile UI
    participant AP as AuthProvider
    participant SB as SupabaseService
    participant DB as Database

    D->>UI: Input Registration Data
    UI->>AP: validateData()
    AP->>SB: registerDriver()
    SB->>DB: INSERT INTO drivers
    DB-->>SB: Success
    SB-->>AP: Driver Created
    
    D->>UI: Submit Vehicle Info
    UI->>AP: validateVehicleData()
    AP->>SB: updateDriverVehicle()
    SB->>DB: UPDATE drivers
    SB->>DB: INSERT INTO buses
    DB-->>SB: Success
    SB-->>UI: Update Complete
    UI-->>D: Show Success Message
```

## 3. Real-time Bus Tracking Sequence

```mermaid
sequenceDiagram
    participant D as Driver
    participant RP as RealtimeProvider
    participant LS as LocationService
    participant SB as SupabaseService
    participant P as Passengers

    D->>RP: startTrip()
    RP->>LS: startLocationUpdates()
    
    loop Every 5 seconds
        LS->>RP: onLocationChanged()
        RP->>SB: updateBusPosition()
        SB-->>P: broadcastUpdate()
    end

    D->>RP: endTrip()
    RP->>LS: stopLocationUpdates()
    RP->>SB: updateTripStatus()
    SB-->>P: tripEnded()
```

## 4. Station Search and Route Planning

```mermaid
sequenceDiagram
    participant U as User
    participant UI as Mobile UI
    participant SP as SearchProvider
    participant DB as Database
    participant MP as MapProvider

    U->>UI: Search Station
    UI->>SP: searchStations(query)
    SP->>DB: SELECT FROM stations
    DB-->>SP: Station Results
    SP-->>UI: Display Results
    
    U->>UI: Select Station
    UI->>MP: showOnMap()
    MP-->>UI: Update Map View
    UI->>SP: getNearbyBuses()
    SP->>DB: Query Active Buses
    DB-->>SP: Bus Locations
    SP-->>UI: Show Buses
```

## 5. Administrative Dashboard Operations

```mermaid
sequenceDiagram
    participant A as Admin
    participant UI as Dashboard UI
    participant AP as AdminProvider
    participant SB as SupabaseService
    participant DB as Database

    A->>UI: Login
    UI->>AP: authenticate()
    AP->>SB: signIn()
    SB-->>AP: Session
    
    A->>UI: View System Stats
    UI->>AP: fetchStatistics()
    AP->>DB: Multiple Queries
    DB-->>AP: Statistics Data
    AP-->>UI: Display Dashboard
    
    A->>UI: Manage Driver
    UI->>AP: updateDriverStatus()
    AP->>SB: updateDriver()
    SB->>DB: UPDATE drivers
    DB-->>SB: Success
    SB-->>UI: Refresh View
```

## 6. Key Interaction Patterns

### 6.1 Authentication Flow
1. User inputs credentials
2. AuthProvider validates input
3. SupabaseService attempts authentication
4. Success/failure response handled
5. UI updated accordingly

### 6.2 Real-time Updates
1. Driver initiates trip
2. LocationService begins tracking
3. Position updates sent to server
4. Server broadcasts to subscribers
5. UI components update automatically

### 6.3 Data Management
1. User initiates action
2. Provider validates request
3. SupabaseService processes operation
4. Database updated
5. Real-time updates broadcast
6. UI refreshed

## 7. Error Handling Sequences

### 7.1 Network Error Recovery
```mermaid
sequenceDiagram
    participant U as User
    participant UI as App UI
    participant P as Provider
    participant SB as SupabaseService

    U->>UI: Perform Action
    UI->>P: processRequest()
    P->>SB: apiCall()
    SB-->>P: Network Error
    P->>P: startRetrySequence()
    P-->>UI: Show Error State
    P->>SB: retryApiCall()
    SB-->>P: Success
    P-->>UI: Update View
```

### 7.2 Data Validation
```mermaid
sequenceDiagram
    participant U as User
    participant UI as App UI
    participant V as Validator
    participant P as Provider

    U->>UI: Submit Data
    UI->>V: validateInput()
    V-->>UI: Validation Error
    UI-->>U: Show Error Message
    U->>UI: Fix and Resubmit
    UI->>V: validateInput()
    V-->>UI: Valid
    UI->>P: processData()
```

## 8. Implementation Notes

### 8.1 Performance Considerations
- Optimize real-time updates frequency
- Implement efficient data caching
- Use pagination for large datasets
- Minimize network requests

### 8.2 Security Measures
- Validate all user input
- Implement proper authentication flows
- Use secure communication channels
- Apply role-based access control

### 8.3 Error Handling
- Implement retry mechanisms
- Provide user feedback
- Log errors for debugging
- Handle edge cases gracefully

## 9. Future Enhancements

1. **Real-time Features**
   - Add websocket connections
   - Implement push notifications
   - Real-time chat support

2. **Performance Improvements**
   - Optimize database queries
   - Implement better caching
   - Add offline support

3. **User Experience**
   - Enhanced error messages
   - Better loading states
   - Smoother transitions
