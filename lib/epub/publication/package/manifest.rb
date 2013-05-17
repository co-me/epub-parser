require 'enumerabler'
require 'epub/constants'
require 'epub/parser/content_document'

module EPUB
  module Publication
    class Package
      class Manifest
        include ContentModel

        attr_accessor :package,
                      :id

        # @return self
        def <<(item)
          @items ||= {}
          item.manifest = self
          @items[item.id] = item
          self
        end

        def navs
          items.selector(&:nav?)
        end

        def nav
          navs.first
        end

        def cover_image
          items.selector {|i| i.properties.include? 'cover-image'}.first
        end

        def each_item
          @items.each_value do |item|
            yield item
          end
        end

        def items
          @items.values
        end

        def [](item_id)
          @items[item_id]
        end

        def to_xml_fragment(xml)
          node = xml.manifest {
            items.each do |item|
              item_node = xml.item
              to_xml_attribute item_node, item, [:id, :href, :media_type, :media_overlay]
              item_node['properties'] = item.properties.join(' ') unless item.properties.empty?
              item_node['fallback'] = item.fallback.id if item.fallback
            end
          }
          to_xml_attribute node, self, [:id]
        end

        class Item
          # @!attribute [rw] manifest
          #   @return [Manifest] Returns the value of manifest
          # @!attribute [rw] id
          #   @return [String] Returns the value of id
          # @!attribute [rw] href
          #   @return [Addressable::URI] Returns the value of href
          # @!attribute [rw] media_type
          #   @return [String] Returns the value of media_type
          # @!attribute [rw] properties
          #   @return [Array<String>] Returns the value of properties
          # @!attribute [rw] media_overlay
          #   @return [String] Returns the value of media_overlay
          # @!attribute [rw] fallback
          #   @return [Item] Returns the value of attribute fallback
          attr_accessor :manifest,
                        :id, :href, :media_type, :fallback, :properties, :media_overlay

          # @todo Handle circular fallback chain
          def fallback_chain
            @fallback_chain ||= traverse_fallback_chain([])
          end

          def read
            rootfile = Addressable::URI.parse(manifest.package.book.ocf.container.rootfile.full_path)
            Zip::Archive.open(manifest.package.book.epub_file) {|zip|
              path = Addressable::URI.unescape(rootfile + href.normalize.request_uri)
              zip.fopen(path).read
            }
          end

          def nav?
            properties.include? 'nav'
          end

          # @todo Handle circular fallback chain
          def use_fallback_chain(options = {})
            supported = EPUB::MediaType::CORE
            if ad = options[:supported]
              supported = supported | (ad.respond_to?(:to_ary) ? ad : [ad])
            end
            if del = options[:unsupported]
              supported = supported - (del.respond_to?(:to_ary) ? del : [del])
            end

            return yield self if supported.include? media_type
            if (bindings = manifest.package.bindings) && (binding_media_type = bindings[media_type])
              return yield binding_media_type.handler
            end
            return fallback.use_fallback_chain(options) {|fb| yield fb} if fallback
            raise EPUB::MediaType::UnsupportedError
          end

          def content_document
            return nil unless %w[application/xhtml+xml image/svg+xml].include? media_type
            @content_document ||= Parser::ContentDocument.new(self).parse
          end

          # @return [Package::Spine::Itemref]
          # @return nil when no Itemref refers this Item
          def itemref
            manifest.package.spine.itemrefs.find {|itemref| itemref.idref == id}
          end

          protected

          def traverse_fallback_chain(chain)
            chain << self
            return chain unless fallback
            fallback.traverse_fallback_chain(chain)
          end
        end
      end
    end
  end
end
