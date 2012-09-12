class HomeController < ApplicationController

  def index
    demo_ontology = Ontology.find("NCIT")
    demo_class = Klass.find("http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#Anatomic_Structure_System_or_Substance", "NCIT")

    doc_intro = <<-EOS
      The following links can be used to see the functionality available in the API.
      Generally, you can add 'include={property}' when browsing a resource or set of resources to return a custom set of properties.
      The API is meant to be navigated like a normal web page, by starting at the root and following the resource URLs in the 'links' list.
    EOS
    doc_intro.gsub!("\n", "").gsub!(/ {2,}/, " ").strip!

    json = {
      :links => { :ontologies => $BASE_REST_URL + Ontology.path.gsub("/:ontology", "") },
      :demo => [
        doc_intro,
        :ontologies => {
          :ontology => demo_ontology.canonical_path,
          :ontology_all_properties => demo_ontology.canonical_path + "?include=all",
          :ontology_only_name_and_acronym => demo_ontology.canonical_path + "?include=name,acronym"
        },
        :classes => {
          :root_classes => demo_ontology.canonical_path + "/classes/roots",
          :class => demo_class.canonical_path,
          :class_all_properties => demo_class.canonical_path + "?include=all",
          :class_only_label_and_id => demo_class.canonical_path + "?include=label,id"
        }
      ],
      :planned_resources => [
        "The following resources are planned but not yet implemented",
        {
          :ontology_artifacts => [
            "/metrics",
            "/reviews",
            "/categories",
            "/groups",
            "/mappings/{mappingid}",
            "/notes/{noteid}",
            "/projects"
          ],
          :views => [
            "/views"
          ],
          :ontology_related => [
            "/ontologies/{acronym}/reviews",
            "/ontologies/{acronym}/projects",
            "/ontologies/{acronym}/properties",
            "/ontologies/{acronym}/notes",
            "/ontologies/{acronym}/mappings",
            "/ontologies/{acronym}/views"
          ],
          :class_related => [
            "/ontologies/{acronym}/classes/{class_id}",
            "/ontologies/{acronym}/classes/{class_id}/instances",
            "/ontologies/{acronym}/classes/{class_id}/instances/{instance_id}",
            "/ontologies/{acronym}/classes/{class_id}/tree_to_root -- this replaces 'path to root' and provides an expanded tree structure for a given class",
            "/ontologies/{acronym}/classes/{class_id}/notes",
            "/ontologies/{acronym}/classes/{class_id}/mappings",
            "/ontologies/{acronym}/classes/{class_id}/ancestors",
            "/ontologies/{acronym}/classes/{class_id}/descendants"
          ],
          :resource_index => [
            "/resource_index/search",
            "/resource_index/resources",
            "/resource_index/resources/{resource_id}",
            "/resource_index/statistics/system",
            "/resource_index/statistics/ontologies",
            "/resource_index/statistics/ontologies/{acronym}",
            "/resource_index/statistics/resources",
            "/resource_index/statistics/resources/{resource_id}",
            "/resource_index/populations/all",
            "/resource_index/populations/current/resources/{resource_id}",
            "/resource_index/populations/current/ontologies",
            "/resource_index/popular_concepts",
            "/resource_index/resources/{resource_id}/popular_concepts"
          ],
          :process_endpoints => [
            "/search",
            "/view_extractor",
            "/recommender",
            "/annotator"
          ]
        }
      ]
    }

    restful_render(json)
  end

end
