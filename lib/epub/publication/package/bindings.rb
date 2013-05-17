module EPUB
  module Publication
    class Package
      class Bindings
        include ContentModel

        attr_accessor :package

        def <<(media_type)
          @media_types ||= {}
          @media_types[media_type.media_type] = media_type
        end

        def [](media_type)
          _, mt = @media_types.detect {|key, _| key == media_type}
          mt
        end

        def media_types
          @media_types.values
        end

        def to_xml_fragment(xml)
          xml.bindings {
            media_types.each do |media_type|
              media_type_node = xml.mediaType
              to_xml_attribute media_type_node, media_type, [:media_type]
              media_type_node['handler'] = media_type.handler.id if media_type.handler && media_type.handler.id
            end
          }
        end

        class MediaType
          attr_accessor :media_type, :handler
        end
      end
    end
  end
end
