{{ config(materialized='incremental', unique_key='facture_pk', 
          partition_by={'field':'date_facture','data_type':'date'}) }} 
 
WITH factures AS ( 
    SELECT * FROM {{ ref('sv_ecritures_comptables') }} 
    WHERE type_document IN ('RE','KR','KG')  -- Types factures fourn. SAP 
), 
 
fournisseurs AS ( 
    SELECT * FROM {{ ref('bz_sap_lfa1') }} 
) 
 
SELECT 
    f.ecriture_pk                       AS facture_pk, 
    f.code_societe, 
    f.numero_document                   AS numero_facture, 
    f.exercice, 
    f.date_piece                        AS date_facture, 
    f.reference_externe                 AS num_facture_fournisseur, 
    f.code_fournisseur, 
    v.raison_sociale                    AS nom_fournisseur, 
    v.pays                              AS pays_fournisseur, 
    v.groupe_comptes, 
    f.compte_gl, 
    f.centre_cout, 
    SUM(f.montant_eur) OVER ( 
        PARTITION BY f.code_societe, f.numero_document, f.exercice 
    )                                   AS montant_total_facture_eur, 
    f.devise, 
 
    -- Délai standard Servier : 60 jours 
    DATE_ADD(f.date_piece, INTERVAL 60 DAY) AS date_echeance_theorique, 
    DATE_DIFF(CURRENT_DATE(), f.date_piece, DAY) AS anciennete_jours, 
 
    CASE 
        WHEN ABS(f.montant_eur) < 0.01 THEN 'SOLDE' 
        WHEN DATE_DIFF(CURRENT_DATE(), f.date_piece, DAY) > 60 THEN 'EN_RETARD' 
        ELSE 'EN_COURS' 
    END AS statut_paiement, 
 
    f.charge_timestamp 
 
FROM factures f 
LEFT JOIN fournisseurs v USING (code_fournisseur) 
WHERE f.numero_poste = 1  -- 1 ligne par facture