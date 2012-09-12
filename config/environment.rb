# Global app settings
$BASE_REST_URL = "http://localhost:2000"
$RDF_ID_BASE = "http://data.bioontology.org"
$GRAPH_ID_BASE = "http://bioportal.bioontology.org"

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BioportalApi::Application.initialize!

