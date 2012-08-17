module LinkedData
  module Queries
    module Record
      PREDICATE_QUERY = <<-EOS
        SELECT ?s ?p (COUNT(?o) as ?c) WHERE {
            ?s a <%%RDF_TYPE%%> .
            ?s ?p ?o .
        } GROUP BY ?s ?p
      EOS
    end
  end
end
