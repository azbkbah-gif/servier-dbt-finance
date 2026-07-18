{{ config(
    materialized='table', 
    tags=['silver', 'comptabilite']
) }} 

WITH cskt AS ( 
    SELECT 
        LTRIM(KOSTL, '0') AS code_centre_cout, 
        KTEXT  AS libelle_court, 
        LTEXT  AS libelle_long, 
        KOSAR  AS type_centre_cout, 
        VERAK  AS responsable, 
        DATBI  AS date_fin_validite 
    FROM {{ ref('bz_sap_cskt') }}
    
    -- Version stable : Libellés en anglais (seule langue présente en base)
    WHERE SPRAS = 'E' 
    
    -- Sécurité Date (conduisant à 99991231, donc valide)
    AND SAFE.PARSE_DATE('%Y%m%d', REGEXP_REPLACE(CAST(DATBI AS STRING), r'[-/]', '')) >= CURRENT_DATE()
    
    -- DÉDOUBLONNAGE : On ne garde que la période de validité la plus récente par centre de coût
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY LTRIM(KOSTL, '0') 
        ORDER BY SAFE.PARSE_DATE('%Y%m%d', REGEXP_REPLACE(CAST(DATBI AS STRING), r'[-/]', '')) DESC
    ) = 1
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

--  (garde le début de ton fichier sv_centre_cout.sql tel quel) ...

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
-- PROTECTION ULTIME : Force l'unicité stricte par code quoi qu'il arrive après le JOIN
QUALIFY ROW_NUMBER() OVER (PARTITION BY c.code_centre_cout ORDER BY h.division DESC) = 1