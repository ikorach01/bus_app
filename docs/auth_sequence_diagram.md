@startuml

actor User
participant "Auth Screen" as Auth
participant "Supabase Auth" as AuthSvc
participant "Database" as DB

User -> Auth: Enter credentials
Auth -> AuthSvc: authenticate(email, password)
AuthSvc -> DB: verifyCredentials()
DB --> AuthSvc: return user data
AuthSvc --> Auth: return auth token
Auth --> User: Show home screen

@enduml
