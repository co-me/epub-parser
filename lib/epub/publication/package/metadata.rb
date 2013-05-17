module EPUB
  module Publication
    class Package
      class Metadata
        include MethodDecorators
        extend MethodDecorators
        include ContentModel

        DC_ELEMS = [:identifiers, :titles, :languages] +
                   [:contributors, :coverages, :creators, :dates, :descriptions, :formats, :publishers,
                    :relations, :rights, :sources, :subjects, :types]
        attr_accessor :package, :unique_identifier, :metas, :links,
                      *(DC_ELEMS.collect {|elem| "dc_#{elem}"})
        DC_ELEMS.each do |elem|
          alias_method elem, "dc_#{elem}"
          alias_method "#{elem}=", "dc_#{elem}="
        end

        def initialize
          (DC_ELEMS + [:metas, :links]).each do |elem|
            __send__ "#{elem}=", []
          end
        end

        def title
          return extended_title unless extended_title.empty?
          compositted = titles.select {|title| title.display_seq}.sort.join("\n")
          return compositted unless compositted.empty?
          return main_title unless main_title.empty?
          titles.sort.join("\n")
        end

        %w[ main short collection edition extended ].each do |type|
          define_method "#{type}_title" do
            titles.select {|title| title.title_type.to_s == type}.sort.join(' ')
          end
        end

        def subtitle
          titles.select {|title| title.title_type.to_s == 'subtitle'}.sort.join(' ')
        end

        def description
          descriptions.join ' '
        end

        def date
          dates.first
        end

        def to_xml_fragment(xml)
          xml.metadata('xmlns:dc' => EPUB::NAMESPACES['dc']) {
            (DC_ELEMS - [:languages]).each do |elems|
              singular = elems[0..-2]
              __send__("dc_#{elems}").each do |elem|
                node = xml['dc'].__send__(singular, elem.content)
                to_xml_attribute node, elem, [:id, :dir]
                node['xml:lang'] = elem.lang if elem.lang
              end
            end
            languages.each do |language|
              xml.language language
            end

            metas.each do |meta|
              node = xml.meta(meta.content)
              to_xml_attribute node, meta, [:property, :id, :scheme]
              node['refines'] = "##{meta.refines.id}" if meta.refines
            end

            links.each do |link|
              node = xml.link
              to_xml_attribute node, link, [:href, :id, :media_type]
              node['rel'] = link.rel.join(' ') if link.rel
              node['refines'] = "##{link.refines.id}" if link.refines
            end
          }
        end

        def to_h
          DC_ELEMS.inject({}) do |hsh, elem|
            hsh[elem] = __send__(elem)
            hsh
          end
        end

        +Deprecated.new {|klass, method| "#{klass}##{method} is deprecated. Use #to_h instead."}
        def to_hash
          to_h
        end

        def primary_metas
          metas.select {|meta| meta.primary_expression?}
        end

        module Refinee
          PROPERTIES = %w[ alternate-script display-seq file-as group-position identifier-type meta-auth role title-type ]

          attr_writer :refiners

          def refiners
            @refiners ||= []
          end

          PROPERTIES.each do |voc|
            met = voc.gsub(/-/, '_')
            attr_writer met
            define_method met do
              refiners.selector {|refiner| refiner.property == voc}.first
            end
          end
        end

        class DCMES
          include Refinee

          attr_accessor :content, :id, :lang, :dir

          def inspect
            ivs = instance_variables.map {|iv|
              [iv, instance_variable_get(iv).inspect].join('=')
            }.join(' ')
            '<#%s:%#0x %s>' % [self.class, __id__, ivs]
          end

          def to_s
            content
          end
        end

        class Title < DCMES
          include Comparable

          def <=>(other)
            return 1 if other.display_seq.nil?
            return -1 if display_seq.nil?
            display_seq.to_s.to_i <=> other.display_seq.to_s.to_i
          end
        end

        class Meta
          include Refinee

          attr_accessor :property, :id, :scheme, :content
          attr_reader :refines

          def refines=(refinee)
            @refines = refinee
            refinee.refiners << self
          end

          def refines?
            ! refines.nil?
          end
          alias subexpression? refines?

          def primary_expression?
            ! subexpression?
          end

          def inspect
            ivs = instance_variables.map {|iv|
              [iv, instance_variable_get(iv).inspect].join('=')
            }.join(' ')
            '<#%s:%#0x %s>' % [self.class, __id__, ivs]
          end

          def to_s
            content
          end
        end

        class Link
          include Refinee

          attr_accessor :href, :rel, :id, :media_type
          attr_reader :refines

          def refines=(refinee)
            @refines = refinee
            refinee.refiners << self
          end
        end
      end
    end
  end
end
