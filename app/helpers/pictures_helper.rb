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

    tag.picture do
      if (icon = attachment.variant(:icon)).present?
        if icon.url.present?
          tag.img(src_sym => icon.url, **opts)
        else
          tag.i(class: ["fal fa-loader", html_opts.delete(:class)], **html_opts)
        end
      else
        image_tag("icons/user.png", **opts)
      end
    end
  end
end
