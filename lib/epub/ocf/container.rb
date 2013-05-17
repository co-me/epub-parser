module EPUB
  class OCF
    class Container
      FILE = 'container.xml'

      attr_reader :rootfiles

      def initialize
        @rootfiles = []
      end

      # syntax sugar
      def rootfile
        rootfiles.first
      end

      def to_xml(options={:encoding => 'UTF-8'})
        Nokogiri::XML::Builder.new {|xml|
          xml.container('xmlns' => EPUB::NAMESPACES['ocf'], 'version' => '1.0') {
            xml.rootfiles {
              rootfiles.each do |rootfile|
                xml.rootfile('full-path' => rootfile.full_path,
                             'media-type' => rootfile.media_type)
              end
            }
          }
        }.to_xml(options)
      end

      class Rootfile
        attr_accessor :full_path, :media_type

        def initialize(full_path=nil, media_type=EPUB::MediaType::ROOTFILE)
          @full_path, @media_type = full_path, media_type
        end
      end
    end
  end
end
