module LinkedData::Queries
  module Ontology
    ALL_ONTS = <<-EOS
      PREFIX bp: <http://bioportal.bioontology.org/metadata/>

      SELECT DISTINCT *
      WHERE
      {
        ?s a bp:OntologyContainer .
        ?s ?p ?o .
        OPTIONAL { ?s bp:relatedOntology ?viewOf }
        FILTER (!bound(?viewOf))
      }
    EOS

  end
end