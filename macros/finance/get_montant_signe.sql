-- Convertit le couple (montant absolu, sens S/H) en montant signé pour SAP
{% macro get_montant_signe(champ_montant, champ_sens) %} 
    CASE 
        WHEN {{ champ_sens }} = 'S' THEN {{ champ_montant }}       -- Débit (+)
        WHEN {{ champ_sens }} = 'H' THEN -1 * {{ champ_montant }}  -- Crédit (-)
        ELSE 0 
    END 
{% endmacro %}