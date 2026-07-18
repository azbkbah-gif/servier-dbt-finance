# ==============================================================================
# Dockerfile pour l'automatisation du pipeline dbt Servier Finance sur BigQuery
# ==============================================================================

# Utilisation d'une image Python légère et stable
FROM python:3.11-slim

# Définition du répertoire de travail dans le conteneur
WORKDIR /opt/servier-dbt-finance

# Installation des dépendances système minimales requises (ex: git pour dbt deps)
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Installation de dbt et de son adaptateur BigQuery
RUN pip install --no-cache-dir dbt-bigquery

# Copie de l'ensemble du projet dbt dans le conteneur
COPY . .

# Sécurité : On s'assure que le script shell a bien les droits d'exécution
RUN chmod +x scripts/run_production.sh

# Point d'entrée : Exécute le script d'automatisation au démarrage du conteneur
ENTRYPOINT ["./scripts/run_production.sh"]
