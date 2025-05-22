# Global Use Case Diagram - Bus Management System

```plantuml
@startuml
' ==== DIAGRAM SETTINGS ====
left to right direction
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam defaultFontColor #333333

' ==== STYLING ====
skinparam rectangle {
    BackgroundColor White
    BorderColor #2A52C9
    roundCorner 10
}

skinparam usecase {
    BackgroundColor #F8F9FA
    BorderColor #2A52C9
    ArrowColor #2A52C9
    FontStyle plain
}

' ==== ACTORS ====
actor "Passenger" as passenger #2A52C9
actor "Driver" as driver #2A52C9
actor "Admin" as admin #2A52C9

' ==== SYSTEM BOUNDARY ====
rectangle "Bus Management System" as system {
    ' ==== PASSENGER USE CASES ====
    usecase "Register Account" as UC1
    usecase "Login" as UC2
    usecase "Search Buses" as UC3
    usecase "View Schedule" as UC4
    usecase "Track Bus Location" as UC5
    usecase "View Bus Details" as UC6
    usecase "View Driver Info" as UC7
    usecase "View Station Info" as UC8
    usecase "View Route Info" as UC9
    usecase "View Profile" as UC10
    usecase "Update Profile" as UC11
    usecase "Book Ticket" as UC12
    usecase "View Booking History" as UC13
    usecase "Cancel Booking" as UC14

    ' ==== DRIVER USE CASES ====
    usecase "Register as Driver" as UC15
    usecase "Driver Login" as UC16
    usecase "Start Trip" as UC17
    usecase "End Trip" as UC18
    usecase "Update Location" as UC19
    usecase "View Assigned Route" as UC20
    usecase "View Schedule" as UC21
    usecase "View Passenger Count" as UC22

    ' ==== ADMIN USE CASES ====
    usecase "Admin Login" as UC23
    usecase "Manage Users" as UC24
    usecase "Manage Drivers" as UC25
    usecase "Manage Buses" as UC26
    usecase "Manage Routes" as UC27
    usecase "Manage Stations" as UC28
    usecase "View Reports" as UC29
    usecase "Monitor System" as UC30
    usecase "Generate Reports" as UC31
    usecase "Manage Fares" as UC32
}

' ==== ACTOR CONNECTIONS ====
' Passenger connections
passenger --> UC1
passenger --> UC2
passenger --> UC3
passenger --> UC4
passenger --> UC5
passenger --> UC6
passenger --> UC7
passenger --> UC8
passenger --> UC9
passenger --> UC10
passenger --> UC11
passenger --> UC12
passenger --> UC13
passenger --> UC14

' Driver connections
driver --> UC15
driver --> UC16
driver --> UC17
driver --> UC18
driver --> UC19
driver --> UC20
driver --> UC21
driver --> UC22

' Admin connections
admin --> UC23
admin --> UC24
admin --> UC25
admin --> UC26
admin --> UC27
admin --> UC28
admin --> UC29
admin --> UC30
admin --> UC31
admin --> UC32

' ==== USE CASE RELATIONSHIPS ====
' Passenger relationships
UC1 ..> UC3 : <<extends>>
UC2 ..> UC3 : <<extends>>
UC3 ..> UC4 : <<includes>>
UC3 ..> UC5 : <<includes>>
UC12 ..> UC13 : <<extends>>
UC13 ..> UC14 : <<includes>>

' Driver relationships
UC15 ..> UC17 : <<extends>>
UC16 ..> UC17 : <<extends>>
UC17 ..> UC18 : <<includes>>
UC17 ..> UC19 : <<includes>>

' Admin relationships
UC23 ..> UC24 : <<extends>>
UC24 ..> UC25 : <<includes>>
UC24 ..> UC26 : <<includes>>
UC24 ..> UC27 : <<includes>>
UC24 ..> UC28 : <<includes>>
UC29 ..> UC31 : <<includes>>

' ==== NOTES ====
note right of UC1
  Requires email, password,
  and basic information
end note

note right of UC15
  Requires license verification
  and vehicle information
end note

note right of UC23
  Requires admin credentials
  and 2FA authentication
end note

@enduml
```

## Diagram Explanation

### Actors
1. **Passenger**: Regular users who use the bus service
2. **Driver**: Bus drivers who operate the vehicles
3. **Admin**: System administrators who manage the platform

### Key Features

#### Passenger Features
- Account management (registration, login, profile)
- Bus search and tracking
- Schedule and route information
- Booking management

#### Driver Features
- Driver registration and authentication
- Trip management
- Location updates
- Route and schedule access

#### Admin Features
- User management
- Driver management
- Bus and route management
- System monitoring
- Report generation

### Relationships
- **<<includes>>**: Indicates that one use case includes the behavior of another
- **<<extends>>**: Shows optional/conditional behavior

This diagram provides a comprehensive view of all system functionalities and their relationships, with all actors positioned on the left side for clarity.
