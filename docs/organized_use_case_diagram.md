@startuml
' === Diagram Settings ===
left to right direction
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam defaultFontColor #333333

' === Styling ===
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

' === Actors ===
actor "Passenger" as passenger #2A52C9
actor "Driver" as driver #2A52C9
actor "Admin" as admin #2A52C9

' === System Boundary ===
rectangle "Bus Management System" as system {
    ' === Passenger Use Cases ===
    package "Passenger Features" {
        usecase "Authentication" as auth1 {
            usecase "Register Account" as UC1
            usecase "Login" as UC2
        }
        usecase "Bus Information" as info1 {
            usecase "Search Buses" as UC3
            usecase "View Schedule" as UC4
            usecase "Track Bus Location" as UC5
            usecase "View Bus Details" as UC6
        }
        usecase "Driver Information" as UC7
        usecase "Station Information" as UC8
        usecase "Route Information" as UC9
        usecase "Profile Management" as profile1 {
            usecase "View Profile" as UC10
            usecase "Update Profile" as UC11
        }
        usecase "Ticket Management" as ticket1 {
            usecase "Book Ticket" as UC12
            usecase "View Booking History" as UC13
            usecase "Cancel Booking" as UC14
        }
    }

    ' === Driver Use Cases ===
    package "Driver Features" {
        usecase "Authentication" as auth2 {
            usecase "Register as Driver" as UC15
            usecase "Driver Login" as UC16
        }
        usecase "Trip Management" as trip1 {
            usecase "Start Trip" as UC17
            usecase "End Trip" as UC18
        }
        usecase "Location Management" as UC19
        usecase "Route Information" as UC20
        usecase "Schedule Information" as UC21
        usecase "Passenger Count" as UC22
    }

    ' === Admin Use Cases ===
    package "Admin Features" {
        usecase "Authentication" as auth3 {
            usecase "Admin Login" as UC23
        }
        usecase "User Management" as UC24
        usecase "Driver Management" as UC25
        usecase "Bus Management" as UC26
        usecase "Route Management" as UC27
        usecase "Station Management" as UC28
        usecase "Reporting" as report1 {
            usecase "View Reports" as UC29
            usecase "Generate Reports" as UC31
        }
        usecase "System Monitoring" as UC30
        usecase "Fare Management" as UC32
    }
}

' === Actor Connections ===
' Passenger connections
passenger --> auth1
passenger --> info1
passenger --> UC7
passenger --> UC8
passenger --> UC9
passenger --> profile1
passenger --> ticket1

' Driver connections
driver --> auth2
driver --> trip1
driver --> UC19
driver --> UC20
driver --> UC21
driver --> UC22

' Admin connections
admin --> auth3
admin --> UC24
admin --> UC25
admin --> UC26
admin --> UC27
admin --> UC28
admin --> report1
admin --> UC30
admin --> UC32

' === Use Case Relationships ===
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

' === Notes ===
note right of auth1
  Authentication required for all features
end note

note right of auth2
  Requires driver license and vehicle info
end note

note right of auth3
  Requires admin credentials and 2FA
end note
@enduml
