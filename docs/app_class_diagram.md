@startuml

' Core Application Classes
abstract class App {
    +main()
    +createState()
    +build(BuildContext)
}

class MyApp extends App {
    +_determineInitialScreen()
    +_setInitialScreen()
}

class _MyAppState {
    +initState()
    +_initAppLinks()
    +_handleAppLink()
    +_fallbackToMetadataCheck()
}

' Authentication Classes
abstract class AuthManager {
    +login()
    +logout()
    +register()
}

class SupabaseAuth extends AuthManager {
    +authenticate()
    +getUser()
    +updateUser()
}

' User Classes
abstract class User {
    +id: String
    +email: String
    +firstName: String
    +lastName: String
}

class Passenger extends User {
    +searchBuses()
    +viewSchedule()
    +viewLocation()
}

class Driver extends User {
    +vehicleRegistrationPlate: String
    +licenseNumber: String
    +startTrip()
    +endTrip()
}

class Admin extends User {
    +manageDrivers()
    +manageBuses()
    +viewReports()
}

' Database Models
class DriverModel {
    +id: UUID
    +user_id: UUID
    +license_number: String
    +vehicle_registration_plate: String
    +bus_id: UUID
}

class BusModel {
    +id: UUID
    +bus_name: String
    +vehicle_registration_plate: String
    +bus_photo: bytea
}

class RouteModel {
    +id: UUID
    +driver_id: UUID
    +bus_id: UUID
    +start_station: UUID
    +end_station: UUID
    +start_time: DateTime
    +end_time: DateTime
}

class StationModel {
    +id: UUID
    +name: String
    +latitude: String
    +longitude: String
    +mairie: String
}

' Provider Classes
abstract class Provider {
    +notifyListeners()
    +addListener()
}

class SettingsProvider extends Provider {
    +language: String
    +theme: ThemeMode
    +updateLanguage()
    +updateTheme()
}

class RealtimeProvider extends Provider {
    +busPositions: List<BusPosition>
    +updateBusPosition()
    +getActiveBuses()
}

' Relationships
App "1" -- "1" _MyAppState
MyApp -- _MyAppState

AuthManager <|-- SupabaseAuth
User <|-- Passenger
User <|-- Driver
User <|-- Admin

DriverModel "1" -- "1" BusModel
RouteModel "1" -- "1" DriverModel
RouteModel "1" -- "1" BusModel
RouteModel "1" -- "1" StationModel

Provider <|-- SettingsProvider
Provider <|-- RealtimeProvider

@enduml
