{{ config(materialized='view') }}

WITH source AS (
    SELECT * FROM {{ source('staging', 'auth_events') }}
),

renamed_and_casted AS (
    SELECT
        -- Ép kiểu thời gian chuẩn
        CAST(ts AS TIMESTAMP) AS ts,
        sessionId AS session_id,
        level,
        itemInSession AS item_in_session,
        city,
        state,
        userAgent AS user_agent,
        lon,
        lat,
        userId AS user_id,
        lastName AS last_name,
        firstName AS first_name,
        gender,
        CAST(registration / 1000 AS TIMESTAMP) AS registration_ts,
        success,
        year,
        month,
        day,
        hour
    FROM source
    WHERE userId IS NOT NULL AND userId != ''
)

SELECT * FROM renamed_and_casted