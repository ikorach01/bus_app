@startuml
' Configuration
left to right direction
skinparam backgroundColor transparent
skinparam handwritten false
skinparam packageStyle rectangle
skinparam usecaseBackgroundColor White
skinparam usecaseBorderColor Black
skinparam rectangleBackgroundColor White
skinparam rectangleBorderColor Black

' Actors
actor "User" as User
actor "Driver" as Driver
actor "Admin" as Admin

rectangle "Bus Management System" {
    package "Passenger System" {
        ' Authentication
        usecase "Register Account" as UC1
        usecase "Login" as UC2
        usecase "Search for Buses" as UC11

        ' Information View
        usecase "View Schedule" as UC3
        usecase "Track Location" as UC4
        usecase "View Bus Details" as UC5
        usecase "View Driver Info" as UC6
        usecase "View Station Info" as UC7
        usecase "View Route Info" as UC8

        ' Profile Management
        usecase "View Profile" as UC9
        usecase "Update Profile" as UC10
    }

    package "Driver System" {
        ' Authentication
        usecase "Register as Driver" as UC12
        usecase "Login" as UC13

        ' Trip Management
        usecase "Start Trip" as UC14
        usecase "End Trip" as UC15
        usecase "Track Location" as UC16

        ' Profile & Info
        usecase "View Profile" as UC17
        usecase "Update Profile" as UC18
        usecase "View Bus Info" as UC19
    }

    package "Admin System" {
        ' Reports
        usecase "Export Report" as UC20
        usecase "Generate Report" as UC21
        usecase "View Reports" as UC22

        ' Dashboard
        usecase "Login" as UC23
        usecase "Dashboard" as UC24
        usecase "Monitor Activity" as UC25

        ' Management
        usecase "Manage Drivers" as UC26
        usecase "Manage Users" as UC27
        usecase "Manage Buses" as UC28
        usecase "Manage Routes" as UC29
    }
}

' Actor Relationships
User --> Driver : "views"
Driver --> Admin : "managed by"
User --> Admin : "managed by"

' User Actions
User --> UC1
User --> UC2
User --> UC3
User --> UC4
User --> UC5
User --> UC6
User --> UC7
User --> UC8
User --> UC9
User --> UC10
User --> UC11

' Driver Actions
Driver --> UC12
Driver --> UC13
Driver --> UC14
Driver --> UC15
Driver --> UC16
Driver --> UC17
Driver --> UC18
Driver --> UC19

' Admin Actions
Admin --> UC20
Admin --> UC21
Admin --> UC22
Admin --> UC23
Admin --> UC24
Admin --> UC25
Admin --> UC26
Admin --> UC27
Admin --> UC28
Admin --> UC29

' Use Case Relationships
UC1 ..> UC11 : <<extends>>
note right on link: Search becomes available after registration

UC12 ..> UC14 : <<extends>>
note right on link: Start trip after registration

UC14 ..> UC15 : <<includes>>
note right on link: Completing trip is part of starting one

' Management Relationships
UC26 --> UC6
UC26 --> UC17
UC28 --> UC5
UC28 --> UC19
UC27 --> UC9
UC27 --> UC10
UC29 --> UC8
UC29 --> UC18

' Report Relationships
UC20 <|-- UC22
UC21 <|-- UC22

@enduml
