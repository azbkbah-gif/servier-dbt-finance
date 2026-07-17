{{ 
    config( 
        materialized = 'table', 
        tags = ['silver', 'comptabilite'] 
 
 
    ) 
}} 
  
WITH bkpf AS (SELECT * FROM {{ ref('bz_sap_bkpf') }}), 
     bseg AS (SELECT * FROM {{ ref('bz_sap_bseg') }}) 
  
SELECT 
    CONCAT(b.code_societe,'_',b.numero_document,'_', 
           CAST(b.exercice AS STRING),'_', 
           CAST(b.numero_poste AS STRING))  AS ecriture_pk, 
    h.code_societe, 
    h.numero_document, 
    h.exercice, 
    h.periode_comptable, 
    h.date_piece, 
    h.date_comptable, 
    h.type_document, 
    h.devise, 
    h.reference_externe, 
    h.texte_document, 
    b.numero_poste, 
    b.compte_gl, 
    b.centre_cout, 
    b.code_client, 
    b.code_fournisseur, 
    b.sens_sh, 
    b.texte_poste, 
    CASE 
        WHEN b.sens_sh = 'S' THEN  b.montant_devise_societe 
        WHEN b.sens_sh = 'H' THEN -b.montant_devise_societe 
        ELSE 0 
    END                                    AS montant_eur, 
    b.montant_devise_societe               AS montant_absolu_eur, 
    h.charge_timestamp 
FROM bkpf h 
INNER JOIN bseg b 
    ON h.code_societe    = b.code_societe 
   AND h.numero_document = b.numero_document 
   AND h.exercice        = b.exercice 
WHERE h.statut_document != 'R' 