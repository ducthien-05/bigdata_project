{{ config(materialized = 'table') }}

-- Máy tự động đẻ ra từng giờ một trong năm 2026 (Chuẩn Spark SQL)
WITH date_series AS (
    SELECT explode(sequence(
        to_timestamp('2026-01-01 00:00:00'),
        to_timestamp('2026-12-31 23:59:59'),
        interval 1 hour
    )) AS date
)

SELECT
    CAST(unix_timestamp(date) AS BIGINT) AS dateKey,
    date,
    dayofweek(date) AS dayOfWeek,
    dayofmonth(date) AS dayOfMonth,
    weekofyear(date) AS weekOfYear,
    month(date) AS month,
    year(date) AS year,
    -- Trong Spark: 1 là Chủ Nhật, 7 là Thứ Bảy. Ta đánh cờ cuối tuần
    CASE WHEN dayofweek(date) IN (1, 7) THEN True ELSE False END AS weekendFlag
FROM date_series