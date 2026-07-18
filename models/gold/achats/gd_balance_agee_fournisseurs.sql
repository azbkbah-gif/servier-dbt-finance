-- Rapport d'ancienneté des factures fournisseurs non payées (Balance Âgée)
{{ config(
    materialized='table', 
    tags=['gold', 'achats', 'power_bi']
) }} 
 
WITH factures AS ( 
    SELECT 
        *, 
        -- On nomme différemment ici pour éviter le conflit avec la colonne existante
        DATE_DIFF(CURRENT_DATE('Europe/Paris'), date_facture, DAY) AS calcul_anciennete_jours 
    FROM {{ ref('sv_factures_fournisseurs') }} 
    WHERE statut_paiement != 'SOLDE' 
) 
 
SELECT 
    code_societe, 
    code_fournisseur, 
    nom_fournisseur, 
    pays_fournisseur, 
    groupe_comptes, 
 
    -- Tranches d'ancienneté basées sur le calcul explicite
    SUM(CASE WHEN calcul_anciennete_jours BETWEEN 0 AND 30 
             THEN montant_total_facture_eur ELSE 0 END) AS tranche_0_30j, 
    SUM(CASE WHEN calcul_anciennete_jours BETWEEN 31 AND 60 
             THEN montant_total_facture_eur ELSE 0 END) AS tranche_31_60j, 
    SUM(CASE WHEN calcul_anciennete_jours BETWEEN 61 AND 90 
             THEN montant_total_facture_eur ELSE 0 END) AS tranche_61_90j, 
    SUM(CASE WHEN calcul_anciennete_jours > 90 
             THEN montant_total_facture_eur ELSE 0 END) AS tranche_plus_90j, 
             
    SUM(CASE WHEN calcul_anciennete_jours < 0 
             THEN montant_total_facture_eur ELSE 0 END) AS tranche_futur_erreur,
 
    SUM(montant_total_facture_eur)                      AS total_en_cours_eur, 
    COUNT(DISTINCT numero_facture)                      AS nb_factures_ouvertes, 
    
    ROUND(AVG(calcul_anciennete_jours), 1)              AS age_moyen_factures_jours, 
    CURRENT_DATE('Europe/Paris')                        AS date_calcul 
 
FROM factures 
GROUP BY 1, 2, 3, 4, 5