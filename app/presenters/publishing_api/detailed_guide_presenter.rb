module PublishingApi
  class DetailedGuidePresenter
    include UpdateTypeHelper

    attr_accessor :item
    attr_accessor :update_type

    def initialize(item, update_type: nil)
      self.item = item
      self.update_type = update_type || default_update_type(item)
    end

    def content_id
      item.content_id
    end

    def content
      content = BaseItemPresenter.new(item).base_attributes
      content.merge!(
        description: item.summary,
        details: details,
        document_type: item.display_type_key,
        public_updated_at: item.public_timestamp || item.updated_at,
        rendering_app: item.rendering_app,
        schema_name: "detailed_guide",
      )
      content.merge!(PayloadBuilder::PublicDocumentPath.for(item))
      content.merge!(PayloadBuilder::AccessLimitation.for(item))
    end

    def links
      LinksPresenter.new(item).extract(
        [
          :organisations,
          :parent,
          :policy_areas,
          :related_policies,
          :topics,
        ]
      ).merge(
        related_guides: item.related_detailed_guide_content_ids,
        related_mainstream: item.related_mainstream
      )
    end

  private

    def maybe_add_national_applicability(content)
      return content unless item.nation_inapplicabilities.any?
      content.merge(national_applicability: item.national_applicability)
    end

    def details
      details_hash = {
        body: body,
        change_history: item.change_history.as_json,
        emphasised_organisations: item.lead_organisations.map(&:content_id),
        first_public_at: first_public_at,
        related_mainstream_content: item.related_mainstream,
      }
      details_hash = maybe_add_national_applicability(details_hash)
      details_hash.merge!(PayloadBuilder::PoliticalDetails.for(item))
      details_hash.merge!(PayloadBuilder::TagDetails.for(item))
    end

    def first_public_at
      (item.document.published? ? item.first_public_at : item.document.created_at).try(:iso8601)
    end


    def body
      Whitehall::GovspeakRenderer.new.govspeak_edition_to_html(item)
    end
  end
end
