@startuml

actor Admin
participant "Admin App" as App
participant "Database" as DB

Admin -> App: View Drivers
App -> DB: fetchDrivers()
DB --> App: return drivers list

Admin -> App: Select driver
App -> DB: fetchDriverDetails()
DB --> App: return driver info

Admin -> App: Update driver status
App -> DB: updateDriverStatus()
DB --> App: confirm update
App --> Admin: Show updated status

@enduml
