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
      :links => { :ontologies => $BASE_UI_URL + Ontology.path.gsub("/:ontology", "") },
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
            "/ontologies/{acronym}/classes/{classid}",
            "/ontologies/{acronym}/classes/{classid}/instances",
            "/ontologies/{acronym}/classes/{classid}/instances/{instance_id}",
            "/ontologies/{acronym}/classes/tree -- this replaces 'path to root' and provides an expanded tree structure for a given class",
            "/ontologies/{acronym}/classes/{classid}/notes",
            "/ontologies/{acronym}/classes/{classid}/mappings"
          ],
          :process_endpoints => [
            "/search",
            "/view_extractor",
            "/recommender",
            "/resource_index",
            "/annotator"
          ]
        }
      ]
    }

    restful_render(json)
  end

end
