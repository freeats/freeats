-- Params:
-- * thread_ids-- thread's ids for which email messages should be selected
-- * per_page
-- * page
WITH
email_messages AS (
  SELECT
    DISTINCT ON ( email_messages.email_thread_id ) email_messages.*,
    count(email_messages.id) OVER (PARTITION BY email_messages.email_thread_id) AS total_messages_count
  FROM email_messages
  WHERE email_thread_id IN (:thread_ids)
  ORDER BY email_messages.email_thread_id DESC, email_messages.timestamp DESC
  LIMIT :per_page
  OFFSET :per_page * (:page - 1)
)

SELECT
  email_messages.*,
  coalesce((SELECT array_agg(DISTINCT ARRAY[t.name, t.address]) FROM unnest(ema.from_addresses) t(name varchar, address citext)), '{}'::varchar[]) AS from_addresses,
  coalesce((SELECT array_agg(DISTINCT ARRAY[t.name, t.address]) FROM unnest(ema.to_addresses) t(name varchar, address citext)), '{}'::varchar[]) AS to_addresses,
  coalesce((SELECT array_agg(DISTINCT ARRAY[t.name, t.address]) FROM unnest(ema.cc_addresses) t(name varchar, address citext)), '{}'::varchar[]) AS cc_addresses,
  coalesce((SELECT array_agg(DISTINCT ARRAY[t.name, t.address]) FROM unnest(ema.bcc_addresses) t(name varchar, address citext)), '{}'::varchar[]) AS bcc_addresses
FROM email_messages
JOIN LATERAL (
  SELECT
    coalesce(array_agg((name, address) ORDER BY position) FILTER (WHERE field = 'from'), '{}') AS from_addresses,
    coalesce(array_agg((name, address) ORDER BY position) FILTER (WHERE field = 'to'), '{}') AS to_addresses,
    coalesce(array_agg((name, address) ORDER BY position) FILTER (WHERE field = 'cc'), '{}') AS cc_addresses,
    coalesce(array_agg((name, address) ORDER BY position) FILTER (WHERE field = 'bcc'), '{}') AS bcc_addresses
  FROM email_message_addresses
  WHERE email_message_addresses.email_message_id = email_messages.id
  GROUP BY email_message_addresses.email_message_id
) AS ema ON TRUE
ORDER BY email_messages.timestamp DESC
