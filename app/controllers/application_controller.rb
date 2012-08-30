class ApplicationController < ActionController::API
  include ActionController::MimeResponds

  # Look for the 'include' param in the request and set appropriately
  def serializer_options
    options = {}
    params[:include].nil? ? nil : options[:only] = params[:include].split(",")
    options
  end

  # Render an object and add RESTful links when available
  # TODO: Method should do content negotiation for other serialization formats
  # @param object to serialize
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
    respond_to do |format|
      format.html do
        @object_for_render = json
        render "layouts/jsonview"
      end
      format.json { render :json => json }
    end
  end

  private

  # Check if the object has links defined and, if so, add them
  def add_links(hash, obj)
    if obj.respond_to?(:restful_links)
      hash["links"] = obj.restful_links
    end
    hash
  end

end
