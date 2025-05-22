@startuml

actor Passenger
actor "Bus App" as App

rectangle "Passenger System" {
    usecase "Register as Passenger" as UC1
    usecase "Search Buses" as UC2
    usecase "View Bus Schedule" as UC3
    usecase "View Real-time Location" as UC4
    usecase "View Bus Details" as UC5
    usecase "View Driver Info" as UC6
    usecase "View Station Info" as UC7
    usecase "View Route Info" as UC8
}

Passenger --> UC1
Passenger --> UC2
Passenger --> UC3
Passenger --> UC4
Passenger --> UC5
Passenger --> UC6
Passenger --> UC7
Passenger --> UC8

App --> UC1
App --> UC2
App --> UC3
App --> UC4
App --> UC5
App --> UC6
App --> UC7
App --> UC8

UC2 .> UC3 : "After search"
UC2 .> UC4 : "After search"
UC2 .> UC5 : "After search"
UC2 .> UC7 : "After search"
UC2 .> UC8 : "After search"

@enduml
