FactoryGirl.define do
  factory :case_study, class: CaseStudy, parent: :edition do
    title "case-study-title"
    summary "case-study-summary"
    body  "case-study-body"
  end

  factory :imported_case_study, parent: :case_study, traits: [:imported]
  factory :draft_case_study, parent: :case_study, traits: [:draft]
  factory :submitted_case_study, parent: :case_study, traits: [:submitted]
  factory :rejected_case_study, parent: :case_study, traits: [:rejected]
  factory :published_case_study, parent: :case_study, traits: [:published] do
    first_published_at { 2.days.ago }
  end
  factory :deleted_case_study, parent: :case_study, traits: [:deleted]
  factory :archived_case_study, parent: :case_study, traits: [:archived]
  factory :scheduled_case_study, parent: :case_study, traits: [:scheduled]
end
