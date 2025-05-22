@startuml

actor Driver
participant "Driver App" as App
participant "Realtime Provider" as RT
participant "Database" as DB

Driver -> App: Start Trip
App -> RT: getStations()
RT -> DB: fetchStations()
DB --> RT: return stations list
RT --> App: show stations

Driver -> App: Select departure station
Driver -> App: Select destination station
App -> RT: createRoute()
RT -> DB: insertRoute()
DB --> RT: return route ID
RT --> App: startTrip()

App --> Driver: Show trip started

@enduml
