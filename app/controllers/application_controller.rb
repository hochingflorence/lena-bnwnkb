class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Initialize dialogflow
  require "google/cloud/dialogflow"
  ENV['GOOGLE_APPLICATION_CREDENTIALS'] = 'config/dialogflow_authentication.json'
  
end
