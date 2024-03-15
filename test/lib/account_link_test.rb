# frozen_string_literal: true

require "test_helper"

class AccountLinkTest < ActiveSupport::TestCase
  test "normalize method should work" do
    github_link = AccountLink.new(
      "http://subdomain.GitHub.com/UserName/?utf8=✓&tab=repositories&q=query&type=&language="
    )
    hh_link = AccountLink.new("http://HH.ru/UserName?query=something")
    linkedin_link = AccountLink.new("http://LinkedIn.com/IN/UserName/en/?query=something")
    long_linkedin_link = AccountLink.new("https://www.linkedin.com/in/andrey-flegontov/details/skills/")
    googledev_link = AccountLink.new("http://developers.google.com/experts/people/jerry-jalava")
    fb_link = AccountLink.new("https://www.facebook.com/profile.php?id=100003586208563&sk=about")
    some_link = AccountLink.new("http://SomeSite.com/UserName?query=something&another_query=something")
    some_link_with_sub_domain = AccountLink.new("http://UserName.SomeSite.com?query=something&another_query=something")
    link_with_anchor = AccountLink.new("https://Some.SiteWithAnchor.com/#/content?param=test")
    link_with_non_ansi_char = AccountLink.new("https://www.linkedin.com/in/сергей-пашин-bb1924166/")
    x_twitter_link = AccountLink.new("https://x.com/elonmusk")
    twitter_link = AccountLink.new("https://twitter.com/elonmusk")

    assert_equal github_link.normalize, "https://github.com/username"
    assert_equal hh_link.normalize, "https://hh.ru/username"
    assert_equal linkedin_link.normalize, "https://www.linkedin.com/in/username/"
    assert_equal long_linkedin_link.normalize, "https://www.linkedin.com/in/andrey-flegontov/"
    assert_equal googledev_link.normalize, "https://developers.google.com/community/experts/directory/profile/profile-jerry_jalava"
    assert_equal some_link.normalize, "http://somesite.com/UserName"
    assert_equal some_link_with_sub_domain.normalize, "http://username.somesite.com"
    assert_equal link_with_anchor.normalize, "https://some.sitewithanchor.com/"
    assert_equal link_with_non_ansi_char.normalize, "https://www.linkedin.com/in/%D1%81%D0%B5%D1%80%D0%B3%D0%B5%D0%B9-%D0%BF%D0%B0%D1%88%D0%B8%D0%BD-bb1924166/"
    assert_equal fb_link.normalize, "https://www.facebook.com/profile.php?id=100003586208563"
    assert_equal twitter_link.normalize, "https://x.com/elonmusk"
    assert_equal x_twitter_link.normalize, "https://x.com/elonmusk"
  end

  test "blacklisted? method should work" do
    assert_predicate AccountLink.new("https://www.linkedin.com/in"), :blacklisted?
    assert_predicate AccountLink.new("http://gist.github.io/"), :blacklisted?
    assert_predicate AccountLink.new("https://img.shields.io/badge/gnuton"), :blacklisted?
    assert_predicate AccountLink.new("http://stats.vercel.app/api/top-langs/"), :blacklisted?
    assert_predicate AccountLink.new("http://README.md"), :blacklisted?
    assert_predicate AccountLink.new("https://raw.githubusercontent.com/visual-studio-code.png"), :blacklisted?
    assert_predicate AccountLink.new("https://www.linkedin.com/profile/view?id=42361418"), :blacklisted?

    assert_not AccountLink.new("https://www.linkedin.com/in/stepanov").blacklisted?
    assert_not AccountLink.new("https://github.com/greenfork").blacklisted?
    assert_not AccountLink.new("https://play.google.com/store/apps/developer?id=Trino+Alberto+Parra+Figueroa").blacklisted?
  end

  test "social? method should work" do
    assert_predicate AccountLink.new("https://www.linkedin.com/in/stepanov"), :social?
    assert_predicate AccountLink.new("https://github.com/greenfork"), :social?
    assert_predicate AccountLink.new("https://www.xing.com/profile/AlfredoNicolas_Almiron/cv"), :social?

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
    behance_link_with_dash = AccountLink.new("https://www.behance.net/vagharspoghosy-uiux")
    behance_link_no_dash = AccountLink.new("https://www.behance.net/vagharspoghosyuiux")

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
    weird_link = AccountLink.new("http://zdenda.online.gitlab.io/technology-registry/registry.html")

    assert_equal gitlab_resume_link.normalize, "https://gitlab.com/user-number123"
    assert_equal gitlab_link.normalize, "https://gitlab.com/user-number123"
    assert_equal normalized_gitlab_link.normalize, "https://gitlab.com/user-number123"
    assert_equal username_with_dot_link.normalize, "https://gitlab.com/user.number123"
    assert_equal weird_link.normalize, "https://gitlab.com/zdenda.online"
  end

  test "should downcase only username part for github domain" do
    github_link = AccountLink.new("https://github.com/WrMk/Wrmk/blob/main/README.md")

    assert_equal github_link.normalize, "https://github.com/wrmk/Wrmk/blob/main/README.md"
  end
end
