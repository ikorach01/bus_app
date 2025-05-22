@startuml

actor Passenger
participant "Passenger App" as App
participant "Realtime Provider" as RT
participant "Database" as DB

Passenger -> App: Search Buses
App -> RT: getActiveBuses()
RT -> DB: fetchActiveBuses()
DB --> RT: return buses list
RT --> App: show buses

Passenger -> App: Select bus
App -> RT: getBusDetails(bus_id)
RT -> DB: fetchBusDetails()
DB --> RT: return bus info
RT --> App: show bus details

@enduml
