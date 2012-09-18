# Looks for items that should be cached at startup

unless ENV["RAKE"]
  # Thread.new do
    # puts "Getting predicates from triplestore for ontology"
    # predicates = Ontology.predicates
    # puts predicates
    # $PREDICATES = predicates
  # end
end