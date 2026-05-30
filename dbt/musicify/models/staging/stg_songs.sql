{{ config(materialized='view') }}

SELECT * FROM {{ source('raw', 'ext_songs') }}