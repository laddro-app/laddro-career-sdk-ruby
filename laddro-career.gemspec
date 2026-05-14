Gem::Specification.new do |s|
  s.name        = "laddro-career"
  s.version     = "0.2.0" # x-release-please-version
  s.summary     = "Ruby SDK for the Laddro Career API"
  s.description = "Tailor resumes, generate cover letters, and export PDFs via the Laddro Career API"
  s.authors     = ["Laddro"]
  s.email       = "support@laddro.com"
  s.homepage    = "https://docs.laddro.com"
  s.license     = "MIT"
  s.files       = Dir["lib/**/*.rb"]
  s.required_ruby_version = ">= 3.1"
  s.metadata = {
    "source_code_uri" => "https://github.com/laddro-app/laddro-career-sdk-ruby",
    "homepage_uri" => "https://docs.laddro.com"
  }
end
