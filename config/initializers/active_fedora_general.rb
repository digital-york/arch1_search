require 'noid-rails'

# 2+ [(".reeddeeddk".gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
# 2 + [(Noid::Rails::Config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
baseparts = 6
baseurl = "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}"
ActiveFedora::Base.translate_uri_to_id = lambda do |uri|
  uri.to_s.sub(baseurl, '').split('/', baseparts).last
end
ActiveFedora::Base.translate_id_to_uri = lambda do |id|
  "#{baseurl}/#{Noid::Rails.treeify(id)}"
end
