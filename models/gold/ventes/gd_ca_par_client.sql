-- Rapport d'analyse du Chiffre d'Affaires Ventes par Client (Analyses N vs N-1)
{{ config(
    materialized='table', 
    tags=['gold', 'ventes', 'power_bi']
) }} 

WITH ca_mensuel AS (
    SELECT 
        code_societe, 
        code_client, 
        nom_client, 
        pays_client, 
        annee_mois, 
        EXTRACT(YEAR FROM date_facture)              AS annee, 
        EXTRACT(MONTH FROM date_facture)             AS mois, 
        EXTRACT(QUARTER FROM date_facture)           AS trimestre, 
        -- 📊 Métriques financières validées
        SUM(montant_net_ht)                          AS ca_ht, 
        SUM(montant_ttc)                             AS ca_ttc, 
        COUNT(DISTINCT numero_facture)               AS nb_factures
        -- ❌ Suppression temporaire de la quantité et du prix moyen
    FROM {{ ref('sv_factures_clients') }} 
    GROUP BY 1,2,3,4,5,6,7,8
)

SELECT 
    actuel.*,
    COALESCE(n_moins_1.ca_ht, 0)                      AS ca_n_moins_1, 
    SAFE_DIVIDE(
        actuel.ca_ht - COALESCE(n_moins_1.ca_ht, 0), 
        n_moins_1.ca_ht
    ) * 100                                           AS taux_croissance_pct 
FROM ca_mensuel actuel
LEFT JOIN ca_mensuel n_moins_1 
    ON actuel.code_client = n_moins_1.code_client
    AND actuel.code_societe = n_moins_1.code_societe
    AND actuel.annee = n_moins_1.annee + 1  
    AND actuel.mois = n_moins_1.mois