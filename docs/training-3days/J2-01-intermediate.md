# J2-01 : Modèles Intermediate

**Durée : 1h30** | **Jour 2, Matin**

## Objectifs
À la fin de ce module, vous saurez :
- [ ] Comprendre le rôle de la couche intermediate
- [ ] Joindre plusieurs modèles staging
- [ ] Appliquer de la logique métier
- [ ] Choisir entre `view` et `ephemeral`

---

## Rappel : L'architecture en couches

```
Sources (raw) → Staging → Intermediate → Production → BI
                            ↑
                         Vous êtes ici
```

---

## Le rôle de l'intermediate

La couche **intermediate** fait :
- Jointures entre modèles staging
- Logique métier (calculs, normalisation)
- Enrichissement des données

Elle ne fait PAS :
- Accès direct aux sources (utilise `ref()` vers staging)
- Agrégations finales (c'est le rôle de production)

### Règle
> Les modèles intermediate utilisent `ref()` vers staging, jamais `source()`.

---

## Créer un modèle intermediate

### Exemple : int_sales.sql

Ce modèle enrichit les ventes avec les informations clients, produits et magasins.

```sql
{{
  config(
    materialized = 'view'
  )
}}

with sales as (
    select * from {{ ref('stg_sales') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

stores as (
    select * from {{ ref('stg_store') }}
)

select
    -- Clé
    sales.key_transaction_id,

    -- Dates
    sales.sale_date,

    -- Client
    sales.customer_id,
    customers.fullname as customer_fullname,
    customers.gender as customer_gender,
    customers.is_loyalty_member as is_customer_loyal,
    customers.loyalty_level,
    customers.signup_date as customer_signup_date,

    -- Produit
    sales.product_id,
    products.product_name,
    products.category as product_category,
    products.brand as product_brand,

    -- Magasin
    sales.store_id,
    stores.store_name,
    stores.channel as store_channel,
    stores.city as store_city,
    stores.region as store_region,

    -- Métriques
    sales.revenue_ordered,
    sales.revenue_billed,
    sales.status,

    -- Calculs dérivés
    date_diff(sales.sale_date, customers.signup_date, day) as days_since_signup

from sales
left join customers on sales.customer_id = customers.customer_id
left join products on sales.product_id = products.product_id
left join stores on sales.store_id = stores.store_id
```

---

## Les CTEs (Common Table Expressions)

dbt encourage l'utilisation de CTEs pour la lisibilité :

```sql
with cte_1 as (
    select * from {{ ref('model_a') }}
),

cte_2 as (
    select * from {{ ref('model_b') }}
)

select ...
from cte_1
join cte_2 on ...
```

### Avantages des CTEs
- Code plus lisible
- Chaque étape a un nom explicite
- Facile à débugger

---

## LEFT JOIN : la règle

En analytics, on utilise presque toujours **LEFT JOIN** :

```sql
from sales
left join customers on sales.customer_id = customers.customer_id
```

Pourquoi ?
- On ne veut pas perdre de lignes de la table principale
- Si un client n'existe pas, on garde quand même la vente
- Les INNER JOIN peuvent cacher des problèmes de données

---

## Matérialisation : view vs ephemeral

| Matérialisation | Objet créé | Visible dans BigQuery | Quand l'utiliser |
|----------------|------------|----------------------|------------------|
| `view` | Vue SQL | Oui | Modèle utilisé par plusieurs autres |
| `ephemeral` | Rien (CTE inlinée) | Non | Modèle utilisé par un seul autre |

### Exemple ephemeral

```sql
{{
  config(
    materialized = 'ephemeral'
  )
}}

select ...
```

Le SQL est injecté comme CTE dans le modèle qui le référence. Aucun objet n'est créé dans BigQuery.

---

## Le DAG après intermediate

```
stg_customers ─────┐
stg_products ──────┼──→ int_sales ──→ (production)
stg_store ─────────┤
stg_sales ─────────┘
```

Les dépendances sont automatiquement comprises par dbt.

---

## Exercice pratique

### 1. Créer int_sales.sql

Créez `models/intermediate/int_sales.sql` avec le code ci-dessus.

### 2. Exécuter le modèle

```bash
dbt run --select int_sales
```

### 3. Vérifier les dépendances

```bash
dbt ls --select +int_sales
```

Cette commande liste `int_sales` ET tous ses ancêtres (les 4 staging).

### 4. Exécuter avec les dépendances

```bash
dbt run --select +int_sales
```

Le `+` avant le nom exécute d'abord les dépendances.

### 5. Vérifier dans BigQuery

Ouvrez la console BigQuery et exécutez :
```sql
SELECT * FROM `votre_projet.dbt_dev.int_sales` LIMIT 100
```

---

## Ajouter des calculs métier

### Exemple : Dates de première et dernière commande

```sql
-- Dans une CTE supplémentaire
customer_stats as (
    select
        customer_id,
        min(sale_date) as first_purchase_date,
        max(sale_date) as last_purchase_date
    from {{ ref('stg_sales') }}
    group by customer_id
)

-- Puis joindre
left join customer_stats on sales.customer_id = customer_stats.customer_id
```

---

## Points clés

- Intermediate = jointures + logique métier
- Utilise `ref()` vers staging, jamais `source()`
- CTEs pour la lisibilité
- LEFT JOIN pour ne pas perdre de données
- `view` si réutilisé, `ephemeral` si utilisé une seule fois
- `+model_name` exécute le modèle et ses dépendances

---

## Prochaine étape
→ [J2-02 : Modèles Production](./J2-02-production.md)
