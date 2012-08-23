class KlassesController < ApplicationController

  def index
    render :json => { :links => { :roots => Klass.path.gsub(":ontology", params[:ontology].upcase).gsub(":klass", "roots")} }
  end

  def show
    id = params[:id]
    ontology = params[:ontology]
    if id.downcase.eql?("roots")
      klass = Ontology.find(ontology).root_classes
    else
      klass = Klass.find(id, ontology)
    end
    restful_render(klass)
  end

end
