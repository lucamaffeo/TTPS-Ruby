class Admin::BaseController < ApplicationController
  # verificamos que el usuario haya iniciado sesión caso contrario va al login.
  before_action :authenticate_usuario!
end