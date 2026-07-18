{% snapshot snap_fournisseurs %} 
{{ 
    config( 
        target_schema = 'snapshots', 
        unique_key = 'code_fournisseur', 
        strategy = 'check', 
        check_cols = ['raison_sociale', 'pays', 'groupe_comptes'] 
    ) 
}} 
 
SELECT 
    code_fournisseur, 
    raison_sociale, 
    pays, 
    groupe_comptes 
FROM {{ ref('bz_sap_lfa1') }} 
{% endsnapshot %} 
# dbt ajoute automatiquement : 
#   
dbt_scd_id, dbt_updated_at, dbt_valid_from, dbt_valid_to 
# Lancer le snapshot : 
dbt snapshot