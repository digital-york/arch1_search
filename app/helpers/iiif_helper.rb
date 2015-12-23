# added (ja)
require 'iiif/presentation'

module IiifHelper

  def make_manifest(pid)
    @query_obj = SolrQuery.new
    canvas(pid,manifest(pid)).to_json(pretty: true)
  end

  def manifest(pid)
    resp = @query_obj.solr_query('id:"' + pid + '"',fl='reg_id_tesim,preflabel_tesim',rows=1)['response']['docs']

    seed = {
        '@id' => 'http://example.com/manifest',
        'label' => resp[0]['reg_id_tesim'],
        'description' => resp[0]['preflabel_tesim'],
        'attribution' => 'Made available by the University of York',
        'license' => 'http://creativecommons.org/licenses/by-sa/4.0/'
        # TODO thumbnail
    }

    manifest = IIIF::Presentation::Manifest.new(seed)
    manifest
  end

  def canvas(pid,manifest)

    @query_obj.solr_query('id:"' + pid + '/list_source"',fl='ordered_targets_ssim',rows=1)['response']['docs'][0]['ordered_targets_ssim'].each do |target|
      resp = @query_obj.solr_query('id:"' + target + '"',fl='id,preflabel_tesim',rows=1)['response']['docs']
      canvas = IIIF::Presentation::Canvas.new()
      canvas['@id'] = 'http://example.com/folio/' + resp[0]['id']
      canvas.width = 10 # TODO required
      canvas.height = 20 # TODO required
      canvas.label = resp[0]['preflabel_tesim']
      canvas['on'] = 'http://example.com/folio/' + resp[0]['id']

      @query_obj.solr_query('hasTarget_ssim:"'+ resp[0]['id'] + '"',fl='id,file_path_tesim',rows=1)['response']['docs'].each do |image|
        begin
          img = IIIF::Presentation::Annotation.new(
              'resource' => IIIF::Presentation::ImageResource.new(
                  '@id' => "http://example.com/iip-url/#{image['file_path_tesim'].join}",
                  'service' => {
                      '@id' => "http://example.com/image/#{image['id']}",
                      '@context' => 'http://iiif.io/api/image/2/context.json',
                      'profile' => 'http://iiif.io/api/image/2/level1.json'
                  },
                  'format' => 'image/jp2'
              )
          )
          canvas.images << img
        rescue
        end
      end
      manifest.sequences << canvas
    end
    manifest
  end
end
