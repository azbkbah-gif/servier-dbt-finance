#!/bin/bash
# scripts/run_production.sh
set -e  # Arrêter si une commande échoue

# Charge ton environnement virtuel dbt (adapte le chemin si nécessaire)
source venv-dbt/bin/activate 

export DBT_PROFILES_DIR=/opt/secrets/dbt
export GOOGLE_APPLICATION_CREDENTIALS=/opt/secrets/sa-prod.json

echo '=== SERVIER FINANCE PIPELINE : Démarrage ==='
echo "Date : $(date)"

dbt source freshness --target prod
dbt seed              --target prod
dbt snapshot          --target prod
dbt build             --target prod

echo '=== Pipeline terminé avec succès ==='
