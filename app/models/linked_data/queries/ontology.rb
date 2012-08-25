# LinkedData::Queries classes provide constants that contain SPARQL queries that are used in their corresponding LinkedData::Record classes via mixin.
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

    ROOT_CLASSES = <<-EOS
      PREFIX owl:  <http://www.w3.org/2002/07/owl#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

      SELECT DISTINCT ?root
      FROM <http://bioportal.bioontology.org/ontologies/%%ID%%>
      WHERE {
        ?root a owl:Class .
        OPTIONAL {
          ?root rdfs:subClassOf ?super
        }
        OPTIONAL {
          ?root owl:equivalentClass ?equiv
        }
        OPTIONAL {
          ?root owl:deprecated ?obsolete
        }
        FILTER (!bound(?super) && !bound(?equiv) && !bound(?obsolete) && isIRI(?root))
      }
    EOS
  end
end