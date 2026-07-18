-- Rapport de suivi budgétaire : Réel vs Budget
{{ config(
    materialized='table', 
    tags=['gold', 'budget', 'power_bi']
) }} 
 
WITH reel AS ( 
    SELECT 
        code_societe, 
        compte_gl, 
        centre_cout, 
        annee_mois, 
        annee, 
        mois, 
        SUM(solde) AS montant_reel 
    FROM {{ ref('gd_balance_comptable') }} 
    GROUP BY 1,2,3,4,5,6 
), 

-- Budget chargé via dbt seed
budget AS (
    SELECT 
        code_societe,
        compte_gl,
        centre_cout,
        annee_mois,
        -- On s'assure d'extraire proprement annee/mois du budget si non présents dans le CSV
        COALESCE(SAFE_CAST(annee AS INT64), EXTRACT(YEAR FROM SAFE_CAST(annee_mois AS DATE))) AS annee,
        COALESCE(SAFE_CAST(mois AS INT64), EXTRACT(MONTH FROM SAFE_CAST(annee_mois AS DATE))) AS mois,
        montant_budget
    FROM {{ ref('budget_finance') }}
) 
 
SELECT 
    COALESCE(r.code_societe,  b.code_societe)                   AS code_societe, 
    COALESCE(r.compte_gl,     b.compte_gl)                      AS compte_gl, 
    COALESCE(r.centre_cout,   b.centre_cout)                    AS centre_cout, 
    COALESCE(r.annee_mois,    b.annee_mois)                     AS annee_mois, 
    COALESCE(r.annee,         b.annee)                          AS annee, 
    COALESCE(r.mois,          b.mois)                           AS mois, 
    
    COALESCE(r.montant_reel,  0)                                AS montant_reel, 
    COALESCE(b.montant_budget, 0)                               AS montant_budget, 
    
    -- Calcul de l'écart nominal
    COALESCE(r.montant_reel, 0) - COALESCE(b.montant_budget, 0) AS ecart_budget, 
    
    -- Calcul de l'écart en % (Sécurisé par SAFE_DIVIDE contre la division par zéro)
    SAFE_DIVIDE( 
        COALESCE(r.montant_reel, 0) - COALESCE(b.montant_budget, 0), 
        COALESCE(b.montant_budget, 0)
    ) * 100                                                     AS ecart_pct, 
    
    -- Calcul du taux d'exécution (Consommation du budget)
    SAFE_DIVIDE( 
        COALESCE(r.montant_reel, 0), 
        COALESCE(b.montant_budget, 0)
    ) * 100                                                     AS taux_execution_pct 

FROM reel r 
FULL OUTER JOIN budget b 
    ON r.code_societe = b.code_societe 
   AND r.compte_gl   = b.compte_gl 
   AND r.centre_cout = b.centre_cout 
   AND r.annee_mois  = b.annee_mois