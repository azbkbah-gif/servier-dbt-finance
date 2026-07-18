-- Surcharge pour séparer dev (préfixé par le schéma de l'utilisateur) et prod (schéma fixe)
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    
    {# Cas 1 : Aucun schéma personnalisé n'est configuré sur le modèle #}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
        
    {# Cas 2 : On est en production -> On applique STRICTEMENT le nom personnalisé (ex: gold) #}
    {%- elif target.name == 'prod' or target.name == 'production' -%}
        {{ custom_schema_name | trim }}
        
    {# Cas 3 : On est en dév -> On préfixe avec le schéma utilisateur #}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}