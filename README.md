# TTPS - Trabajo Ruby

## Requisitos técnicos
- Ruby 3.4.x 
- Bundler 2.7.x
- rails 8.1.x

## Decisiones de diseño
- Autenticación: Devise (email + password).
- Autorización: Pundit, con políticas por recurso.
- Modelo Usuario:
  - Atributos: nombre, email, dni, rol, password.
  - Roles como enum: 0=empleado, 1=gerente, 2=administrador.
  - Restricciones de BD: email único, dni único, check constraint `rol IN (0,1,2)`.
- Seeds: crean 3 usuarios base (admin/gerente/empleado) con password "password".


## Puesta en marcha local
```powershell
bundle install
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
bundle exec rails s
```
* Puede ser solo rails.

## Gestión de base de datos
- Migraciones pendientes:
  ```powershell
  bundle exec rails db:migrate
  ```
- Reset completo (drop + create + schema + seed). Recomendado en Windows/SQLite:
  ```powershell
  bundle exec rails db:reset
  ```
- Replantar seeds:
  ```powershell
  bundle exec rails db:seed:replant
  ```

Notas:
- Cerrá cualquier visor de SQLite antes de resetear (evita "Permission denied").

## Cuentas iniciales (seeds)
- admin@example.com / password (rol: administrador)
- gerente@example.com / password (rol: gerente)
- empleado@example.com / password (rol: empleado)
