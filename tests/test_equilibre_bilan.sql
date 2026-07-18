{{ config(
    error_if = ">2"
) }}

SELECT
    code_societe,
    numero_document,
    exercice,
    SUM(montant_eur) AS desequilibre_eur
FROM {{ ref('sv_ecritures_comptables') }}
GROUP BY 1, 2, 3
HAVING ROUND(SUM(montant_eur), 2) != 0