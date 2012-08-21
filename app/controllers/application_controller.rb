class ApplicationController < ActionController::API

  def serializer_options
    options = {}
    params[:include].nil? ? nil : options[:only] = params[:include].split(",")
    options
  end

  def restful_render(obj)
    puts obj
    json = obj.as_json(serializer_options)
    if obj.respond_to?(:links)
      json["links"] = obj.links
    end
    render :json => json
  end


end
