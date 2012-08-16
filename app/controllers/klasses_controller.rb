class KlassesController < ApplicationController

  def show
    klass = Klass.find(params[:id], params[:ontology])
    render :json => klass.as_json(serializer_options)
  end

end
