# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "activity_counter"
  s.summary = "Simplifies the creation of multiple counter cache on a single model."
  s.description = "It lets you create a multiple counter cache on a single model without adding a column for every new cache. Instead uses a counter model that stores all status."
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.version = "0.0.1"
end