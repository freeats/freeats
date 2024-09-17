# frozen_string_literal: true

module MailerHelper
  def mailer_button_link_to(label, path, custom_style: "")
    # In order to make emails look similarly in Microsoft Outlook,
    # we have to consider following limitations:
    # - rem units aren't reliable, only use px and em;
    # - Margins and paddings aren't well supported by Outlook, use other tricks for spacing:
    #   * thick border with the same color as background serving as padding;
    #   * <table> tag with its spacing attributes works well.
    style = <<~TEXT.strip
      line-height: 1.715em;
      border-radius: 0.25em;
      font-size: 14px;
      font-weight: 400;
      font-family: system-ui;
      display: inline-block;
      text-decoration: none;
      color: white;
      background-color: #1c6dd0;
      border: 0.143em solid #1c6dd0;
      border-left-width: 0.572em;
      border-right-width: 0.572em;
    TEXT
    style += custom_style
    link_to(label, path, target: :_blank, style:)
  end

  def mailer_blockquote(&block)
    style = <<~TEXT.strip
      border-left: 2px solid gray;
      padding-left: 1em;
    TEXT
    tag.blockquote(style:) { yield block }
  end
end
