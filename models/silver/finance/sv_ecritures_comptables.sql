{{ config(
    materialized='table',
    unique_key='facture_client_pk'
) }} 
 
WITH vbrk AS (SELECT * FROM {{ ref('bz_sap_vbrk') }}), 
     kna1 AS (SELECT * FROM {{ ref('bz_sap_kna1') }}) 
 
SELECT 
    CONCAT(CAST(h.code_societe AS STRING), '_', LTRIM(CAST(h.numero_facture AS STRING), '0')) AS facture_client_pk, 
    h.code_societe, 
    LTRIM(CAST(h.numero_facture AS STRING), '0') AS numero_facture, 
    -- SAFE_CAST pour sécuriser le partitionnement de BigQuery
    SAFE_CAST(h.date_facture AS DATE) AS date_facture, 
    FORMAT_DATE('%Y-%m', SAFE_CAST(h.date_facture AS DATE)) AS annee_mois, 
    LTRIM(CAST(h.code_client AS STRING), '0') AS code_client, 
    c.raison_sociale                     AS nom_client, 
    c.pays                               AS pays_client, 
    h.devise, 
    h.montant_net_ht, 
    (h.montant_net_ht + h.montant_tva)   AS montant_ttc, 
    h.charge_timestamp
FROM vbrk h 
LEFT JOIN kna1 c ON LTRIM(CAST(h.code_client AS STRING), '0') = LTRIM(CAST(c.code_client AS STRING), '0')
WHERE h.date_facture IS NOT NULL
  AND COALESCE(h.statut_annulation, '') != 'X'