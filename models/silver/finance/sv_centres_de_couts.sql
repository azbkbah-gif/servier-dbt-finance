{{ config(materialized='table', tags=['silver', 'comptabilite']) }} 
 
WITH cskt AS ( 
    SELECT 
        KOSTL  AS code_centre_cout, 
        KTEXT  AS libelle_court, 
        LTEXT  AS libelle_long, 
        KOSAR  AS type_centre_cout, 
        VERAK  AS responsable, 
        DATBI  AS date_fin_validite 
    FROM {{ ref('bz_sap_cskt') }} -- <-- Assure-toi que le fichier bz_sap_cskt.sql existe bien dans /models/bronze/
    WHERE SPRAS = 'F'   -- Libellés en français uniquement 
    -- Sécurité : On compare du texte avec du texte au format SAP YYYYMMDD
    AND CAST(DATBI AS STRING) >= FORMAT_DATE('%Y%m%d', CURRENT_DATE()) 
), 
 
-- Enrichissement avec la hiérarchie (seed CSV) 
hierarchie AS ( 
    SELECT * FROM {{ ref('dim_hierarchie_cdc') }} 
) 
 
SELECT 
    c.code_centre_cout, 
    c.libelle_court, 
    c.libelle_long, 
    c.responsable, 
    h.division, 
    h.departement, 
    h.direction, 
    h.business_unit 
FROM cskt c 
LEFT JOIN hierarchie h USING (code_centre_cout)