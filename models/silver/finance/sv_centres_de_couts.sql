{{ config(materialized='table', tags=['silver', 'comptabilite']) }} 

WITH cskt AS ( 
    SELECT 
        LTRIM(KOSTL, '0') AS code_centre_cout, 
        KTEXT  AS libelle_court, 
        LTEXT  AS libelle_long, 
        KOSAR  AS type_centre_cout, 
        VERAK  AS responsable, 
        DATBI  AS date_fin_validite 
    FROM {{ ref('bz_sap_cskt') }}
    
    -- MODIFICATION ICI : On passe de 'F' à 'E'
    WHERE SPRAS = 'E'   -- Libellés en anglais (seule langue présente en base)
    
    -- Sécurité Date (conduisant à 99991231, donc valide)
    AND SAFE.PARSE_DATE('%Y%m%d', REGEXP_REPLACE(CAST(DATBI AS STRING), r'[-/]', '')) >= CURRENT_DATE()
), 

-- Enrichissement avec la hiérarchie (seed CSV) 
hierarchie AS ( 
    SELECT 
        LTRIM(CAST(code_centre_cout AS STRING), '0') AS code_centre_cout,
        division,
        departement,
        direction,
        business_unit
    FROM {{ ref('dim_hierarchie_cdc') }} 
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