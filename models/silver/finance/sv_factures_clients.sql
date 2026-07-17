{{ config(
    materialized='incremental',
    unique_key='facture_client_pk', 
    partition_by={'field': 'date_facture', 'data_type': 'date'}
) }} 
 
WITH vbrk AS (SELECT * FROM {{ ref('bz_sap_vbrk') }}), 
     kna1 AS (SELECT * FROM {{ ref('bz_sap_kna1') }}) 
 
SELECT 
    -- Puisqu'on n'a pas de numéro de poste, la PK se base sur la société et la facture
    CONCAT(h.code_societe, '_', h.numero_facture) AS facture_client_pk, 
    h.code_societe, 
    h.numero_facture, 
    h.date_facture, 
    FORMAT_DATE('%Y-%m', h.date_facture) AS annee_mois, 
    h.code_client, 
    c.raison_sociale                     AS nom_client, 
    c.pays                               AS pays_client, 
    h.devise, 
    h.montant_net_ht, 
    -- Si montant_ttc n'est pas dans vbrk, tu peux utiliser (montant_net_ht + montant_tva)
    (h.montant_net_ht + h.montant_tva)   AS montant_ttc, 
    h.charge_timestamp
FROM vbrk h 
LEFT JOIN kna1 c USING (code_client) 
WHERE h.date_facture IS NOT NULL
  AND COALESCE(h.statut_annulation, '') != 'X' 

{% if is_incremental() %}
  -- Ne prend que les nouvelles factures arrivées depuis le dernier run
  AND h.charge_timestamp > (SELECT MAX(charge_timestamp) FROM {{ this }})
{% endif %}