{{ config(materialized='view', tags=['bronze','sap']) }} 
SELECT 
    KUNNR  AS code_client, 
    NAME1  AS raison_sociale, 
    LAND1  AS pays, 
    ORT01  AS ville, 
    _airbyte_emitted_at AS charge_timestamp 
FROM {{ source('sap_raw', 'kna1') }}