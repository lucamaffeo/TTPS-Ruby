# TTPS - Trabajo Ruby ActiveSound Disqueria.

## INTEGRANTES
# Franco Bof
# Luca Maffeo
# Alejandro Proia

## Requisitos técnicos
- Ruby 3.4.x 
- Bundler 2.7.x
- rails 8.1.x
- SQLite

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

## Gemas utilizadas.
# Autenticación y Autorización
devise: Maneja el sistema(registro, login, recuperación de contraseña)
pundit: Control de permisos basado en roles

# Búsqueda y Filtrado
ransack: Crea filtros y búsquedas avanzadas.
kaminari: Para la paginacion.

# Procesamiento de Imágenes
mini_magick: Redimensiona, convierte y manipula imágenes subidas por usuarios

# Datos de Prueba
faker: Genera nombres, emails, direcciones ficticias automáticamente para rellenar tu base de datos en desarrollo

# PDFs
prawn: Crea documentos PDF(para crear facturas).
prawn-table: Añade tablas formateadas a los PDFs

# Gráficos
chartkick: Genera gráficos interactivos (líneas, barras, etc.) con datos-
groupdate: Agrupa datos por períodos de tiempo (útil para mostrar estadísticas diarias/mensuales en gráficos)