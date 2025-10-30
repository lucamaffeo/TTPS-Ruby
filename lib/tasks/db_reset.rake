namespace :db do
  desc "Forzar reset de la BD SQLite (elimina el archivo y corre create, schema:load y seed)"
  task :hard_reset do
    env = ENV["RAILS_ENV"] || "development"
    db_path = File.join(Dir.pwd, "db", "#{env}.sqlite3")
    if File.exist?(db_path)
      puts "Eliminando #{db_path}..."
      File.delete(db_path)
    end

    Rake::Task["db:create"].reenable
    Rake::Task["db:schema:load"].reenable
    Rake::Task["db:seed"].reenable

    Rake::Task["db:create"].invoke
    Rake::Task["db:schema:load"].invoke
    Rake::Task["db:seed"].invoke
  end

  # Alias: db:reset -> db:hard_reset (útil en SQLite/Windows)
  Rake::Task["db:reset"].clear if Rake::Task.task_defined?("db:reset")
  desc "Reset estándar compatible con SQLite (alias de db:hard_reset)"
  task reset: :hard_reset
end
