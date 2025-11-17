class Genero < ApplicationRecord
  begin
    if ActiveRecord::Base.connection.data_source_exists?("generos")
      # nada especial
    end
  rescue StandardError
  end

  # Asociaciones
  has_many :productos, dependent: :nullify

  # Validaciones
  validates :nombre, presence: true, uniqueness: true
end
