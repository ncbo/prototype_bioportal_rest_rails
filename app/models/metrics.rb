class Metrics < LinkedData::Record
  include RestfulLinks
  resource_path "/ontologies/:ontology/metrics"
end