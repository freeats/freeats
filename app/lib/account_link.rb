# frozen_string_literal: true

class AccountLink
  attr_reader :link, :uri

  def initialize(link)
    @link = link.is_a?(String) ? link&.strip : link
    @uri = Addressable::URI.parse(@link)
    @normalized_link = link.blank? ? link : normalize
  end

  def low_level_domain
    uri.hostname.split(".").first
  end

  def domain
    DOMAINS[normalize]
  end

  def normalize
    return @normalized_link if @normalized_link

    uri.hostname = uri.hostname.downcase if uri.hostname.present?

    normalized_link =
      case uri.domain
      when /hh\.(ru|kz)/
        path = uri.path.last == "/" ? uri.path[0...-1] : uri.path
        "https://#{uri.domain}#{path.downcase}"
      when "github.com"
        splited_path = uri.path.split("/").compact_blank
        username = splited_path.shift

        downcased_url_part = [username].join("/").downcase
        other_url_part = splited_path.join("/")

        normalized_link = "https://#{uri.domain}/#{downcased_url_part}/#{other_url_part}"
        normalized_link.last == "/" ? normalized_link[0...-1] : normalized_link
      when "gitlab.io"
        # Here we pull everything except `www` and `gitlab.io`
        # from the left side of the link.
        host_parts = uri.host.split(".").without("www")[...-2]
        path_parts = uri.path.split("/").compact_blank

        username =
          if host_parts.length.positive?
            host_parts.join(".")
          elsif path_parts.first == "users" && path_parts.length > 1
            path_parts.second
          else
            path_parts.first
          end

        "https://gitlab.com/#{username}"
      when "twitter.com"
        path = uri.path
        "https://x.com#{path}"
      when "linkedin.com"
        path = (uri.path.last == "/" ? uri.path : "#{uri.path}/").downcase
        link_root = "https://www.#{uri.domain}"
        if path.starts_with?("/in/", "/company/", "/school/")
          path = path.split("/")
          "#{[link_root, path[1], path[2]].compact.join('/')}/"
        elsif path.starts_with?("/jobs/view/")
          job_id = path.match(%r{[-/](\d+)}).captures.first
          link_root + "/jobs/view/#{job_id}/"
        else
          link_root + path
        end
      when "google.com"
        if @link.include?("developers.google.com/experts/people")
          path = uri.path.last == "/" ? uri.path[0...-1] : uri.path
          profile = path.downcase.split("/").last.tr!("-", "_")
          "https://#{uri.hostname}/community/experts/directory/profile/profile-#{profile}"
        elsif @link.match?(%r{play.google.com/store/apps/(details|developer)}i)
          "https://play.google.com#{uri.path.downcase}?#{uri.query}"
        else
          uri.fragment = nil
          uri.query = nil
          uri.to_s
        end
      when "xing.com"
        uri.path.delete_suffix!("/cv") if uri.path.ends_with?("/cv")
        uri.to_s
      when "facebook.com", "fb.com"
        uri.path.downcase
        if uri.query&.starts_with?("id=")
          uri.to_s.split("&")[0]
        else
          uri.fragment = nil
          uri.query = nil
          uri.to_s
        end
      when "ycombinator.com"
        uri.to_s
      else
        uri.fragment = nil
        uri.query = nil
        uri.to_s
      end

    # See issue https://github.com/sporkmonger/addressable/issues/511
    if normalized_link.include?("´")
      raise Addressable::URI::InvalidURIError, "Invalid character ´ in link"
    end

    Addressable::URI.normalized_encode(normalized_link)
  end

  def humanize
    Addressable::URI.unencode(normalize)
  end

  def blacklisted?
    BLACKLISTED_LINKS.include?(@normalized_link.chomp("/")) ||
      BLACKLISTED_DOMAIN_NAMES.include?(@normalized_link.chomp("/")) ||
      @normalized_link.starts_with?(*BLACKLISTED_DOMAIN_NAMES.map { "#{_1}/" }) ||
      @normalized_link.split(".").last.in?(BLACKLISTED_EXTENSIONS)
  end

  def social?
    DOMAINS[normalize].present?
  end

  # rubocop:disable Layout/ClassStructure
  DOMAINS = Hashie::Rash.new(
    %r{\.linkedin\.com/in/|linkedin\.com/pub/} => {
      type: :svg,
      params: ["linkedin.svg", { height: 18, width: 18, class: "linkedin-blue" }],
      class: "linkedin"
    },
    %r{hh\.(ru|kz)/resume/\w+$|headhunter\.(ru|kz)/resume/\w+$} => {
      type: :svg,
      params: ["hh_logo.svg", { height: 18, width: 18, class: "hh-red" }],
      class: "hh"
    },
    %r{github\.com/[\w-]+$} => {
      type: :svg,
      params: ["github.svg", { height: 18, width: 18, class: "github-black" }],
      class: "github"
    },
    %r{bitbucket\.org/[%\w-]+$} => { class: "bitbucket" },
    %r{facebook\.com/[\w.]+|fb\.com/[\w.]+} => {
      type: :svg,
      params: ["facebook.svg", { height: 18, width: 18, class: "facebook-blue" }],
      class: "facebook"
    },
    %r{^(https://|http://)?(www.)?(x\.com)/\w+$} => {
      type: :svg,
      params: ["x.svg", { height: 18, width: 18, class: "twitter-black" }],
      class: "twitter"
    },
    %r{500px\.com/\w+} => { params: [{ height: 18, width: 18 }], class: "500px" },
    %r{about\.me/[\w.]+$} => { class: "about" },
    %r{angel\.co/[\w-]+$} => { class: "angel" },
    %r{apple\.com/[\w/-]+$} => {
      type: :svg,
      params: ["apple.svg", { height: 18, width: 18, class: "apple-blue" }],
      class: "apple"
    },
    %r{askubuntu\.com/users/\w+} => { class: "askubuntu" },
    %r{behance\.net/[\w|-]+$} => { class: "behance" },
    %r{blogger\.com/profile/\w+$} => { class: "blogger" },
    %r{\.blogspot\.com/} => { class: "blogspot" },
    %r{codeforces\.com/profile/\w+$} => { class: "codeforces" },
    %r{coderwall\.com/\w+$} => { class: "coderwall" },
    %r{codewars\.com/users/\w+$} => { params: [{ height: 18, width: 18 }], class: "codewars" },
    %r{dev\.to/\w+$} => { params: [{ height: 18, width: 18 }], class: "dev" },
    %r{developers\.google\.com/} => { class: "developers" },
    %r{\.deviantart\.com/} => { class: "deviantart" },
    %r{djinni\.co/home/inbox/} => { params: [{ height: 18, width: 18 }], class: "djinni" },
    %r{dou\.ua/users/[\w-]+/?$} => { params: [{ height: 18, width: 18 }], class: "dou" },
    %r{dribbble\.com/\w+$} => { class: "dribbble" },
    %r{fl\.ru/users/\w+/?$} => { params: [{ height: 18, width: 18 }], class: "fl" },
    %r{flickr\.com/people/\w+$} => { class: "flickr" },
    %r{foursquare\.com/\w+$} => { class: "foursquare" },
    %r{foursquare\.com/user/\w+$} => { class: "foursquare" },
    %r{freelansim\.ru/freelancers/\w+$} => { class: "freelansim" },
    %r{gamedev\.ru/users/\?id=\d+$} => { class: "gamedev" },
    %r{geektimes\.ru/users/\w+$} => { class: "geektimes" },
    %r{gitlab\.com/[\w.-]+$} => { class: "gitlab" },
    %r{goldenline\.pl/[\w-]+} => { class: "goldenline" },
    %r{goodreads\.com/user/} => { class: "goodreads" },
    %r{gravatar\.com/\w+$} => { class: "gravatar" },
    %r{habr\.com/users/\w+$} => { class: "habr" },
    %r{career\.habr\.com/[\w-]+$} => { class: "habrcareer" },
    %r{hackerrank\.com/[\w/_]+$} => { class: "hackerrank" },
    %r{hexlet\.io/u/[\w-]+$} => { class: "hexlet" },
    %r{instagram\.com/[\w.]+/?$} => { class: "instagram" },
    %r{kaggle\.com/\w+$} => { class: "kaggle" },
    %r{keybase\.io/\w+$} => { class: "keybase" },
    %r{last\.fm/user/\w+$} => { class: "last" },
    %r{\.livejournal\.com/} => { class: "livejournal" },
    %r{meetup\.com[\w/-]*/members/\w+} => { class: "meetup" },
    %r{megamozg\.ru/users/\w+$} => { class: "megamozg" },
    %r{mvp\.microsoft\.com/.+/mvp/} => { class: "mvp" },
    %r{news\.ycombinator\.com/user\?id=} => { class: "news" },
    %r{npmjs\.com/~[\w.]+$} => { class: "npmjs" },
    %r{ok\.ru/profile/[\w-]+$} => { class: "ok" },
    %r{openhub\.net/accounts/[\w-]+$} => { class: "openhub" },
    %r{people\.djangoproject\.com/[\w/+]+$} => { class: "djangoproject" },
    %r{picasaweb\.google\.com/[\w.]+$} => { class: "picasaweb" },
    %r{pinterest\.com/\w+$} => { class: "pinterest" },
    %r{pluralsight\.com/id/profile/[\w-]+$} => { class: "pluralsight" },
    %r{play\.google\.com/[\w/+]+$} => {
      type: :svg,
      params: ["google-play.svg", { height: 18, width: 18, class: "play-blue" }],
      class: "play"
    },
    %r{profiles\.google\.com/\w+} => { class: "profiles" },
    %r{quora\.com/profile/[\w-]+$} => { class: "quora" },
    %r{reddit\.com/user/\w+$} => { class: "reddit" },
    %r{researchgate\.net/profile/\w+$} => { class: "researchgate" },
    %r{rubygems\.org/profiles/\w+$} => { class: "rubygems" },
    %r{serverfault\.com/users/\w+$} => { class: "serverfault" },
    %r{slideshare\.net/\w+$} => { class: "slideshare" },
    %r{soundcloud\.com/[\w-]+$} => { class: "soundcloud" },
    %r{sourceforge\.net/u/[\w-]+/profile/?$} => { class: "sourceforge" },
    %r{speakerdeck\.com/[\w-]+$} => { class: "speakerdeck" },
    %r{\.stackexchange\.com/users/[\w/-]+$} => { class: "stackexchange" },
    %r{
      stackoverflow\.com/users/\w+$|stackoverflow\.com/users/\w+/[\w-]+$|
      stackoverflow\.com/cv/[\w-]+$
      }x => {
        class: "stackoverflow"
      },
    %r{superuser\.com/users/\w+$} => { class: "superuser" },
    %r{topcoder\.com/members/\w+$} => { class: "topcoder" },
    %r{toster\.ru/user/\w+$} => { class: "toster" },
    %r{\.tumblr\.com/} => { class: "tumblr" },
    %r{upwork\.com/o/profiles/users/} => { class: "upwork" },
    %r{vimeo\.com/\w+$} => { class: "vimeo" },
    %r{vk\.com/[\w._-]+$|vkontakte\.ru/[\w._-]+$} => {
      type: :svg,
      params: ["vk.svg", { height: 18, width: 18, class: "vk-blue" }],
      class: "vk"
    },
    %r{\.wordpress\.com/} => { class: "wordpress" },
    %r{xing\.com/profile/\w+$} => { class: "xing" },
    %r{youtube\.com/user/\w+$} => { class: "youtube" }
  )
  # rubocop:enable Layout/ClassStructure

  BLACKLISTED_LINKS = %w[
    http://asp.net
    http://www.asp.net
    http://www.asp.net/MVC
    http://www.ado.net
    http://www.m.sc
    http://www.vb.net
    http://www.socket.io
    https://www.linkedin.com/profile/view
    https://www.linkedin.com/feed
    https://www.linkedin.com/in
    http://www.goo.gl
    http://www.epam.com
    http://www.b.sc
    http://gist.github.io
    http://www.google.com
    http://www.t.co
    http://www.mail.ru
    http://www.salesforce.com
    http://www.drupal.org
    http://docs.google.com
    http://www.scand.com
    http://www.brainbench.com
    http://www.bit.ly
    http://drive.google.com
    http://www.microsoft.com
    http://www.coursera.org
    http://www.codeschool.com
    http://www.upwork.com
    http://www.upwork.como/profiles/users/_
    https://www.upwork.com/o/profiles/users/_
    http://www.upwork.com/freelancers
    https://www.facebook.com/app_scoped_user_id
    http://www.force.com
    http://www.codepen.io
    https://www.artstation.com/artist
    http://www.yandex.ru
    http://www.t.me
    http://www.authorize.net
    http://www.parse.com
    http://www.microsoft.net
    http://www.luxoft.com
    http://freelance.ru/users
    http://www.youtu.be
    https://www.youtube.com/user/playlist
    https://www.youtube.com/user/embed
    http://m.in
    http://www.m.in
    http://www.umbrella-web.com
    http://www.tieto.com
    http://www.hackerrank.com
    http://www.gmail.com
    http://www.knowit.no
    http://www.finn.no
    http://www.ericsson.com
    http://mcp.microsoft.com
    http://www.spring.net
    http://www.example.com
    http://www.gitlab.com
    http://www.nokia.com
    http://www.codewars.com
    http://www.certifications.ru
    http://www.cruisecontrol.net
    https://github.com
    https://github.com/pulls
    http://www.akka.net
    http://www.odesk.com
    http://www.htmlacademy.ru
    http://www.udemy.com
    http://www.bouvet.no
    http://www.scrum.org
    http://www.oracle.com
    http://mcp.microsoft.com/authenticate/validatemcp.aspx
    http://www.dataart.com
    http://app.pluralsight.com
    http://www.skype.com
    http://www.webstep.no
    http://www.enonic.com
    http://www.softserveinc.com
    http://www.twitch.tv
    http://www.king.com
    http://www.studio.net
    http://www.jetbrains.com
    http://www.nrk.no
    http://www.zend.com
    http://www.amazon.com
    http://www.spotify.com
    http://www.freelancer.com
    http://www.codecademy.com
    http://www.booking.com
    http://www.kaggle.com
    http://www.opera.com
    http://www.intel.com
    http://www.agilie.com
    http://www.ciklum.com
    http://www.pluralsight.com
    http://store.steampowered.com
    http://www.basic.net
    http://www.toptal.com
    http://www.hiq.se
    http://www.allegro.pl
    http://www.mean.io
    http://www.futurice.com
    http://www.gofore.com
    http://www.wargaming.net
    http://www.cc.net
    http://www.leanpub.com
    http://careers.stackoverflow.com
    https://www.livejournal.com
    https://livejournal.com
    https://www.livejournal.com/profile
    https://livejournal.com/profile
    https://www.facebook.com/profile.php
    http://www.facebook.com/profile.php
    https://facebook.com/profile.php
    http://facebook.com/profile.php
    https://www.slideshare.net/http
    https://play.google.com/store/apps/dev
    https://github.com/anuraghazra/github-readme-stats
  ].freeze

  BLACKLISTED_EXTENSIONS = %w[
    apng
    avif
    bmp
    cur
    gif
    ico
    jfif
    jpeg
    jpg
    pdf
    pjp
    pjpeg
    png
    svg
    tif
    tiff
    webp
  ].freeze

  BLACKLISTED_DOMAIN_NAMES = %w[
    http://stats.vercel.app/api
    https://cdn.jsdelivr.net
    http://readme.md
    https://img.shields.io
  ].freeze
end
