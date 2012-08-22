class ApplicationController < ActionController::API

  def serializer_options
    options = {}
    params[:include].nil? ? nil : options[:only] = params[:include].split(",")
    options
  end

  def restful_render(obj)
    if obj.kind_of?(Array)
      json = []
      obj.each do |el|
        json_el = el.as_json(serializer_options)
        json << add_links(json_el, el)
      end
    else
      json = obj.as_json(serializer_options)
      add_links(json, obj)
    end
    render :json => json
  end

  private

  def add_links(hash, obj)
    if obj.respond_to?(:links)
      hash["links"] = obj.links
    end
    hash
  end

end
