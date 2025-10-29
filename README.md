# README
TRABAJO RUBY

## Requisitos

- Ruby y Bundler instalados
- SQLite 3 (la app usa sqlite3; ver `config/database.yml`)

## Configuración inicial

En PowerShell, desde la carpeta del proyecto:

```powershell
bundle install
bin\rails db:create 
bin\rails db:migrate
bin\rails db:seed
```

Arrancar el servidor:

```powershell
bin\rails s
```

## Migraciones y base de datos

- Ejecutar migraciones pendientes:
	```powershell
	bin\rails db:migrate
	```

- Ver estado de migraciones:
	```powershell
	bin\rails db:migrate:status
	```

- Deshacer la última migración:
	```powershell
	bin\rails db:rollback STEP=1
	```

- Resetear la base (drop + create + schema + seed) ATENCIÓN: borra datos:
	```powershell
	bin\rails db:reset
	```

- Replantar seeds rápidamente (Rails 6+):
	```powershell
	bin\rails db:seed:replant
	```

## Seeds

Edita `db/seeds.rb` para definir datos iniciales. Para cargar:

```powershell
bin\rails db:seed
```

El archivo actual crea usuarios (incluyendo los que se usan en vehículos) y vehículos de ejemplo de forma idempotente.
