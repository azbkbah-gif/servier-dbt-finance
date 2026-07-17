{{ config(materialized='view', tags=['bronze','sap']) }} 
SELECT 
    CONCAT(BUKRS,'_',VBELN)         AS vbrk_pk, 
    BUKRS  AS code_societe, 
    VBELN  AS numero_facture, 
    KUNAG  AS code_client, 
    -- Fermeture de la parenthèse manquante + ajout de la virgule à la fin
    SAFE.PARSE_DATE('%Y%m%d', CAST(FKDAT AS STRING)) AS date_facture,  
    WAERK  AS devise, 
    CAST(NETWR AS NUMERIC) AS montant_net_ht, 
    CAST(MWSBK AS NUMERIC) AS montant_tva, 
    FKSTO  AS statut_annulation, 
    _airbyte_emitted_at AS charge_timestamp 
FROM {{ source('sap_raw', 'vbrk') }} 
WHERE MANDT = 100