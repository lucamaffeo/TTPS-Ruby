class Producto < ApplicationRecord
  has_many_attached :imagenes
  has_one_attached :audio_muestra
end
