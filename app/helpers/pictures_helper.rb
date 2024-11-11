# frozen_string_literal: true

# Use <picture> HTML element to show different versions of an image,
# or when an image is combined with text in a view.
module PicturesHelper
  def picture_avatar_icon(attachment, opts = {})
    src_sym = :src

    opts[:class] = ["avatar", "avatar-sm", *opts.delete(:class)]

    if (icon = attachment&.variant(:icon)).present?
      if (url = url_for(icon)).present?
        tag.img(src_sym => url, **opts)
      else
        content_tag(
          :span,
          **opts
        ) do
          render(IconComponent.new(:loader))
        end
      end
    else
      content_tag(
        :span,
        **opts
      ) do
        render(IconComponent.new(:user))
      end
    end
  end
end
