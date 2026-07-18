{{ config(
    materialized='table', 
    tags=['gold','comptabilite','power_bi']
) }} 
  
SELECT 
    FORMAT_DATE('%Y-%m', date_comptable)                                 AS annee_mois, 
    EXTRACT(YEAR FROM date_comptable)                                    AS annee, 
    EXTRACT(MONTH FROM date_comptable)                                   AS mois, 
    code_societe, 
    compte_gl, 
    LEFT(CAST(compte_gl AS STRING), 1)                                  AS classe_compte,
    
    -- SÉCURISATION DU CENTRE DE COÛT : Évite les jointures blanches ou cassées dans Power BI
    COALESCE(NULLIF(TRIM(CAST(centre_cout AS STRING)), ''), 'SANS_CDC')  AS centre_cout, 
    
    SUM(CASE WHEN sens_sh = 'S' THEN montant_absolu_eur ELSE 0 END)      AS total_debit, 
    SUM(CASE WHEN sens_sh = 'H' THEN montant_absolu_eur ELSE 0 END)      AS total_credit, 
    SUM(montant_eur)                                                     AS solde, 
    COUNT(DISTINCT numero_document)                                      AS nb_documents, 
    COUNT(*)                                                             AS nb_ecritures 

FROM {{ ref('sv_ecritures_comptables') }} 
WHERE date_comptable IS NOT NULL 
GROUP BY 1, 2, 3, 4, 5, 6, 7