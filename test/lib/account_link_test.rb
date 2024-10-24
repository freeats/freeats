# frozen_string_literal: true

require "test_helper"

class AccountLinkTest < ActiveSupport::TestCase
  test "normalize method should work" do
    github_link = AccountLink.new(
      "http://subdomain.GitHub.com/UserName/?utf8=✓&tab=repositories&q=query&type=&language="
    )
    linkedin_link = AccountLink.new("http://LinkedIn.com/IN/UserName/en/?query=something")
    long_linkedin_link = AccountLink.new("https://www.linkedin.com/in/user-name/details/skills/")
    googledev_link = AccountLink.new("http://developers.google.com/experts/people/user-name")
    fb_link = AccountLink.new("https://www.facebook.com/profile.php?id=000000000000000&sk=about")
    some_link = AccountLink.new("http://SomeSite.com/UserName?query=something&another_query=something")
    some_link_with_sub_domain = AccountLink.new("http://UserName.SomeSite.com?query=something&another_query=something")
    link_with_anchor = AccountLink.new("https://Some.SiteWithAnchor.com/#/content?param=test")
    link_with_non_ansi_char = AccountLink.new("https://www.linkedin.com/in/úšéŕ-ñáḿé-bb0000000/")
    x_twitter_link = AccountLink.new("https://x.com/username")
    twitter_link = AccountLink.new("https://twitter.com/username")

    assert_equal github_link.normalize, "https://github.com/username"
    assert_equal linkedin_link.normalize, "https://www.linkedin.com/in/username/"
    assert_equal long_linkedin_link.normalize, "https://www.linkedin.com/in/user-name/"
    assert_equal googledev_link.normalize, "https://developers.google.com/community/experts/directory/profile/profile-user_name"
    assert_equal some_link.normalize, "http://somesite.com/UserName"
    assert_equal some_link_with_sub_domain.normalize, "http://username.somesite.com"
    assert_equal link_with_anchor.normalize, "https://some.sitewithanchor.com/"
    assert_equal link_with_non_ansi_char.normalize, "https://www.linkedin.com/in/%C3%BA%C5%A1%C3%A9%C5%95-%C3%B1%C3%A1%E1%B8%BF%C3%A9-bb0000000/"
    assert_equal fb_link.normalize, "https://www.facebook.com/profile.php?id=000000000000000"
    assert_equal twitter_link.normalize, "https://x.com/username"
    assert_equal x_twitter_link.normalize, "https://x.com/username"
  end

  test "blacklisted? method should work" do
    assert_predicate AccountLink.new("https://www.linkedin.com/in"), :blacklisted?
    assert_predicate AccountLink.new("http://gist.github.io/"), :blacklisted?
    assert_predicate AccountLink.new("https://img.shields.io/badge/gnuton"), :blacklisted?
    assert_predicate AccountLink.new("http://stats.vercel.app/api/top-langs/"), :blacklisted?
    assert_predicate AccountLink.new("http://README.md"), :blacklisted?
    assert_predicate AccountLink.new("https://raw.githubusercontent.com/visual-studio-code.png"), :blacklisted?
    assert_predicate AccountLink.new("https://www.linkedin.com/profile/view?id=42361418"), :blacklisted?

    assert_not AccountLink.new("https://www.linkedin.com/in/username").blacklisted?
    assert_not AccountLink.new("https://github.com/username").blacklisted?
    assert_not AccountLink.new("https://play.google.com/store/apps/developer?id=Firstname+Lastname").blacklisted?
  end

  test "social? method should work" do
    assert_predicate AccountLink.new("https://www.linkedin.com/in/username"), :social?
    assert_predicate AccountLink.new("https://github.com/username"), :social?
    assert_predicate AccountLink.new("https://www.xing.com/profile/FirstName_LastName/cv"), :social?

    assert_not AccountLink.new("http://klevu.com/").social?
    assert_not AccountLink.new("https://askubuntu.com/questions/1291720/cant-use-the-updated-youtube-dl").social?
  end

  test "instagram links should be recognized regardless of trailing slash" do
    instagram_link_with_trailing_slash = AccountLink.new("https://instagram.com/somepage/")
    instagram_link_no_trailing_slash = AccountLink.new("https://instagram.com/somepage")

    assert_equal instagram_link_with_trailing_slash.domain, { class: "instagram" }
    assert_equal instagram_link_no_trailing_slash.domain, { class: "instagram" }
  end

  test "behance links containing dash should be recognized" do
    behance_link_with_dash = AccountLink.new("https://www.behance.net/username-skill")
    behance_link_no_dash = AccountLink.new("https://www.behance.net/usernameskill")

    assert_equal behance_link_with_dash.domain, { class: "behance" }
    assert_equal behance_link_no_dash.domain, { class: "behance" }
  end

  test "domain method should recognize gitlab links if there are dots in a slug" do
    gitlab_link = AccountLink.new("https://gitlab.com/test.link.os")

    assert_equal gitlab_link.domain[:class], "gitlab"
  end

  test "normalize method should create links to gitlab profile " \
       "out of links with gitlab.io domain" do
    gitlab_resume_link = AccountLink.new("http://user-number123.gitlab.io/")
    gitlab_link = AccountLink.new("http://www.gitlab.io/users/user-number123")
    normalized_gitlab_link = AccountLink.new("http://gitlab.io/user-number123")
    username_with_dot_link = AccountLink.new("http://user.number123.gitlab.io/")
    weird_link = AccountLink.new("http://username.online.gitlab.io/technology-registry/registry.html")

    assert_equal gitlab_resume_link.normalize, "https://gitlab.com/user-number123"
    assert_equal gitlab_link.normalize, "https://gitlab.com/user-number123"
    assert_equal normalized_gitlab_link.normalize, "https://gitlab.com/user-number123"
    assert_equal username_with_dot_link.normalize, "https://gitlab.com/user.number123"
    assert_equal weird_link.normalize, "https://gitlab.com/username.online"
  end

  test "should downcase only username part for github domain" do
    github_link = AccountLink.new("https://github.com/AsDF/Asdf/blob/main/README.md")

    assert_equal github_link.normalize, "https://github.com/asdf/Asdf/blob/main/README.md"
  end
end
