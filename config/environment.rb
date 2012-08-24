# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BioportalApi::Application.initialize!

$BASE_UI_URL = "http://localhost:2000"