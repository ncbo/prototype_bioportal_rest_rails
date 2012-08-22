require 'test_helper'

class OntologyTest < ActiveSupport::TestCase

  test "describe from triplestore" do
    puts "testing data retrieval from triplestore"
    ont = Ontology.find("nif")
    assert ont.kind_of? Ontology
    assert ont.id.eql?("NIF")
  end

end
