module EPUB
  module Publication
    class Package
      class Spine
        include ContentModel

        attr_accessor :package,
                      :id, :toc, :page_progression_direction
        attr_reader :itemrefs

        # @return self
        def <<(itemref)
          @itemrefs ||= []
          itemref.spine = self
          @itemrefs << itemref
          self
        end

        # @yield [itemref]
        # @yieldparam [Itemref] itemref
        # @yieldreturn [Object] returns the last value of block
        # @return [Object, Enumerator]
        #   returns the last value of block when block given, Enumerator when not
        def each_itemref
          if block_given?
            itemrefs.each {|itemref| yield itemref}
          else
            enum_for :each_itemref
          end
        end

        # @return [Enumerator] Enumerator which yeilds {Manifest::Item}
        #   referred by each of {#itemrefs}
        def items
          itemrefs.collector {|itemref| itemref.item}
        end

        def to_xml_fragment(xml)
          node = xml.spine {
            itemrefs.each do |itemref|
              itemref_node = xml.itemref
              to_xml_attribute itemref_node, itemref, [:idref, :id]
              itemref_node['linear'] = 'no' unless itemref.linear?
              itemref_node['properties'] = itemref.properties.join(' ') unless itemref.properties.empty?
            end
          }
          to_xml_attribute node, self, [:id, :toc, :page_progression_direction]
        end

        class Itemref
          PAGE_SPREAD_PROPERTIES = ['left'.freeze, 'right'.freeze].freeze
          PAGE_SPREAD_PREFIX = 'page-spread-'.freeze

          attr_accessor :spine,
                        :idref, :linear, :id, :properties
          alias linear? linear

          def initialize
            @properties = []
          end

          # @return [Package::Manifest::Item] item referred by this object
          def item
            @item ||= @spine.package.manifest[idref]
          end

          def item=(item)
            self.idref = item.id
            item
          end

          def ==(other)
            [:spine, :idref, :linear, :id].all? {|meth|
              self.__send__(meth) == other.__send__(meth)
            } and (other.properties - properties).empty?
          end

          # @return ["left", "right", nil]
          def page_spread
            property = properties.find {|prop| prop.start_with? PAGE_SPREAD_PREFIX}
            property ? property.gsub(/\A#{Regexp.escape(PAGE_SPREAD_PREFIX)}/, '') : nil
          end

          # @param new_value ["left", "right", nil]
          def page_spread=(new_value)
            if new_value.nil?
              properties.delete_if {|prop| prop.start_with? PAGE_SPREAD_PREFIX}
              return new_value
            end

            raise "Unsupported page-spread property: #{new_value}" unless PAGE_SPREAD_PROPERTIES.include? new_value

            props_to_be_deleted = (PAGE_SPREAD_PROPERTIES - [new_value]).map {|prop| "#{PAGE_SPREAD_PREFIX}#{prop}"}
            properties.delete_if {|prop| props_to_be_deleted.include? prop}
            new_property = "#{PAGE_SPREAD_PREFIX}#{new_value}"
            properties << new_property unless properties.include? new_property
            new_value
          end
        end
      end
    end
  end
end
