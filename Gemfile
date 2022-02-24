source "https://rubygems.org"

gem "rails", "~> 5.2.6.2"

gem "active-fedora", "~> 13.2.0"
gem "iiif-presentation", "~> 1.0.0"
gem "noid-rails"
gem "openseadragon" # to install run: bundle exec rails g openseadragon:install
gem "qa", "~> 5.4.0"
gem "rdf", "~> 3.1.4"
gem "rsolr"
gem "rsolr-ext"

gem "autoprefixer-rails", "~> 8.6.5"
gem "bootstrap-sass", "~> 3.4.1"
gem "coffee-rails"
gem "dotenv-rails", groups: %i[development test production]
gem "font-awesome-sass"
gem "jbuilder", "~> 2.0"
gem "jquery-rails"
gem "nokogiri", ">= 1.11.0"
gem "sass-rails", "~> 5.0"
gem "sdoc", group: :doc
gem "sprockets", "~> 3.7.2"
gem "sqlite3"
gem "therubyracer", platforms: :ruby
gem "tnw_common", git: "https://github.com/digital-york/tnw_common", branch: "main"
gem "turbolinks"
gem "uglifier", ">= 1.3.0"

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "brakeman"
  gem "solargraph"
  gem "standardrb"
  gem "web-console"
  gem "xray-rails"
end
group :development, :test do
  gem "fcrepo_wrapper"
  gem "pry-byebug"
  gem "pry-rails"
  gem "puma"
  gem "rspec-rails", "~> 4.1.0"
  gem "solr_wrapper"
  gem "spring"
  gem "standardrb"
end
