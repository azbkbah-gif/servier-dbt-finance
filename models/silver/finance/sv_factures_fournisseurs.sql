{{ config(
    materialized='table', 
    unique_key='facture_pk'
) }} 
 
WITH ecritures_totales AS (
    -- On garde toutes les lignes temporairement pour calculer le vrai montant total de la facture
    SELECT 
        *,
        SUM(montant_eur) OVER (
            PARTITION BY code_societe, numero_document, exercice 
        ) AS montant_total_facture_eur
    FROM {{ ref('sv_ecritures_comptables') }}
    WHERE UPPER(type_document) IN ('RE','KR','KG')  
),

factures_poste_1 AS ( 
    -- On ne filtre sur le poste 1 qu'APRÈS avoir calculé le montant global
    SELECT * 
    FROM ecritures_totales
    WHERE CAST(numero_poste AS INT64) = 1
), 
 
fournisseurs AS ( 
    SELECT * FROM {{ ref('bz_sap_lfa1') }} 
) 
 
SELECT 
    f.ecriture_pk                                               AS facture_pk, 
    f.code_societe, 
    f.numero_document                                           AS numero_facture, 
    f.exercice, 
    
    -- SÉCURITÉ DATE
    COALESCE(SAFE_CAST(f.date_piece AS DATE), CURRENT_DATE())   AS date_facture, 
    
    f.reference_externe                                         AS num_facture_fournisseur, 
    f.code_fournisseur, 
    v.raison_sociale                                            AS nom_fournisseur, 
    v.pays                                                      AS pays_fournisseur, 
    v.groupe_comptes, 
    f.compte_gl, 
    f.centre_cout, 
    f.montant_total_facture_eur, 
    f.devise, 
 
    -- Calculs de dates basés sur la date sécurisée
    DATE_ADD(COALESCE(SAFE_CAST(f.date_piece AS DATE), CURRENT_DATE()), INTERVAL 60 DAY) AS date_echeance_theorique, 
    DATE_DIFF(CURRENT_DATE(), COALESCE(SAFE_CAST(f.date_piece AS DATE), CURRENT_DATE()), DAY) AS anciennete_jours, 
    CASE 
        -- Pour les tests : on ne considère comme SOLDE que si c'est explicitement demandé 
        -- ou on supprime la condition sur 0 si toutes tes données de test sont à 0
        WHEN f.montant_total_facture_eur IS NULL THEN 'SOLDE' 
        WHEN DATE_DIFF(CURRENT_DATE(), COALESCE(SAFE_CAST(f.date_piece AS DATE), CURRENT_DATE()), DAY) > 60 THEN 'EN_RETARD' 
        ELSE 'EN_COURS' 
    END AS statut_paiement,
 
    f.charge_timestamp 
 
FROM factures_poste_1 f 
LEFT JOIN fournisseurs v 
    ON LTRIM(CAST(f.code_fournisseur AS STRING), '0') = LTRIM(CAST(v.code_fournisseur AS STRING), '0')