-- Suivi des flux et positions de trésorerie (Classe 5)
{{ config(
    materialized='table', 
    tags=['gold', 'tresorerie', 'power_bi']
) }} 
 
SELECT 
    code_societe, 
    compte_gl, 
    annee_mois, 
    annee, 
    mois, 
     
    CASE 
        WHEN mois BETWEEN 1 AND 3 THEN 1
        WHEN mois BETWEEN 4 AND 6 THEN 2
        WHEN mois BETWEEN 7 AND 9 THEN 3
        WHEN mois BETWEEN 10 AND 12 THEN 4
    END                          AS trimestre, 
     
    total_debit                  AS encaissements, 
    total_credit                 AS decaissements, 
    solde                        AS flux_net_mensuel, 
 
    -- Reconstruction de la position cumulée par exercice
    SUM(solde) OVER (
        PARTITION BY code_societe, compte_gl, annee
        ORDER BY annee_mois
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                            AS position_tresorerie_cumul,
 
    -- Moyenne glissante 3 mois
    AVG(solde) OVER ( 
        PARTITION BY code_societe, compte_gl 
        ORDER BY annee_mois 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW 
    )                            AS flux_moyen_3_mois 
 
FROM {{ ref('gd_balance_comptable') }} 
-- Version correcte pour BigQuery
WHERE REGEXP_CONTAINS(CAST(compte_gl AS STRING), r'^(401|601)')