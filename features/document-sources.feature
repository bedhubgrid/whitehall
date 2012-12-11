Feature: Managing Document Sources

  I want to manage the legacy urls on a document.

  Background:
    Given I am a writer

  Scenario: Viewing legacy URLs
    Given a draft publication "One must have many urls" with a legacy url "http://im-old.com"
    When I visit the list of draft documents
    And I view the publication "One must have many urls"
    Then I should see the legacy url "http://im-old.com"

  Scenario: Managing legacy URLs
    Given a draft publication "One must have many urls" exists
    When I add "http://im-old.com" as a legacy url to the "One must have many urls" publication
    And I visit the list of draft documents
    And I view the publication "One must have many urls"
    Then I should see the legacy url "http://im-old.com"
