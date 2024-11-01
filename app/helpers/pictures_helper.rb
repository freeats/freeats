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
      if attachment && (icon = attachment.variant(:icon)).present?
        if (url = url_for(icon)).present?
          tag.img(src_sym => url, **opts)
        else
          render(
            IconComponent.new(
              :loader,
              class: [*html_opts.delete(:class), "empty-avatar-icon"],
              **html_opts
            )
          )
        end
      else
        render(
          IconComponent.new(
            :user,
            class: [*html_opts.delete(:class), "empty-avatar-icon"],
            **html_opts
          )
        )
      end
    end
  end
end
