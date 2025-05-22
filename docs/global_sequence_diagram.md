@startuml

actor User
participant "App UI" as UI
participant "Auth Manager" as Auth
participant "Realtime Provider" as RT
participant "Settings Provider" as Settings
participant "Database" as DB

' User Login Flow
User -> UI: Open App
UI -> Auth: checkAuthStatus()
alt User is not logged in
    UI --> User: Show Login Screen
    User -> UI: Enter credentials
    UI -> Auth: authenticate()
    Auth -> DB: verifyCredentials()
    DB --> Auth: return user data
    Auth --> UI: return auth token
    UI --> User: Show Home Screen
else User is logged in
    UI -> Auth: getUserRole()
    Auth --> UI: return role
    UI --> User: Show Role-specific Screen

' Driver Flow
User -> UI: Start as Driver
UI -> Auth: checkDriverStatus()
Auth -> DB: fetchDriverInfo()
DB --> Auth: return driver data
Auth --> UI: return status
UI --> User: Show Driver UI

User -> UI: Start Trip
UI -> RT: getStations()
RT -> DB: fetchStations()
DB --> RT: return stations
RT --> UI: show stations

User -> UI: Select stations
UI -> RT: createRoute()
RT -> DB: insertRoute()
DB --> RT: return route ID
RT --> UI: startTrip()

' Passenger Flow
User -> UI: Start as Passenger
UI -> Auth: checkPassengerStatus()
Auth -> DB: fetchPassengerInfo()
DB --> Auth: return passenger data
Auth --> UI: return status
UI --> User: Show Passenger UI

User -> UI: Search Buses
UI -> RT: getActiveBuses()
RT -> DB: fetchActiveBuses()
DB --> RT: return buses
RT --> UI: show buses

' Admin Flow
User -> UI: Start as Admin
UI -> Auth: checkAdminStatus()
Auth -> DB: fetchAdminInfo()
DB --> Auth: return admin data
Auth --> UI: return status
UI --> User: Show Admin Dashboard

User -> UI: Manage Drivers
UI -> RT: fetchDrivers()
RT -> DB: fetchDriverList()
DB --> RT: return drivers
RT --> UI: show drivers

' Settings Flow
User -> UI: Change Settings
UI -> Settings: updateSettings()
Settings -> DB: updateSettings()
DB --> Settings: confirm update
Settings --> UI: settings updated
UI --> User: Show updated settings

@enduml
