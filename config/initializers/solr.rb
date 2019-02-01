SOLR = YAML.load(ERB.new(IO.read("#{Rails.root.to_s}/config/solr.yml")).result)
