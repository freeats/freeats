# frozen_string_literal: true

# rubocop:disable Layout/LineLength
module MessageBodyTestHelper
  SIMPLE_MESSAGE_PLAIN_BODY = <<~TEXT
    Stefan Hammond
    Software Developer at Toughbyte
    <https://www.toughbyte.com/?utm_campaign=bikmeyev&utm_medium=email&utm_source=email>
  TEXT
  SIMPLE_MESSAGE_HTML_BODY =
    "<div dir=\"ltr\"><br clear=\"all\"><div><div dir=\"ltr\" class=\"gmail_signature\" " \
    "data-smartmail=\"gmail_signature\"><div dir=\"ltr\"><br>\n<div><table style=\"" \
    "font-family:Arial,sans-serif;border-spacing:0;max-width:600px;color:#212529\">" \
    "<tbody><tr><td style=\"overflow:hidden;line-height:1.38;vertical-align:top\">" \
    "<img width=\"48\" height=\"48\" style=\"border-radius:2px\" src=\"" \
    "https://dfk1pdma5nc8m.cloudfront.net/assets/email_icons/toughbyte-icon-4cee2a446ffbd279c414027f1bb7fb78886947e991ff20edadd82c066050bb24.png" \
    "\"></td><td style=\"vertical-align:middle;padding:0 0 0 12px;margin-top:1.5px\">" \
    "<div style=\"font-size:16px;font-weight:700;line-height:24px\">Stefan Hammond</div>" \
    "<div style=\"font-size:14px;line-height:21px\">Software Developer at <a style=\"font-weight:700\" " \
    "rel=\"noopener noreferrer\" href=\"https://www.toughbyte.com/?utm_campaign=bikmeyev&amp;utm_medium=email&amp;utm_source=email\" " \
    "target=\"_blank\">Toughbyte</a></div></td></tr></tbody></table></div></div></div></div></div>\n"
end
# rubocop:enable Layout/LineLength
