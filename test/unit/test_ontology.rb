require 'test_helper'

class TestOntology < ActiveSupport::TestCase
  test "the truth" do
    assert true
  end

  test "describe from triplestore" do
    puts "testing data retrieval from triplestore"
    ont = Ontology.find(44840)
    assert ont.kind_of? Ontology
    assert ont.id == 44840
  end

end
