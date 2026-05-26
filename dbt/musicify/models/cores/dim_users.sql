{{ config(materialized = 'table') }}

-- Sử dụng generate_surrogate_key để băm 3 cột thành 1 chuỗi ID duy nhất
SELECT {{ dbt_utils.generate_surrogate_key(['userId', 'rowActivationDate', 'level']) }} as userKey, *
FROM
(
    SELECT 
        user_id as userId, 
        first_name as firstName, 
        last_name as lastName, 
        gender, 
        level, 
        registration_ts as registration, 
        minDate as rowActivationDate,
        -- Lấy ngày bắt đầu của mốc tiếp theo làm ngày kết thúc cho mốc hiện tại
        LEAD(minDate, 1, '9999-12-31') OVER(PARTITION BY user_id, first_name, last_name, gender ORDER BY grouped) as rowExpirationDate,
        -- Đánh dấu dòng mới nhất bằng cờ 1
        CASE WHEN RANK() OVER(PARTITION BY user_id, first_name, last_name, gender ORDER BY grouped desc) = 1 THEN 1 ELSE 0 END AS currentRow
    FROM
    (
        -- Tìm ngày sớm nhất cho mỗi lần thay đổi trạng thái free/paid
        SELECT 
            user_id, 
            first_name, 
            last_name, 
            gender, 
            registration_ts, 
            level, 
            grouped, 
            CAST(MIN(date) AS DATE) as minDate
        FROM
        (
            -- Gom nhóm các khoảng thời gian dùng chung 1 gói cước
            SELECT 
                *, 
                SUM(lagged) OVER(PARTITION BY user_id, first_name, last_name, gender ORDER BY date) as grouped
            FROM
            (
                -- Dùng LAG để soi xem gói cước có bị thay đổi so với dòng trước đó không
                SELECT 
                    *, 
                    CASE WHEN LAG(level, 1, 'NA') OVER(PARTITION BY user_id, first_name, last_name, gender ORDER BY date) <> level THEN 1 ELSE 0 END AS lagged
                FROM
                (
                    -- Lấy dữ liệu SẠCH từ tầng Staging thay vì lấy từ raw source
                    SELECT DISTINCT 
                        user_id,
                        first_name,
                        last_name,
                        gender,
                        registration_ts,
                        level,
                        ts AS date
                    FROM {{ ref('stg_listen_events') }}
                    WHERE user_id IS NOT NULL AND user_id != ''
                )
            )
        )
        GROUP BY user_id, first_name, last_name, gender, registration_ts, level, grouped
    )
)