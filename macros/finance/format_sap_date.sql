-- Convertit le format date SAP string ('YYYYMMDD' ou '00000000') en vraie DATE BigQuery
{% macro format_sap_date(champ) %} 
    CASE 
        WHEN {{ champ }} IS NULL OR TRIM(CAST({{ champ }} AS STRING)) IN ('00000000', '') THEN NULL 
        WHEN LENGTH(TRIM(CAST({{ champ }} AS STRING))) = 8 
             THEN SAFE.PARSE_DATE('%Y%m%d', TRIM(CAST({{ champ }} AS STRING))) 
        ELSE NULL 
    END 
{% endmacro %}