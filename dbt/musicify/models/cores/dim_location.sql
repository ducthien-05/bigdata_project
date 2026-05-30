{{ config(materialized = 'table') }}

WITH deduplicated_locations AS (
    SELECT 
        le.city,
        COALESCE(sc.stateCode, 'NA') as stateCode,
        COALESCE(sc.stateName, 'NA') as stateName,
        le.lat as latitude,
        le.lon as longitude,
        ROW_NUMBER() OVER (PARTITION BY le.city, COALESCE(sc.stateCode, 'NA'), le.lat, le.lon ORDER BY le.city) as rn
    FROM {{ ref('stg_listen_events') }} le
    LEFT JOIN {{ ref('state_codes') }} sc 
        ON le.state = sc.stateCode
    WHERE le.city IS NOT NULL
)


SELECT 
    {{ dbt_utils.generate_surrogate_key(['latitude', 'longitude', 'city', 'stateName']) }} as locationKey,
    *
FROM
(
    -- Lấy bộ tọa độ đã được băm sạch sẽ (chỉ lấy rn = 1)
    SELECT city, stateCode, stateName, latitude, longitude
    FROM deduplicated_locations
    WHERE rn = 1

    UNION

    -- Dòng mặc định chống null cho Fact
    SELECT 
        'NA' as city,
        'NA' as stateCode,
        'NA' as stateName,
        0.0 as latitude,
        0.0 as longitude
)