{{ config(materialized = 'table') }}

SELECT {{ dbt_utils.generate_surrogate_key(['latitude', 'longitude', 'city', 'stateName']) }} as locationKey,
*
FROM
    (
        SELECT DISTINCT
            le.city,
            COALESCE(sc.stateCode, 'NA') as stateCode,
            COALESCE(sc.stateName, 'NA') as stateName,
            le.lat as latitude,
            le.lon as longitude
        FROM {{ ref('stg_listen_events') }} le
        -- JOIN với hạt giống state_codes.csv để lấy tên Bang đầy đủ
        LEFT JOIN {{ ref('state_codes') }} sc 
            ON le.state = sc.stateCode

        UNION ALL

        SELECT 
            'NA',
            'NA',
            'NA',
            0.0,
            0.0
    )