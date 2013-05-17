module EPUB
  module Publication
    class Package
      CONTENT_MODELS = [:metadata, :manifest, :spine, :guide, :bindings]
      RESERVED_VOCABULARY_PREFIXES = {
        ''        => 'http://idpf.org/epub/vocab/package/#',
        'dcterms' => 'http://purl.org/dc/terms/',
        'marc'    => 'http://id.loc.gov/vocabulary/',
        'media'   => 'http://www.idpf.org/epub/vocab/overlays/#',
        'onix'    => 'http://www.editeur.org/ONIX/book/codelists/current.html#',
        'xsd'     => 'http://www.w3.org/2001/XMLSchema#'
      }


      class << self
        def define_content_model(model_name)
          define_method "#{model_name}=" do |model|
            current_model = __send__(model_name)
            current_model.package = nil if current_model
            model.package = self
            instance_variable_set "@#{model_name}", model
          end
        end
      end

      attr_accessor :book,
                    :version, :prefix, :xml_lang, :dir, :id
      attr_reader *CONTENT_MODELS
      alias lang  xml_lang
      alias lang= xml_lang=

      CONTENT_MODELS.each do |model|
        define_content_model model
      end

      def initialize
        @prefix = {}
      end

      def unique_identifier
        @metadata.unique_identifier
      end

      def to_xml
        Nokogiri::XML::Builder.new {|xml|
          xml.package('version' => '3.0',
                      'unique-identifier' => unique_identifier.id,
                      'dir' => dir,
                      'id' => id,
                      'xml:lang' => xml_lang,
                      'prefix' => prefix.reduce('') {|attr, (pfx, iri)| [attr, [pfx, iri].join(':')].join(' ')},
                      'xmlns' => EPUB::NAMESPACES['opf']) do
            (EPUB::Publication::Package::CONTENT_MODELS - [:guide]).each do |model|
              __send__(model).to_xml_fragment xml
            end
          end
        }.to_xml
      end

      module ContentModel
        # @param [Nokogiri::XML::Builder::NodeBuilder] node
        # @param [Object] model
        # @param [Array<Symbol|String>] attributes names of attribute.
        def to_xml_attribute(node, model, attributes)
          attributes.each do |attr|
            val = model.__send__(attr)
            node[attr.to_s.gsub('_', '-')] = val if val
          end
        end
      end
    end
  end
end

EPUB::Publication::Package::CONTENT_MODELS.each do |f|
  require_relative "package/#{f}"
end
