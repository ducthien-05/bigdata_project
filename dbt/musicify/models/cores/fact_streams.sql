{{ config(
  materialized = 'table'
) }}

SELECT 
    dim_users.userKey AS userKey,
    dim_artists.artistKey AS artistKey,
    dim_songs.songKey AS songKey,
    dim_datetime.dateKey AS dateKey,
    dim_location.locationKey AS locationKey,
    listen_events.ts AS ts
-- Thay source thô bằng View sạch của chúng ta
 FROM {{ ref('stg_listen_events') }} listen_events

  LEFT JOIN {{ ref('dim_users') }} dim_users
    -- Chú ý: Đổi userId thành user_id cho khớp với cột ở staging
    ON listen_events.user_id = dim_users.userId 
    AND CAST(listen_events.ts AS DATE) >= dim_users.rowActivationDate 
    AND CAST(listen_events.ts AS DATE) < dim_users.rowExpirationDate

  LEFT JOIN {{ ref('dim_artists') }} dim_artists
    ON REPLACE(REPLACE(listen_events.artist, '"', ''), '\\', '') = dim_artists.name

  LEFT JOIN {{ ref('dim_songs') }} dim_songs
    ON REPLACE(REPLACE(listen_events.artist, '"', ''), '\\', '') = dim_songs.artistName 
    AND listen_events.song = dim_songs.title

  LEFT JOIN {{ ref('dim_location') }} dim_location
    ON listen_events.city = dim_location.city 
    AND listen_events.state = dim_location.stateCode 
    AND listen_events.lat = dim_location.latitude 
    AND listen_events.lon = dim_location.longitude 

  LEFT JOIN {{ ref('dim_datetime') }} dim_datetime
    -- Đổi cú pháp date_trunc chuẩn Spark
    ON dim_datetime.date = date_trunc('hour', listen_events.ts)