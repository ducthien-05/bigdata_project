{{ config(materialized='view') }}

SELECT * FROM musicify.ext_songs