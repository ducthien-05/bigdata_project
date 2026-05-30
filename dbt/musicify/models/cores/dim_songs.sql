{{ config(materialized = 'table') }}

WITH deduplicated_songs AS (
    SELECT 
        song_id as songId,
        REPLACE(REPLACE(artist_name, '"', ''), '\\', '') as artistName,
        duration,
        key,
        key_confidence as keyConfidence,
        loudness,
        song_hotttnesss as songHotness,
        tempo,
        title,
        year,
        -- Đánh số thứ tự các bài hát trùng tên và trùng ca sĩ
        ROW_NUMBER() OVER (PARTITION BY title, REPLACE(REPLACE(artist_name, '"', ''), '\\', '') ORDER BY song_id) as rn
    FROM {{ ref('stg_songs') }}
)

SELECT {{ dbt_utils.generate_surrogate_key(['songId']) }} AS songKey, *
FROM (
        -- Chỉ lấy dòng số 1 của dữ liệu đã lọc
        SELECT songId, artistName, duration, key, keyConfidence, loudness, songHotness, tempo, title, year
        FROM deduplicated_songs
        WHERE rn = 1

        UNION
        -- Dòng NA mặc định
        SELECT 
            'NNNNNNNNNNNNNNNNNNN' as songId,
            'NA' as artistName,
            0.0 as duration,
            -1 as key,
            -1.0 as keyConfidence,
            -1.0 as loudness,
            -1.0 as songHotness,
            -1.0 as tempo,
            'NA' as title,
            0 as year
    )