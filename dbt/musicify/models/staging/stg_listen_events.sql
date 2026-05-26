{{ config(materialized='view') }}

WITH source AS (
    -- Gọi dữ liệu gốc từ cấu hình sources.yml
    SELECT * FROM {{ source('staging', 'listen_events') }}
),

renamed_and_casted AS (
    SELECT
        artist,
        song,
        duration,
        -- Xử lý logic thời gian của tác giả: Chuyển chuỗi mili-giây thành chuẩn TIMESTAMP của Spark
        CAST(ts AS TIMESTAMP) AS ts,
        auth,
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
        year,
        month,
        day,
        hour
    FROM source
    WHERE userId IS NOT NULL AND userId != ''
)

SELECT * FROM renamed_and_casted