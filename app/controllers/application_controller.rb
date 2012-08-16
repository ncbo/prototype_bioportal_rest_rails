class ApplicationController < ActionController::API

  def serializer_options
    options = {}
    params[:include].nil? ? nil : options[:only] = params[:include].split(",")
    options
  end


end
