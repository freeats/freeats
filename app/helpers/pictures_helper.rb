# frozen_string_literal: true

# Use <picture> HTML element to show different versions of an image,
# or when an image is combined with text in a view.
module PicturesHelper
  def picture_avatar_icon(attachment, helper_opts = {}, html_opts = {})
    opts = html_opts
    hopts = { lazy: false }.merge(helper_opts)
    src_sym = :src
    if hopts[:lazy]
      opts = html_opts.merge(class: "lazy") { |_, old, new| "#{old} #{new}" }
      src_sym = :"data-src"
    end

    tag.picture(class: ["d-flex", "align-items-center", *html_opts.delete(:class)]) do
      if attachment && (icon = attachment.variant(:icon)).present?
        if (url = url_for(icon)).present?
          tag.img(src_sym => url, **opts)
        else
          render(
            IconComponent.new(
              :loader,
              **html_opts
            )
          )
        end
      else
        render(
          IconComponent.new(
            :user,
            **html_opts
          )
        )
      end
    end
  end
end
