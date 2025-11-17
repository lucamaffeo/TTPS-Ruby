class Imagen < ApplicationRecord
  begin
    if ActiveRecord::Base.connection.data_source_exists?("imagenes")
      # nada por ahora
    end
  rescue StandardError
  end

  # Asociaciones
  belongs_to :producto
  has_one_attached :archivo

  # Validaciones
  validates :archivo, presence: true
end
