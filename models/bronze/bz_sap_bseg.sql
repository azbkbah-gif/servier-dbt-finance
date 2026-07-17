{{ config(materialized='view', tags=['bronze','sap']) }} 
SELECT 
    CONCAT(MANDT,'_',BUKRS,'_',BELNR,'_',GJAHR,'_',BUZEI) AS bseg_pk, 
    MANDT               AS mandant, 
    BUKRS               AS code_societe, 
    BELNR               AS numero_document, 
    CAST(GJAHR AS INT64) AS exercice, 
    CAST(BUZEI AS INT64) AS numero_poste, 
    HKONT               AS compte_gl, 
    KOSTL               AS centre_cout, 
    PRCTR               AS centre_profit, 
    KUNNR               AS code_client, 
    LIFNR               AS code_fournisseur, 
    CAST(DMBTR AS NUMERIC) AS montant_devise_societe, 
    CASE WHEN SHKZG IN ('S', 'H') THEN SHKZG ELSE NULL END AS sens_sh, 
    SGTXT               AS texte_poste, 
    _airbyte_emitted_at AS charge_timestamp 
FROM {{ source('sap_raw', 'bseg') }} 
WHERE MANDT = 100 