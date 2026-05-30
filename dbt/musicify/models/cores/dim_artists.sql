{{ config(materialized = 'table') }}

WITH cleaned_artists AS (
    SELECT 
        MAX(artist_id) AS artistId,
        MAX(artist_latitude) AS latitude,
        MAX(artist_longitude) AS longitude,
        MAX(artist_location) AS location,
        REPLACE(REPLACE(artist_name, '"', ''), '\\', '') AS name
    FROM {{ ref('stg_songs') }}
    GROUP BY artist_name
),
deduplicated_artists AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY name ORDER BY artistId) as rn
    FROM cleaned_artists
)

SELECT {{ dbt_utils.generate_surrogate_key(['name']) }} AS artistKey, *
FROM (
        SELECT artistId, latitude, longitude, location, name
        FROM deduplicated_artists
        WHERE rn = 1

        UNION

        SELECT 
            'NNNNNNNNNNNNNNN' AS artistId,
            0.0 AS latitude,
            0.0 AS longitude,
            'NA' AS location,
            'NA' AS name
    )