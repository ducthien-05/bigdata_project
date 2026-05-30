{{ config(materialized = 'table') }}

WITH base_scd2_users AS (
    SELECT 
        user_id as userId, 
        first_name as firstName, 
        last_name as lastName, 
        gender, 
        level, 
        registration_ts as registration, 
        minDate as rowActivationDate,
        LEAD(minDate, 1, '9999-12-31') OVER(PARTITION BY user_id, first_name, last_name, gender ORDER BY grouped) as rowExpirationDate,
        CASE WHEN RANK() OVER(PARTITION BY user_id, first_name, last_name, gender ORDER BY grouped desc) = 1 THEN 1 ELSE 0 END AS currentRow
    FROM
    (
        SELECT 
            user_id, first_name, last_name, gender, registration_ts, level, grouped, 
            CAST(MIN(date) AS DATE) as minDate
        FROM
        (
            SELECT *, SUM(lagged) OVER(PARTITION BY user_id, first_name, last_name, gender ORDER BY date) as grouped
            FROM
            (
                SELECT *, CASE WHEN LAG(level, 1, 'NA') OVER(PARTITION BY user_id, first_name, last_name, gender ORDER BY date) <> level THEN 1 ELSE 0 END AS lagged
                FROM
                (
                    SELECT DISTINCT user_id, first_name, last_name, gender, registration_ts, level, ts AS date
                    FROM {{ ref('stg_listen_events') }}
                    WHERE user_id IS NOT NULL AND user_id != ''
                )
            )
        )
        GROUP BY user_id, first_name, last_name, gender, registration_ts, level, grouped
    )
),

-- BƯỚC 2: Bổ sung lớp khiên chống Fan-out và loại bỏ trùng lặp nếu có nhiều dòng cùng userId và cùng ngày kích hoạt
deduplicated_users AS (
    SELECT 
        *,
        -- Băm theo ID và Ngày kích hoạt. Nếu 1 user có 2 mốc trạng thái trùng ngày, ưu tiên giữ lại trạng thái mới nhất (currentRow = 1)
        ROW_NUMBER() OVER (PARTITION BY userId, rowActivationDate ORDER BY currentRow DESC) as rn
    FROM base_scd2_users
)

-- BƯỚC 3: Tạo Surrogate Key và trả ra kết quả cuối cùng sạch sẽ
SELECT 
    {{ dbt_utils.generate_surrogate_key(['userId', 'rowActivationDate', 'level']) }} as userKey, 
    userId, 
    firstName, 
    lastName, 
    gender, 
    level, 
    registration, 
    rowActivationDate,
    rowExpirationDate,
    currentRow
FROM deduplicated_users
-- Trảm tất cả những dòng bị trùng lặp trong cùng 1 ngày
WHERE rn = 1