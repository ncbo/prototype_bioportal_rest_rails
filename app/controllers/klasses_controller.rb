class KlassesController < ApplicationController

  def index
    render :json => { :links => { :roots => $BASE_UI_URL + Klass.path.gsub(":ontology", params[:ontology].upcase).gsub(":klass", "roots")} }
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

  def children
    id = params[:id]
    ontology = params[:ontology]
    klass = Klass.find(id, ontology)
    children = []
    klass.children.each do |child|
      children << Klass.find(child, ontology)
    end
    restful_render(children)
  end

end
