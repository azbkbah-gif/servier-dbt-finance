-- Ce modèle crée une VUE sur les données brutes SAP -- Il ne transforme rien, il renomme juste les colonnes 
  
{{ 
    config( 
        materialized = 'view', 
        tags = ['bronze', 'sap'] 
    ) 
}} 
  
SELECT 
    CONCAT(MANDT, '_', BUKRS, '_', BELNR, '_', GJAHR) AS bkpf_pk, 
    MANDT   AS mandant, 
    BUKRS   AS code_societe, 
    BELNR   AS numero_document, 
    GJAHR   AS exercice, 
    -- Conversion de l'entier en chaîne de caractères avant le PARSE_DATE
    SAFE.PARSE_DATE('%Y%m%d', CAST(BLDAT AS STRING)) AS date_piece, 
    SAFE.PARSE_DATE('%Y%m%d', CAST(BUDAT AS STRING)) AS date_comptable, 
    BLART   AS type_document, 
    MONAT   AS periode_comptable, 
    BSTAT   AS statut_document, 
    WAERS   AS devise, 
    XBLNR   AS reference_externe, 
 
    BKTXT   AS texte_document, 
    _airbyte_emitted_at AS charge_timestamp 
  
FROM {{ source('sap_raw', 'bkpf') }} 
WHERE MANDT = 100