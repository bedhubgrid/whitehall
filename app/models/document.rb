class Document < ActiveRecord::Base
  include Document::Identifiable
  include Document::AccessControl
  include Document::Workflow

  belongs_to :author, class_name: "User"

  has_many :fact_check_requests

  has_many :document_organisations
  has_many :organisations, through: :document_organisations

  has_many :document_relations_to, class_name: "DocumentRelation", foreign_key: 'document_id'
  has_many :document_relations_from, class_name: "DocumentRelation", foreign_key: 'related_document_id'

  has_many :documents_related_with, through: :document_relations_to, source: :related_document
  has_many :documents_related_to, through: :document_relations_from, source: :document

  def can_be_associated_with_topics?
    false
  end

  def can_be_associated_with_ministers?
    false
  end

  def related_documents
    [*documents_related_to, *documents_related_with].uniq
  end

  validates_presence_of :title, :body, :author

  class << self
    def in_organisation(organisation)
      joins(:organisations).where('organisations.id' => organisation)
    end
  end

  def attach_file=(file)
    self.attachment = build_attachment(file: file)
  end

  def submit_as(user)
    update_attribute(:submitted, true)
  end

  def publish_as(user, lock_version = self.lock_version)
    if publishable_by?(user)
      self.lock_version = lock_version
      publish!
      true
    else
      errors.add(:base, reason_to_prevent_publication_by(user))
      false
    end
  end

  def create_draft(user)
    draft_attributes = {
      state: "draft",
      author: user,
      submitted: false,
      organisations: organisations,
      documents_related_with: documents_related_with,
      documents_related_to: documents_related_to
    }
    draft_attributes[:topics] = topics if can_be_associated_with_topics?
    draft_attributes[:ministerial_roles] = ministerial_roles if can_be_associated_with_ministers?
    if respond_to?(:inapplicable_nations)
      draft_attributes[:inapplicable_nations] = inapplicable_nations
    end
    new_draft = self.class.create(attributes.merge(draft_attributes))
    if new_draft.valid? && allows_supporting_documents?
      supporting_documents.each do |sd|
        new_draft.supporting_documents.create(sd.attributes.except("document_id"))
      end
    end
    new_draft
  end

  def allows_attachment?
    respond_to?(:attachment)
  end

  def allows_supporting_documents?
    respond_to?(:supporting_documents)
  end

  def has_supporting_documents?
    allows_supporting_documents? && supporting_documents.any?
  end

  def title_with_state
    state_string = (draft? && submitted?) ? 'submitted' : state
    "#{title} (#{state_string})"
  end
end
