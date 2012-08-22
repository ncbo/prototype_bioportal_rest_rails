class OntologiesController < ApplicationController

  def index
    ontologies = Ontology.all
    restful_render(ontologies)
  end

  def show
    ont = Ontology.find(params[:id], :version => params[:version])
    restful_render(ont)
  end

end
