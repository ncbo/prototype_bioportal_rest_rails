class OntologiesController < ApplicationController

  def index
    ontologies = Ontology.all
    restful_render(ontologies)
  end

  def show
    ont = Ontology.find(params[:id], :submission => params[:ontology_submission_id])
    restful_render(ont)
  end

end
