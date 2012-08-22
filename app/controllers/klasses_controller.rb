class KlassesController < ApplicationController

  def show
    klass = Klass.find(params[:id], params[:ontology])
    restful_render(klass)
  end

end
