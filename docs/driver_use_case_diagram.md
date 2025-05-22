@startuml

actor Driver
actor "Bus App" as App

rectangle "Driver System" {
    usecase "Register as Driver" as UC1
    usecase "Submit Vehicle Info" as UC2
    usecase "Start Trip" as UC3
    usecase "End Trip" as UC4
    usecase "View Profile" as UC5
    usecase "Update Profile" as UC6
    usecase "View Real-time Location" as UC7
    usecase "View Bus Info" as UC8
}

Driver --> UC1
Driver --> UC2
Driver --> UC3
Driver --> UC4
Driver --> UC5
Driver --> UC6
Driver --> UC7
Driver --> UC8

App --> UC1
App --> UC2
App --> UC3
App --> UC4
App --> UC5
App --> UC6
App --> UC7
App --> UC8

UC1 .> UC2 : "After registration"
UC3 .> UC4 : "When trip ends"
UC5 .> UC6 : "Optional"

@enduml
