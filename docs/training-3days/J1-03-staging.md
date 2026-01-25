# J1-03 : Modèles Staging

**Durée : 2h** | **Jour 1, Après-midi**

## Objectifs
À la fin de ce module, vous saurez :
- [ ] Créer un modèle staging
- [ ] Utiliser `ref()` pour référencer d'autres modèles
- [ ] Comprendre les matérialisations (view, table)
- [ ] Configurer un modèle avec le bloc `config`

---

## Le rôle du staging

La couche **staging** est la première transformation. Elle fait :
- Renommage des colonnes
- Typage (CAST)
- Nettoyage de base (TRIM, LOWER, etc.)
- Dédoublonnage si nécessaire

Elle ne fait PAS :
- Jointures entre tables
- Logique métier complexe
- Agrégations

### Règle d'or
> **1 source = 1 modèle staging**

```
dim_customers (source) → stg_customers (staging)
dim_products (source)  → stg_products (staging)
fact_sales (source)    → stg_sales (staging)
```

---

## Créer un modèle staging

### Exemple : stg_customers.sql

Créez `models/staging/stg_customers.sql` :

```sql
select
    -- Clé primaire
    customer_id,

    -- Colonnes texte
    first_name,
    last_name,
    concat(first_name, ' ', last_name) as fullname,

    -- Colonnes booléennes
    is_loyalty_member,

    -- Colonnes catégorielles
    loyalty_level,
    gender,

    -- Colonnes date
    date(signup_date) as signup_date

from {{ source('sources_tables', 'dim_customers') }}
```

### Exécuter le modèle

```bash
dbt run --select stg_customers
```

Par défaut, dbt crée une **vue** dans BigQuery.

---

## Les matérialisations

Une **matérialisation** définit comment dbt crée l'objet dans le warehouse.

| Matérialisation | Objet créé | Quand l'utiliser |
|----------------|------------|------------------|
| `view` | Vue SQL | Données légères, toujours à jour |
| `table` | Table physique | Requêtes lentes, données stables |
| `ephemeral` | Rien (CTE) | Modèle intermédiaire non exposé |
| `incremental` | Table avec MERGE | Gros volumes, append-only |

### Configurer la matérialisation

**Option 1 : Dans le modèle** (bloc config)
```sql
{{ config(materialized='table') }}

select ...
```

**Option 2 : Dans dbt_project.yml** (pour tout un dossier)
```yaml
models:
  mon_projet:
    staging:
      +materialized: table
```

---

## Le bloc config

Le bloc `config` permet de configurer un modèle individuellement.

```sql
{{
  config(
    materialized = 'table',
    tags = ['daily']
  )
}}

select ...
```

### Options courantes

| Option | Description | Exemple |
|--------|-------------|---------|
| `materialized` | Type de matérialisation | `'table'`, `'view'` |
| `tags` | Tags pour filtrer | `['daily', 'critical']` |
| `schema` | Schema de destination | `'staging'` |
| `alias` | Nom de la table | `'customers'` |

---

## La fonction ref()

`ref()` permet de référencer un autre modèle dbt.

```sql
-- Dans int_sales.sql
select *
from {{ ref('stg_customers') }}  -- Référence le modèle stg_customers
```

### Pourquoi utiliser ref() ?

1. **Dépendances** : dbt comprend l'ordre d'exécution
2. **Environnement** : Le schema correct est utilisé automatiquement
3. **Refactoring** : Si on renomme un modèle, ref() suit

### ref() vs source()

| Fonction | Référence | Exemple |
|----------|-----------|---------|
| `source()` | Table brute externe | `{{ source('raw', 'customers') }}` |
| `ref()` | Modèle dbt | `{{ ref('stg_customers') }}` |

**Règle :**
- Staging → utilise `source()`
- Intermediate/Production → utilise `ref()`

---

## Exercice pratique : Créer les 4 modèles staging

### 1. stg_customers.sql

```sql
{{
  config(
    materialized = 'table'
  )
}}

select
    customer_id,
    first_name,
    last_name,
    concat(first_name, ' ', last_name) as fullname,
    gender,
    is_loyalty_member,
    loyalty_level,
    date(signup_date) as signup_date

from {{ source('sources_tables', 'dim_customers') }}
```

### 2. stg_products.sql

```sql
{{
  config(
    materialized = 'table'
  )
}}

select
    product_id,
    product_name,
    brand,
    category,
    subcategory

from {{ source('sources_tables', 'dim_products') }}
```

### 3. stg_store.sql

```sql
{{
  config(
    materialized = 'table'
  )
}}

select
    store_id,
    store_name,
    channel,
    city,
    region

from {{ source('sources_tables', 'dim_stores') }}
```

### 4. stg_sales.sql

```sql
{{
  config(
    materialized = 'table'
  )
}}

select
    -- Clé primaire composée
    concat(
        cast(sale_date as string), '_',
        cast(customer_id as string), '_',
        cast(product_id as string), '_',
        cast(store_id as string)
    ) as key_transaction_id,

    -- Dimensions
    cast(sale_date as date) as sale_date,
    customer_id,
    product_id,
    store_id,

    -- Métriques
    cast(ordered_amount as float64) as revenue_ordered,
    cast(billed_amount as float64) as revenue_billed,

    -- Statut
    status

from {{ source('sources_tables', 'fact_sales') }}
```

### 5. Exécuter tous les modèles staging

```bash
dbt run --select staging
```

### 6. Vérifier dans BigQuery

Ouvrez la console BigQuery et vérifiez que les 4 tables ont été créées dans votre dataset.

---

## Le DAG (Directed Acyclic Graph)

Après avoir créé vos modèles, dbt comprend les dépendances :

```
dim_customers (source) ──→ stg_customers
dim_products (source)  ──→ stg_products
dim_stores (source)    ──→ stg_store
fact_sales (source)    ──→ stg_sales
```

Pour visualiser :
```bash
dbt docs generate
dbt docs serve
```

---

## Conventions de nommage

| Élément | Convention | Exemple |
|---------|------------|---------|
| Modèles staging | Préfixe `stg_` | `stg_customers` |
| Clés primaires | Suffixe `_id` | `customer_id` |
| Dates | Suffixe `_date` | `sale_date` |
| Booléens | Préfixe `is_` ou `has_` | `is_loyalty_member` |

---

## Points clés

- Staging = nettoyage, renommage, typage (1 source = 1 staging)
- `source()` pour les tables brutes, `ref()` pour les modèles dbt
- Matérialisation : `view` (léger) ou `table` (performance)
- Le bloc `config` configure un modèle individuellement
- `dbt run --select staging` exécute tous les modèles du dossier

---

## Livrable Jour 1

À la fin de cette session, vous devez avoir :
- [ ] 4 modèles staging fonctionnels
- [ ] `dbt run --select staging` sans erreur
- [ ] Tables visibles dans BigQuery

---

## Prochaine étape
→ [J2-01 : Modèles Intermediate](./J2-01-intermediate.md)
