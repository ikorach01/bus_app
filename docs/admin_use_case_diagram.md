@startuml

actor Admin
actor "Admin App" as App

rectangle "Admin System" {
    usecase "Login" as UC1
    usecase "Dashboard Overview" as UC2
    usecase "Manage Drivers" as UC3
    usecase "Manage Buses" as UC4
    usecase "Manage Users" as UC5
    usecase "View Reports" as UC6
    usecase "Monitor Real-time Activity" as UC7
    usecase "Manage Routes" as UC8
}

Admin --> UC1
Admin --> UC2
Admin --> UC3
Admin --> UC4
Admin --> UC5
Admin --> UC6
Admin --> UC7
Admin --> UC8

App --> UC1
App --> UC2
App --> UC3
App --> UC4
App --> UC5
App --> UC6
App --> UC7
App --> UC8

UC1 .> UC2 : "After login"
UC2 .> UC3 : "Quick access"
UC2 .> UC4 : "Quick access"
UC2 .> UC5 : "Quick access"
UC2 .> UC6 : "Quick access"
UC2 .> UC7 : "Quick access"
UC2 .> UC8 : "Quick access"

@enduml
