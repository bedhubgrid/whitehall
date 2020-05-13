module Whitehall
  module DocumentFilter
    class Options
      def initialize(options = {})
        @locale = options[:locale] || I18n.locale
      end

      def for(option_name, *args)
        raise ArgumentError.new("Unknown option name #{option_name}") unless valid_option_name?(option_name)

        send(:"options_for_#{option_name}", *args)
      end

      def for_filter_key(filter_key)
        option_name = option_name_for_filter_key(filter_key)
        self.for(option_name)
      end

      def label_for(filter_key, value)
        for_filter_key(filter_key).label_for(value)
      rescue UnknownFilterKey
        nil
      end

      OPTION_NAMES_TO_FILTER_KEYS = {
        document_type: "document_type",
        publication_type: "publication_filter_option",
        organisations: "departments",
        topics: "topics",
        announcement_type: "announcement_filter_option",
        official_documents: "official_document_status",
        locations: "world_locations",
        people: "people",
        taxons: "taxons",
        subtaxons: "subtaxons",
      }.freeze

      def valid_option_name?(option_name)
        OPTION_NAMES_TO_FILTER_KEYS.key?(option_name)
      end

      def valid_filter_key?(filter_key)
        OPTION_NAMES_TO_FILTER_KEYS.value?(filter_key.to_s)
      end

      def invalid_filter_key?(filter_key)
        !valid_filter_key?(filter_key)
      end

      def valid_keys?(filter_keys)
        (filter_keys & valid_keys) == filter_keys
      end

      def valid_resource_filter_options?(filter_options)
        filter_options.each_pair.all? do |key, values|
          values.respond_to?(:all?) && values.all? do |value|
            label_for(key.to_s, value)
          end
        end
      end

      def valid_keys
        OPTION_NAMES_TO_FILTER_KEYS.values
      end

      class UnknownFilterKey < StandardError; end

    protected

      def option_name_for_filter_key(filter_key)
        raise UnknownFilterKey.new("Unknown filter key #{filter_key}") unless valid_filter_key?(filter_key)

        OPTION_NAMES_TO_FILTER_KEYS.key(filter_key)
      end

      def options_for_organisations
        @options_for_organisations ||= StructuredOptions.new(all_label: "All departments", grouped: Organisation.grouped_by_type(@locale))
      end

      def options_for_topics
        @options_for_topics ||= StructuredOptions.new(all_label: "All policy areas", grouped: Classification.grouped_by_type)
      end

      def options_for_taxons
        @options_for_taxons ||= begin
          options = Taxonomy::TopicTaxonomy
                      .new
                      .ordered_taxons
                      .map do |taxon|
            [taxon.name, taxon.content_id]
          end

          StructuredOptions.new(all_label: "All topics", grouped: {}, ungrouped: options)
        end
      end

      def options_for_subtaxons(selected_taxons = [])
        @options_for_subtaxons ||= begin
          level_two_taxons = Taxonomy::TopicTaxonomy
                               .new
                               .ordered_taxons
                               .map(&:descendants)

          options = level_two_taxons.flatten(1).map do |taxon|
            # Only show subtopics that make sense given the selected
            # topic
            show_option = selected_taxons.include?(
              taxon.parent_node.content_id,
            )

            [
              taxon.name,
              taxon.content_id,
              # Add the parent content id, so that the JavaScript can
              # show and hide the options when the taxon filter is
              # changed
              {
                "hidden" => !show_option,
                "data-parent-content-id" => taxon.parent_node.content_id,
              },
            ]
          end

          StructuredOptions.new(all_label: "All subtopics", grouped: {}, ungrouped: options)
        end
      end

      def options_for_people
        @options_for_people ||= StructuredOptions.new(
          all_label: "All people",
          ungrouped: Person.all.sort_by(&:name).map { |o| [o.name, o.slug] },
        )
      end

      def options_for_document_type
        @options_for_document_type ||= StructuredOptions.new(
          all_label: "All document types",
          ungrouped: [
            %w[Announcements announcements],
            %w[Policies policies],
            %w[Publications publications],
          ],
        )
      end

      def options_for_publication_type
        @options_for_publication_type ||= StructuredOptions.create_from_ungrouped("All publication types", Whitehall::PublicationFilterOption.all.sort_by(&:label).map { |o| [o.label, o.slug, o.group_key] })
      end

      def options_for_announcement_type
        @options_for_announcement_type ||= StructuredOptions.create_from_ungrouped("All announcement types", Whitehall::AnnouncementFilterOption.all.sort_by(&:label).map { |o| [o.label, o.slug, o.group_key] })
      end

      def options_for_official_documents
        @options_for_official_documents ||= StructuredOptions.new(
          all_label: "All documents",
          ungrouped: [
            ["Command or act papers", "command_and_act_papers"],
            ["Command papers only", "command_papers_only"],
            ["Act papers only", "act_papers_only"],
          ],
        )
      end

      def options_for_locations
        @options_for_locations ||= StructuredOptions.new(
          all_label: I18n.t("document_filters.world_locations.all"),
          ungrouped: WorldLocation.includes(:translations).ordered_by_name.map { |l| [l.name, l.slug] },
        )
      end
    end
  end
end
