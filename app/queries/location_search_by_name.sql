WITH equal_alias AS (
  SELECT locations.id,
         locations.name,
         locations.population,
         locations.type,
         locations.country_name,
         array_agg(location_aliases.alias) as aliases
  FROM locations
  INNER JOIN location_aliases ON location_aliases.location_id = locations.id
  WHERE ((lower(f_unaccent(:name)) = lower(f_unaccent(location_aliases.alias))))
    AND locations.type IN (:types)
  GROUP BY locations.id, locations.name, locations.population, locations.type, locations.country_name
  LIMIT :limit
),
like_alias AS (
  SELECT locations.id,
         locations.name,
         locations.population,
         locations.type,
         locations.country_name,
         array_agg(location_aliases.alias) as aliases
  FROM locations
  INNER JOIN location_aliases ON location_aliases.location_id = locations.id
  WHERE locations.type IN (:types)
    AND ((lower(f_unaccent(location_aliases.alias)) LIKE lower(f_unaccent('%' || :name || '%'))))
    AND locations.id NOT IN (SELECT id FROM equal_alias)
  GROUP BY locations.id, locations.name, locations.population, locations.type, locations.country_name
  ORDER BY locations.population DESC
  LIMIT :limit
)
SELECT * FROM equal_alias
UNION ALL
SELECT * FROM like_alias
LIMIT :limit

