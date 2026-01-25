# J2-02 : Modèles Production

**Durée : 1h30** | **Jour 2, Matin**

## Objectifs
À la fin de ce module, vous saurez :
- [ ] Comprendre le rôle de la couche production
- [ ] Créer des agrégations pour la BI
- [ ] Comprendre les bases du mode incrémental
- [ ] Utiliser `GROUP BY ALL` (BigQuery)

---

## Le rôle de la production

La couche **production** (ou "marts") fait :
- Agrégations finales
- Métriques pour les dashboards
- Tables optimisées pour la BI

Elle ne fait PAS :
- Jointures complexes (c'est fait en intermediate)
- Nettoyage (c'est fait en staging)

### Règle
> Les modèles production utilisent `ref()` vers intermediate (ou staging si pas d'intermediate).

---

## Architecture finale

```
Sources → Staging → Intermediate → Production → BI
                                      ↑
                                  Vous êtes ici
```

---

## Créer un modèle production

### Exemple : prod_sales_kpi.sql

Ce modèle crée une table de KPIs agrégés par date, canal et catégorie.

```sql
{{
  config(
    materialized = 'table'
  )
}}

select
    -- Dimensions
    sale_date,
    store_channel,
    product_category,
    loyalty_level,

    -- Métriques
    sum(revenue_ordered) as revenue_ordered,
    sum(revenue_billed) as revenue_billed,
    count(distinct key_transaction_id) as nb_transactions,
    count(distinct customer_id) as nb_customers,
    count(distinct product_id) as nb_distinct_products_sold,
    sum(1) as total_products_sold

from {{ ref('int_sales') }}
where status = 'completed'  -- On ne compte que les ventes validées
group by all
```

### La syntaxe GROUP BY ALL

BigQuery permet `GROUP BY ALL` qui groupe automatiquement par toutes les colonnes non agrégées.

```sql
-- Équivalent à :
group by sale_date, store_channel, product_category, loyalty_level

-- Mais plus maintenable :
group by all
```

---

## Matérialisation : table vs incremental

### Table (simple)
```sql
{{ config(materialized = 'table') }}
```
- Recrée la table à chaque exécution
- Simple et fiable
- OK pour les petits/moyens volumes

### Incremental (avancé)
```sql
{{ config(materialized = 'incremental') }}
```
- N'ajoute que les nouvelles données
- Performant pour les gros volumes
- Plus complexe à configurer

---

## Introduction à l'incrémental

### Le concept

```
Premier run :        Runs suivants :
┌──────────────┐     ┌──────────────┐
│ Toutes les   │     │ Nouvelles    │
│ données      │     │ données      │
│ → CREATE     │     │ → MERGE      │
└──────────────┘     └──────────────┘
```

### Syntaxe de base

```sql
{{
  config(
    materialized = 'incremental',
    unique_key = 'ma_cle_primaire'
  )
}}

select ...
from {{ ref('source_model') }}

{% if is_incremental() %}
  where date_col > (select max(date_col) from {{ this }})
{% endif %}
```

### Les éléments clés

| Élément | Rôle |
|---------|------|
| `is_incremental()` | Vrai sauf au premier run |
| `{{ this }}` | Référence la table elle-même |
| `unique_key` | Clé pour le MERGE (évite les doublons) |

### Exemple concret

```sql
{{
  config(
    materialized = 'incremental',
    unique_key = ['sale_date', 'store_channel', 'product_category', 'loyalty_level']
  )
}}

select
    sale_date,
    store_channel,
    product_category,
    loyalty_level,
    sum(revenue_billed) as revenue_billed,
    count(*) as nb_transactions

from {{ ref('int_sales') }}
where status = 'completed'

{% if is_incremental() %}
  and sale_date >= (select max(sale_date) from {{ this }})
{% endif %}

group by all
```

### Forcer un rebuild complet

```bash
dbt run --select prod_sales_kpi --full-refresh
```

---

## Exercice pratique

### 1. Créer prod_sales_kpi.sql (version simple)

Créez `models/production/prod_sales_kpi.sql` :

```sql
{{
  config(
    materialized = 'table'
  )
}}

select
    sale_date,
    store_channel,
    product_category,
    loyalty_level,

    sum(revenue_ordered) as revenue_ordered,
    sum(revenue_billed) as revenue_billed,
    count(distinct key_transaction_id) as nb_transactions,
    count(distinct customer_id) as nb_customers,
    count(distinct product_id) as nb_distinct_products_sold,
    count(*) as total_products_sold

from {{ ref('int_sales') }}
where status = 'completed'
group by all
```

### 2. Exécuter le modèle

```bash
dbt run --select prod_sales_kpi
```

### 3. Vérifier dans BigQuery

```sql
SELECT
    sale_date,
    store_channel,
    sum(revenue_billed) as total_revenue
FROM `votre_projet.dbt_dev.prod_sales_kpi`
GROUP BY 1, 2
ORDER BY 1 DESC
LIMIT 10
```

### 4. Visualiser le pipeline complet

```bash
dbt docs generate
dbt docs serve
```

Naviguez dans le DAG pour voir le flux complet :
```
sources → staging → intermediate → production
```

---

## Le pipeline complet

À ce stade, votre DAG ressemble à :

```
dim_customers ─→ stg_customers ─┐
dim_products ──→ stg_products ──┼──→ int_sales ──→ prod_sales_kpi
dim_stores ────→ stg_store ─────┤
fact_sales ────→ stg_sales ─────┘
```

Pour tout exécuter dans l'ordre :

```bash
dbt run
```

dbt respecte automatiquement l'ordre des dépendances.

---

## Points clés

- Production = agrégations finales pour la BI
- `GROUP BY ALL` simplifie les requêtes d'agrégation
- `table` pour les petits volumes, `incremental` pour les gros
- L'incrémental utilise `is_incremental()` et `{{ this }}`
- `--full-refresh` force un rebuild complet
- `dbt run` exécute tout dans le bon ordre

---

## Prochaine étape
→ [J2-03 : Les Tests](./J2-03-tests.md)
