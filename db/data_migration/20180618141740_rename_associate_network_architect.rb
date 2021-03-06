old_slug = "associate-network-architect"
new_slug = "associate-network-architect-skills-they-need"

document = Document.find_by(slug: old_slug)

if document
  # remove the most recent edition from the search index
  edition = document.editions.published.last
  Whitehall::SearchIndex.delete(edition)

  # change the slug of the document and create a redirect from the original
  document.update!(slug: new_slug)
  PublishingApiDocumentRepublishingWorker.new.perform(document.id)
end
