# J1-01 : Introduction à dbt

**Durée : 1h** | **Jour 1, Matin**

## Objectifs
À la fin de ce module, vous saurez :
- [ ] Expliquer ce qu'est dbt et son rôle dans le Modern Data Stack
- [ ] Décrire l'architecture ELT vs ETL
- [ ] Identifier les avantages de dbt pour un data engineer

---

## Qu'est-ce que dbt ?

**dbt** (data build tool) est un outil de transformation de données qui permet d'appliquer les bonnes pratiques du développement logiciel à l'analytics.

### Le problème qu'il résout

Avant dbt :
```
Données brutes → Scripts SQL éparpillés → Pas de tests → Pas de documentation → Chaos
```

Avec dbt :
```
Données brutes → Modèles SQL versionnés → Tests automatisés → Documentation générée → Confiance
```

### Ce que dbt fait (et ne fait pas)

| dbt FAIT | dbt NE FAIT PAS |
|----------|-----------------|
| Transformer les données (le T de ELT) | Extraire les données |
| Orchestrer les dépendances | Charger les données |
| Tester les données | Visualiser les données |
| Documenter les modèles | Créer des dashboards |

---

## ELT vs ETL

### ETL (approche traditionnelle)
```
Extract → Transform → Load
         (serveur)
```
- Transformation AVANT le chargement
- Serveur de transformation dédié
- Coûteux et complexe

### ELT (approche moderne)
```
Extract → Load → Transform
                 (warehouse)
```
- Transformation DANS le warehouse
- Le warehouse fait le travail (BigQuery, Snowflake, etc.)
- Plus simple, plus scalable

**dbt = le "T" de ELT**, exécuté dans votre warehouse.

---

## Modern Data Stack

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Sources   │ →  │   Fivetran  │ →  │  BigQuery   │ →  │   Looker    │
│  (Shopify,  │    │  Airbyte    │    │  Snowflake  │    │   Metabase  │
│   API, DB)  │    │  (Extract   │    │  Redshift   │    │   (BI)      │
│             │    │   + Load)   │    │  (Warehouse)│    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                            ↑
                                       ┌────┴────┐
                                       │   dbt   │
                                       │(Transform)
                                       └─────────┘
```

---

## Pourquoi dbt ?

### 1. Modularité
```sql
-- Au lieu d'une requête de 500 lignes...
SELECT * FROM {{ ref('stg_customers') }}  -- On référence un autre modèle
```

### 2. Versionnement
```bash
git add .
git commit -m "Add customer LTV calculation"
git push
```
Votre SQL est versionné comme du code.

### 3. Tests automatisés
```yaml
models:
  - name: stg_customers
    columns:
      - name: customer_id
        tests:
          - unique
          - not_null
```

### 4. Documentation générée
```bash
dbt docs generate
dbt docs serve
```
Un site web de documentation généré automatiquement.

### 5. Dépendances automatiques
dbt comprend l'ordre d'exécution grâce au DAG (Directed Acyclic Graph).

```
stg_customers ─┐
               ├─→ int_sales ─→ prod_sales_kpi
stg_sales ─────┘
```

---

## Structure d'un projet dbt

```
mon_projet/
├── dbt_project.yml      # Configuration du projet
├── profiles.yml         # Connexion au warehouse (credentials)
├── models/              # Vos modèles SQL
│   ├── staging/         # Couche 1 : nettoyage
│   ├── intermediate/    # Couche 2 : logique métier
│   └── production/      # Couche 3 : tables finales
├── tests/               # Tests personnalisés
├── macros/              # Fonctions réutilisables
├── seeds/               # Fichiers CSV de référence
└── snapshots/           # Historisation (SCD Type 2)
```

---

## Les 3 couches de modèles

| Couche | Rôle | Exemple |
|--------|------|---------|
| **Staging** | Nettoyage, renommage, typage | `stg_customers`, `stg_sales` |
| **Intermediate** | Jointures, logique métier | `int_sales` (sales + customers + products) |
| **Production** | Agrégations pour la BI | `prod_sales_kpi` |

```
Sources (raw) → Staging → Intermediate → Production → BI
```

---

## Démonstration

Le formateur montre :
1. Un projet dbt existant
2. L'exécution de `dbt run`
3. Le DAG généré
4. La documentation

---

## Points clés

- dbt = transformation SQL avec les pratiques du software engineering
- ELT : on transforme DANS le warehouse, pas avant
- Modularité : on découpe en couches (staging → intermediate → production)
- Versionnement, tests, documentation = confiance dans les données

---

## Prochaine étape
→ [J1-02 : Setup & Sources](./J1-02-setup-sources.md)
