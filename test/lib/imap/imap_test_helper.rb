# frozen_string_literal: true

require "mail"
require_relative "message_body_test_helper"

# rubocop:disable Layout/LineLength
module ImapTestHelper
  BLANK_AUTOREPLY_HEADERS = {
    auto_submitted: "",
    x_autoreply: "",
    x_autorespond: "",
    precedence: "",
    x_precedence: "",
    x_auto_response_suppress: ""
  }.freeze
  MESSAGE_UID = 1487
  MESSAGE_FLAGS = ["Seen"].freeze
  AUTO_REPLY_MESSAGE = Mail.new(
    Rails.root.join("test/lib/imap/auto_reply_message.raw").read
  )
  MESSAGE_WITH_ATTACHMENT = Mail.new(
    Rails.root.join("test/lib/imap/message_with_attachment.raw").read
  )
  MESSAGE_WITH_ENCODED_BODY = Mail.new(
    Rails.root.join("test/lib/imap/message_with_encoded_body.raw").read
  )
  MESSAGE_WITH_ENCODED_NAME = Mail.new(
    Rails.root.join("test/lib/imap/message_with_encoded_name.raw").read
  )
  MESSAGE_WITH_ONLY_HTML_BODY = Mail.new(
    Rails.root.join("test/lib/imap/message_with_only_html_body.raw").read
  )
  MESSAGE_WITH_NON_UTF_8_BODY = Mail.new(
    Rails.root.join("test/lib/imap/message_with_non_utf_8_body.raw").read
  )
  MESSAGE_WITH_PKCS7_BODY = Mail.new(
    Rails.root.join("test/lib/imap/message_with_pkcs7_body.raw").read
  )
  MESSAGE_WITH_ONLY_PLAIN_BODY = Mail.new(
    Rails.root.join("test/lib/imap/message_with_only_plain_body.raw").read
  )
  MESSAGE_WITH_SERVICE_ADDRESS = Mail.new(
    Rails.root.join("test/lib/imap/message_with_service_address.raw").read
  )
  MESSAGE_WITH_MULTIPLE_ADDRESSES = Mail.new(
    Rails.root.join("test/lib/imap/message_with_multiple_addresses.raw").read
  )
  REPLY_FROM_HUB_MESSAGE = Mail.new(
    Rails.root.join("test/lib/imap/reply_from_hub_message.raw").read
  )
  REPLY_TO_MESSAGE = Mail.new(
    Rails.root.join("test/lib/imap/reply_to_message.raw").read
  )
  SEQUENCE_MESSAGE = Mail.new(
    Rails.root.join("test/lib/imap/sequence_message.raw").read
  )
  SIMPLE_MESSAGE = Mail.new(
    Rails.root.join("test/lib/imap/simple_message.raw").read
  )
  PARSED_SIMPLE_MESSAGE = Imap::Message.new(
    message_id: "<CAHj9ApeDMFnA-nGED5MGsLr3kM3ZF7qztj75To_CxO5Ft7jF+Q@mail.gmail.com>",
    imap_uid: MESSAGE_UID,
    flags: MESSAGE_FLAGS,
    in_reply_to: nil,
    references: [],
    timestamp: 1_706_147_962,
    to: ["Developers <developers@toughbyte.com>"],
    from: ["Admin Second <admin.second@admin.com>"],
    cc: [],
    bcc: [],
    subject: "Report for 25.01.24",
    plain_body: MessageBodyTestHelper::SIMPLE_MESSAGE_PLAIN_BODY,
    plain_mime_type: "text/plain",
    html_body: MessageBodyTestHelper::SIMPLE_MESSAGE_HTML_BODY,
    attachments: [],
    x_failed_recipients: "",
    headers: [
      { "Return-Path" => "<developers+bncBDV4XZ5QTAIBBB4BY6WQMGQENBNHVHA@toughbyte.com>" },
      { "Received" => "by 2002:a59:a763:0:b0:44a:ccd8:b1ad with SMTP id z3csp634500vqs;\r\n        Wed, 24 Jan 2024 17:59:37 -0800 (PST)" },
      { "Received" => "from mail-sor-f69.google.com (mail-sor-f69.google.com. [209.85.220.69])        by mx.google.com with SMTPS id p25-20020a056512329900b005101702db2dsor437450lfe.18.2024.01.24.17.59.36        for <developers@toughbyte.com>        (Google Transport Security);        Wed, 24 Jan 2024 17:59:36 -0800 (PST)" },
      { "Received" => "by 2002:a05:6512:238e:b0:50e:79a5:777e with SMTP id\r\n c14-20020a056512238e00b0050e79a5777els9159lfv.2.-pod-delta-00-eu; Wed, 24 Jan\r\n 2024 17:59:34 -0800 (PST)" },
      { "Received" => "from mail-sor-f41.google.com (mail-sor-f41.google.com. [209.85.220.41])        by mx.google.com with SMTPS id o16-20020a198c10000000b005101c043967sor55353lfd.12.2024.01.24.17.59.33        for <developers@toughbyte.com>        (Google Transport Security);        Wed, 24 Jan 2024 17:59:33 -0800 (PST)" },
      { "Date" => "Thu, 25 Jan 2024 07:59:22 +0600" },
      { "From" => "Admin Second <admin.second@admin.com>" },
      { "To" => "Developers <developers@toughbyte.com>" },
      { "Message-ID" => "<CAHj9ApeDMFnA-nGED5MGsLr3kM3ZF7qztj75To_CxO5Ft7jF+Q@mail.gmail.com>" },
      { "Subject" => "Report for 25.01.24" },
      { "Mime-Version" => "1.0" },
      { "Content-Type" => "multipart/alternative; boundary=\"000000000000dc78cd060fbb87e8\"" },
      { "Delivered-To" => "developers@toughbyte.com" },
      { "X-Received" => "by 2002:a05:6512:52f:b0:50e:30a8:4c8e with SMTP id o15-20020a056512052f00b0050e30a84c8emr95121lfc.43.1706147976752;        Wed, 24 Jan 2024 17:59:36 -0800 (PST)" },
      { "ARC-Seal" => "i=3; a=rsa-sha256; t=1706147976; cv=pass;        d=google.com; s=arc-20160816;        b=gGPyz4MTlEcgtHXPFE1DeEQh+GHpDaTR/CFRnyXrKKD6TtdNPnN7auqtQBzPR53Jc5         TjXLFpu4oaU+Brlhitz2SrV7pH89z5HY2FQOFQVbluID8ZUXDJdhZBUml+977cM6M8cs         4ZTrm/+RCP6fcEqBehV2zVTntEqLuf2XGq2j9n3q7XbuiAThV0Il/wE2QP8uKtoQb93Q         /5tL+culo+NdPO9RsJU04sdjuj/2h0uwQpkh5+cvyaDWj0rQvaIv9+ltLJudY/1XerhY         TfRxNy+QPoGbL8yEAoFShLOjVJRwWX0sEX/0b6klqXAsoNFq1lFTL+k/2oXgNmf+Et0A         RdMw==" },
      { "ARC-Message-Signature" => "i=3; a=rsa-sha256; c=relaxed/relaxed; d=google.com; s=arc-20160816;        h=list-unsubscribe:list-archive:list-help:list-post:list-id         :mailing-list:precedence:to:subject:message-id:date:from         :mime-version:dkim-signature;        bh=JrDfgKgD3fxIaEwe/UVuDOVXvt0kUiZ+K3u86egdlIM=;        fh=mkvyNViEaOQ6J4bqLkFcMoAZrktAT+q8dhgk/AZa5Fg=;        b=dp8XINNEwOqvPl+5GQ1cQxUkSojZ1ttoTJaP1dFZo+fiAnI8keiaEzBkXX18BpbUtw         YeOqPiV/o+TW+eIxe+2ZzwQ8lOihkhccsZQazWQn5WWrxqq/akVfTekQxLEdsIAB8Qoh         o0TCkBzH3IBilgOHiXVFbazrb1LcfR8eWSm2J2C1dqUH/kCyOOHcoijmstDSb9lPv107         GxTW74wU/2W/CqGMSbcwWg2YIDqGC0GMek5j2Wcy9a7zgqmdvHSOFy4cbtDoixs6Ef3I         kIM0tteleRyrwHNm0IYrV+mRRUgAp88PasMuSrCby0cm8mkG0vThHV1ni1QTTWqs12OV         ctCA==" },
      { "ARC-Authentication-Results" => "i=3; mx.google.com;       dkim=pass header.i=@toughbyte.com header.s=google header.b=GmVThoSo;       arc=pass (i=2 spf=pass spfdomain=toughbyte.com dkim=pass dkdomain=toughbyte.com dmarc=pass fromdomain=toughbyte.com);       spf=pass (google.com: domain of developers+bncbdv4xz5qtaibbb4by6wqmgqenbnhvha@toughbyte.com designates 209.85.220.69 as permitted sender) smtp.mailfrom=developers+bncBDV4XZ5QTAIBBB4BY6WQMGQENBNHVHA@toughbyte.com;       dmarc=pass (p=NONE sp=NONE dis=NONE) header.from=toughbyte.com" },
      { "Received-SPF" => "pass (google.com: domain of developers+bncbdv4xz5qtaibbb4by6wqmgqenbnhvha@toughbyte.com designates 209.85.220.69 as permitted sender) client-ip=209.85.220.69;" },
      { "Authentication-Results" => "mx.google.com;       dkim=pass header.i=@toughbyte.com header.s=google header.b=GmVThoSo;       arc=pass (i=2 spf=pass spfdomain=toughbyte.com dkim=pass dkdomain=toughbyte.com dmarc=pass fromdomain=toughbyte.com);       spf=pass (google.com: domain of developers+bncbdv4xz5qtaibbb4by6wqmgqenbnhvha@toughbyte.com designates 209.85.220.69 as permitted sender) smtp.mailfrom=developers+bncBDV4XZ5QTAIBBB4BY6WQMGQENBNHVHA@toughbyte.com;       dmarc=pass (p=NONE sp=NONE dis=NONE) header.from=toughbyte.com" },
      { "ARC-Seal" => "i=2; a=rsa-sha256; t=1706147976; cv=pass;        d=google.com; s=arc-20160816;        b=om7hcNRfUrEQiq1AF3yuB6aY8VugeLNNdJ3mxNJvXkyayaB9EoBbCmopJoSXp3kt+Y         yqce+SauGuEptnfEtMc3err84Np4hOJYWbJKJqqOjb3W6CNZDF7jEqlCaPJGzxMNQTT0         hTophJfAfDrRgCEznQOxh+vG3aGAdbAmSJ+uCdBh/Eae2kl90AiybZDaacBzESiNs3rV         U6CNFEDJjGgibKd8RFnSUfNdxWN8pwI7BQo2LDSNETN2EcNL2Jatxy042MVCg54GAzB8         sGbInXiwyTelXsiVgVQ8VDxiD1h1vHK9kasMRjzFFL8JJ/JuECi4qgF+s3G/QViS5hgw         1TGA==" },
      { "ARC-Message-Signature" => "i=2; a=rsa-sha256; c=relaxed/relaxed; d=google.com; s=arc-20160816;        h=list-unsubscribe:list-archive:list-help:list-post:list-id         :mailing-list:precedence:to:subject:message-id:date:from         :mime-version:dkim-signature;        bh=JrDfgKgD3fxIaEwe/UVuDOVXvt0kUiZ+K3u86egdlIM=;        fh=mkvyNViEaOQ6J4bqLkFcMoAZrktAT+q8dhgk/AZa5Fg=;        b=1CLU9TrzocCHJpDZvleggB/KxjS2nDHhdCOGq4RPkaPGsn3PBxpVkZZ3dKeA7MzC3c         CO7nmjnFrlymCg3xrRAjLu2/oO+wp2GSJHH/5/Vke+sI6xV51J1ADqpqApg58rundKNF         q2J5vgr/aMYLerkHkRWBBaXIylDLOIz/8TjGcCsl0ugvaS1+hnNNT199zyx0+JbNQzaY         +NrKuDr/tqBSSygUq66bK6gQ7zvYWwmttc+JDeB+XKYc/nV9SB47nJSfSVgiAtHyh5dY         O2K+/8afplAw0xhVdHG5mlhKAQKgt9uMO23VCmsNzU+o+tnc3BIPgn02W0z+vZ7hsoYU         xQ2g==" },
      { "ARC-Authentication-Results" => "i=2; mx.google.com;       dkim=pass header.i=@toughbyte.com header.s=google header.b=TzxdsK4Z;       spf=pass (google.com: domain of admin.second@admin.com designates 209.85.220.41 as permitted sender) smtp.mailfrom=admin.second@admin.com;       dmarc=pass (p=NONE sp=NONE dis=NONE) header.from=toughbyte.com" },
      { "DKIM-Signature" => "v=1; a=rsa-sha256; c=relaxed/relaxed;        d=toughbyte.com; s=google; t=1706147976; x=1706752776; darn=toughbyte.com;        h=list-unsubscribe:list-archive:list-help:list-post:list-id         :mailing-list:precedence:x-original-authentication-results         :x-original-sender:to:subject:message-id:date:from:mime-version:from         :to:cc:subject:date:message-id:reply-to;        bh=JrDfgKgD3fxIaEwe/UVuDOVXvt0kUiZ+K3u86egdlIM=;        b=GmVThoSoDdRv7FgVgku7eW+1+zkHN3R2yu3InunfW/0iJnFu1srWGNlIbspQHulGsz         vbMnZFqUsBRAO8avfbOUzBLUw3jjwHn6Rp4Bz6ZKj7Ekjcbh4neqP9WqO4QGJ1iHZgzX         fHmpf7HLZUKbDVyp9qq54cBOD5kwAFuoSjXMvkDnT951QNzc+90zhjRbKOuaVrHnmYqf         6MsHwj6LGMjCzOsOwCZYQwtVQmNN1VnC0k/6PZfN3SYr6q1WuCz5BLOToJN1URnUZTcZ         I50J7dSqnzup+lnL05TlObQwepe2yImtTHL6z2t3cMgdhVM3BW65AhZAOthPvfIeo1oN         X58g==" },
      { "X-Google-DKIM-Signature" => "v=1; a=rsa-sha256; c=relaxed/relaxed;        d=1e100.net; s=20230601; t=1706147976; x=1706752776;        h=list-unsubscribe:list-archive:list-help:list-post         :x-spam-checked-in-group:list-id:mailing-list:precedence         :x-original-authentication-results:x-original-sender:to:subject         :message-id:date:from:mime-version:x-beenthere:x-gm-message-state         :from:to:cc:subject:date:message-id:reply-to;        bh=JrDfgKgD3fxIaEwe/UVuDOVXvt0kUiZ+K3u86egdlIM=;        b=YjLd0DKCRS/Gk26AqTP6CqdGek/MzJvoBh0KGSK5oYp72zqMRAO5WiWubWDBl/9fQ/         o3yG3RyCyCTbR1mUXdCSINpSxGCwDiUtjaAvhlE7T1afGTP6PWrRPspkxHl0t766L3Va         067XTX5XnqKVnHPvzYMo7Lovp2dkwMB7Cel3BpLAU9/6SU92kuW5V6oIGEunw2g+wSfT         a9lU0+3CR6MhTC+kS+J9fpst+iO4Y3RN8DV9i/0/ZbqOGvuQyO3OWczQqLsWCioeacIT         plGAg1tyk00F3d9kzX59NyxVNLSknfLvcwjQFXMMQZjq3tz2Tewx1qc51ka2epH4Rei7         LmWg==" },
      { "X-Gm-Message-State" => "AOJu0Yz2JCgPST31a5fCupE6glbJ+KRQJlFg8Bx31i5dRmUGuzeTOCae\t6RTQU/W0QLPrfRD5D2Eem/TF8kGPDOUTNNE+LpCHLMTm0Dq1GP27RJvEmRqZrBzv" },
      { "X-Google-Smtp-Source" => "AGHT+IErdha3hqG45iYbmb9mNP4ORbZkDiiOB4S5H4zjUEJ/5JJ8MyC7jWecMd/xYrA8R+ExkLEwiw==" },
      { "X-Received" => "by 2002:a19:674b:0:b0:50e:b2f0:3dbb with SMTP id e11-20020a19674b000000b0050eb2f03dbbmr74949lfj.79.1706147975979;        Wed, 24 Jan 2024 17:59:35 -0800 (PST)" },
      { "X-BeenThere" => "developers@toughbyte.com" },
      { "X-Received" => "by 2002:ac2:5f98:0:b0:510:1410:5a72 with SMTP id r24-20020ac25f98000000b0051014105a72mr163853lfe.2.1706147973673;        Wed, 24 Jan 2024 17:59:33 -0800 (PST)" },
      { "ARC-Seal" => "i=1; a=rsa-sha256; t=1706147973; cv=none;        d=google.com; s=arc-20160816;        b=REpPVCcL6IQQSVkzQep/5dtZZ0/anSsRbWTIkI98xPIh8eLmKqUfRqpEGS9oPf9on0         YUenHEAD7IakuW9YrtmaxGFrGelbHmo/oMTL2WlnFRx8+UfrR/LFnliO28ffhJHYzGCy         fqaJsMjfPyAwIgO5wTYeFmtNKjnRD13dMn4XB4StdmdeE307XcelMgVRJjOPQWmK+xt7         rBbTMfsPA+laKpQHJbvkARdFCYaIer7RbgqyA7Se/U9jKu+GzjSdkhvEe3/f49q3+zFA         Mn6bUMm/VnbOYOnVcN4sD4enxAI8/AGe+ypaCRwwhp0zYnenU7j+ELZvfb3kJgetcxuq         nAVg==" },
      { "ARC-Message-Signature" => "i=1; a=rsa-sha256; c=relaxed/relaxed; d=google.com; s=arc-20160816;        h=to:subject:message-id:date:from:mime-version:dkim-signature;        bh=JrDfgKgD3fxIaEwe/UVuDOVXvt0kUiZ+K3u86egdlIM=;        fh=mkvyNViEaOQ6J4bqLkFcMoAZrktAT+q8dhgk/AZa5Fg=;        b=HnjhL3RtrDGG5OcCX50SP3jUsExPjG8W6IIMjXDFIbqhKvEAmnuWqA5XwG4goOMhgh         Ob0UQyU6/A1xgmZ2eA2FoSrGKFfHTtPijGflnN/cx9kb4F99JyiaCPr862RwwmCodO4b         vYjFKN5Yy6bnh3DMFa33oVqiZlMkjkLPnx7bFKjc9+hwx3posqNBkYc2dkMcUyiT0hwB         xm+AsKap+RFOJzwoEMmaJdZJdmJ9ydzK9ocvNuFhaTK7kyU/RrNT3ZXbhRi+L20NLoUe         4Z80mfiksB0Ly1X4dSlKXnPoRzMw7G3RfSgOHwFz+Zol+zesZdbFSXYkOXgMyCyh/LXM         UcSw==" },
      { "ARC-Authentication-Results" => "i=1; mx.google.com;       dkim=pass header.i=@toughbyte.com header.s=google header.b=TzxdsK4Z;       spf=pass (google.com: domain of admin.second@admin.com designates 209.85.220.41 as permitted sender) smtp.mailfrom=admin.second@admin.com;       dmarc=pass (p=NONE sp=NONE dis=NONE) header.from=toughbyte.com" },
      { "Received-SPF" => "pass (google.com: domain of admin.second@admin.com designates 209.85.220.41 as permitted sender) client-ip=209.85.220.41;" },
      { "X-Received" => "by 2002:ac2:4288:0:b0:510:10e0:cc91 with SMTP id m8-20020ac24288000000b0051010e0cc91mr65018lfh.112.1706147972931; Wed, 24 Jan 2024 17:59:32 -0800 (PST)" },
      { "X-Original-Sender" => "admin.second@admin.com" },
      { "X-Original-Authentication-Results" => "mx.google.com;       dkim=pass header.i=@toughbyte.com header.s=google header.b=TzxdsK4Z;       spf=pass (google.com: domain of admin.second@admin.com designates 209.85.220.41 as permitted sender) smtp.mailfrom=admin.second@admin.com;       dmarc=pass (p=NONE sp=NONE dis=NONE) header.from=toughbyte.com" },
      { "Precedence" => "list" },
      { "Mailing-list" => "list developers@toughbyte.com; contact developers+owners@toughbyte.com" },
      { "List-ID" => "<developers.toughbyte.com>" },
      { "X-Spam-Checked-In-Group" => "developers@toughbyte.com" },
      { "X-Google-Group-Id" => "494641124923" },
      { "List-Post" => "<https://groups.google.com/a/toughbyte.com/group/developers/post>, <mailto:developers@toughbyte.com>" },
      { "List-Help" => "<https://support.google.com/a/toughbyte.com/bin/topic.py?topic=25838>, <mailto:developers+help@toughbyte.com>" },
      { "List-Archive" => "<https://groups.google.com/a/toughbyte.com/group/developers/>" },
      { "List-Unsubscribe" => "<mailto:googlegroups-manage+494641124923+unsubscribe@googlegroups.com>, <https://groups.google.com/a/toughbyte.com/group/developers/subscribe>" }
    ],
    autoreply_headers: {
      auto_submitted: "",
      x_autoreply: "",
      x_autorespond: "",
      precedence: "list",
      x_precedence: "",
      x_auto_response_suppress: ""
    }
  )
  PARSED_CANDIDATE_MESSAGE = Imap::Message.new(
    message_id: "<FJDj9ApeDMFnA-nGED5MGsLr3kM3ZF7qztj75To_CxO5Ft7jF+Q@mail.gmail.com>",
    imap_uid: MESSAGE_UID,
    flags: MESSAGE_FLAGS,
    in_reply_to: nil,
    references: [],
    timestamp: 1_706_147_962,
    to: ["Admin Admin <admin@admin.com>"],
    from: ["John London <john@gmail.com>"],
    cc: [],
    bcc: [],
    subject: "Subject",
    plain_body: "Body",
    plain_mime_type: "text/plain",
    html_body: "<h1>Body</h1>",
    attachments: [],
    x_failed_recipients: "",
    headers: [],
    autoreply_headers: {
      auto_submitted: "",
      x_autoreply: "",
      x_autorespond: "",
      precedence: "list",
      x_precedence: "",
      x_auto_response_suppress: ""
    }
  )
end
# rubocop:enable Layout/LineLength
