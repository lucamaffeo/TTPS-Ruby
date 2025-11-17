class Artista < ApplicationRecord
  # Evitar fallos cuando todavía no existe la tabla
  begin
    if ActiveRecord::Base.connection.data_source_exists?("artistas")
      # nada especial por ahora
    end
  rescue StandardError
  end

  # Asociaciones
  has_many :productos, dependent: :nullify

  # Validaciones
  validates :nombre, presence: true, uniqueness: true
end
