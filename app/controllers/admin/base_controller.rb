class Admin::BaseController < ApplicationController
  before_action :authenticate_usuario!
end