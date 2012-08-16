# Looks for items that should be cached at startup

puts "Getting predicates from triplestore for ontology"
predicates = Ontology.predicates
puts predicates
$PREDICATES = predicates