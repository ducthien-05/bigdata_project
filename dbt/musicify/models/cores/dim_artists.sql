{{ config(materialized = 'table') }}

SELECT {{ dbt_utils.generate_surrogate_key(['artistId']) }} AS artistKey,
    *
FROM (
        SELECT 
            MAX(artist_id) AS artistId,
            MAX(artist_latitude) AS latitude,
            MAX(artist_longitude) AS longitude,
            MAX(artist_location) AS location,
            REPLACE(REPLACE(artist_name, '"', ''), '\\', '') AS name
        FROM {{ ref('stg_songs') }}
        GROUP BY artist_name

        UNION ALL

        SELECT 
            'NNNNNNNNNNNNNNN' AS artistId,
            0.0 AS latitude,
            0.0 AS longitude,
            'NA' AS location,
            'NA' AS name
    )