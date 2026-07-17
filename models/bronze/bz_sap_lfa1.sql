{{ config(materialized='view', tags=['bronze','sap']) }} 
SELECT 
    LIFNR  AS code_fournisseur, 
    NAME1  AS raison_sociale, 
    LAND1  AS pays, 
    ORT01  AS ville, 
 
 
    STCEG  AS numero_tva, 
    KTOKK  AS groupe_comptes, 
    _airbyte_emitted_at AS charge_timestamp 
FROM {{ source('sap_raw', 'lfa1') }} 