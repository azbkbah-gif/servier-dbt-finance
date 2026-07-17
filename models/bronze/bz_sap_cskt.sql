{{ config(
    materialized='view',
    tags=['bronze', 'sap']
) }}

SELECT
    CAST(MANDT AS INT64)          AS mandt,
    CAST(KOKRS AS INT64)          AS perimetre_analytique,
    TRIM(KOSTL)                   AS KOSTL,             -- Code centre de coût
    
    -- Correction du type Airbyte Boolean -> String pour filtrer sur la langue ('F')
    CASE 
        WHEN SPRAS IS TRUE THEN 'F' 
        ELSE 'E' 
    END                           AS SPRAS,
    
    CAST(DATAB AS STRING)         AS date_debut_validite,
    CAST(DATBI AS STRING)         AS DATBI,             -- Date fin de validite
    TRIM(KTEXT)                   AS KTEXT,             -- Libellé court
    TRIM(LTEXT)                   AS LTEXT,             -- Libellé long
    TRIM(KOSAR)                   AS KOSAR,             -- Type de centre de coût
    TRIM(VERAK)                   AS VERAK,             -- Responsable
    TRIM(ABTEI)                   AS departement_sap,
    _airbyte_emitted_at           AS charge_timestamp
FROM {{ source('raw_sap', 'cskt') }} -- Ajuste ici le nom de ta source Airbyte si nécessaire