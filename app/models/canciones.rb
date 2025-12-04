class Cancion < ApplicationRecord
    belongs_to :producto
    
    validates :duracion, numericality: { greater_than: 0 }, allow_nil: true
    validates :formato, presence: true
    end