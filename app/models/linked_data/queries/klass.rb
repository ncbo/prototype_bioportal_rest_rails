# LinkedData::Queries classes provide constants that contain SPARQL queries that are used in their corresponding LinkedData::Record classes via mixin.
module LinkedData::Queries
  module Klass

    OBSOLETE_QUERY = <<-EOS
      PREFIX owl: <http://www.w3.org/2002/07/owl#>
      ASK FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%> WHERE { <%%ID%%> a owl:DeprecatedClass }
    EOS

    BASE_ATTR_QUERY = <<-EOS
      PREFIX owl:  <http://www.w3.org/2002/07/owl#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>


      SELECT ?attribute ?value ?bpProp
      FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%>
      FROM <http://bioportal.bioontology.org/ontologies/globals>
      WHERE {
        <%%ID%%> ?attribute ?value .
        ?attribute  rdfs:subPropertyOf ?bpProp .
        FILTER ( ?attribute = skos:prefLabel || ?attribute = skos:altLabel || ?attribute = skos:definition || ?attribute = owl:deprecated )
      }
    EOS

    CHILD_COUNT_QUERY = <<-EOS
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

      SELECT (COUNT(?s) as ?childcount)
      FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%>
      WHERE
      {
        ?s rdfs:subClassOf <%%ID%%>
      }
    EOS

    CHILDREN_QUERY = <<-EOS
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

      SELECT ?child
      FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%>
      WHERE
      {
        ?child rdfs:subClassOf <%%ID%%>
      }
    EOS

    PARENTS_QUERY = <<-EOS
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

      SELECT ?parent
      FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%>
      WHERE
      {
        <%%ID%%> rdfs:subClassOf ?parent
      }
    EOS

  end
end