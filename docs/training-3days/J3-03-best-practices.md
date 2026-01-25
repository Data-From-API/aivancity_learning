# J3-03 : Bonnes Pratiques

**Durée : 1h** | **Jour 3, Après-midi**

## Objectifs
À la fin de ce module, vous saurez :
- [ ] Appliquer les conventions de nommage dbt
- [ ] Éviter les anti-patterns courants
- [ ] Réaliser une code review sur un modèle dbt

---

## Conventions de nommage

### Modèles

| Couche | Préfixe | Exemple |
|--------|---------|---------|
| Staging | `stg_` | `stg_customers`, `stg_sales` |
| Intermediate | `int_` | `int_sales`, `int_rfm_base` |
| Production | `prod_` ou `fct_`/`dim_` | `prod_sales_kpi` |

### Colonnes

| Type | Convention | Exemple |
|------|------------|---------|
| Identifiants | Suffixe `_id` | `customer_id`, `product_id` |
| Dates | Suffixe `_date` | `sale_date`, `signup_date` |
| Booléens | Préfixe `is_` ou `has_` | `is_loyalty_member`, `has_purchased` |
| Montants | Explicite | `revenue_billed`, `amount_ordered` |
| Compteurs | Préfixe `nb_` ou `total_` | `nb_transactions`, `total_products` |

### Fichiers

| Type | Emplacement |
|------|-------------|
| Modèles staging | `models/staging/stg_*.sql` |
| Modèles intermediate | `models/intermediate/int_*.sql` |
| Modèles production | `models/production/prod_*.sql` |
| Documentation | `models/<couche>/<couche>.yml` |

---

## Règles par couche

### Staging
- **1 source = 1 staging** (mapping 1:1)
- Utilise uniquement `source()`, jamais `ref()`
- Transformations légères : CAST, renommage, TRIM
- **Pas de jointures**

### Intermediate
- Jointures entre staging
- Logique métier
- Utilise `ref()` vers staging
- Matérialisation : `view` ou `ephemeral`

### Production
- Agrégations finales
- `ref()` vers intermediate (ou staging)
- Matérialisation : `table` ou `incremental`
- Tests exhaustifs

---

## Anti-patterns courants

### 1. Staging qui ref() un autre staging

```sql
-- ❌ MAUVAIS
-- Dans stg_sales_enriched.sql
select * from {{ ref('stg_sales') }}
```

**Problème :** Viole le mapping 1:1 source → staging

**Solution :** Déplacer en intermediate

### 2. Source hardcodée

```sql
-- ❌ MAUVAIS
select * from `projet.dataset.table`

-- ✅ BON
select * from {{ source('ma_source', 'table') }}
```

### 3. Pas de tests sur les clés

```yaml
# ❌ MAUVAIS : pas de tests
columns:
  - name: customer_id

# ✅ BON : clé primaire testée
columns:
  - name: customer_id
    tests:
      - unique
      - not_null
```

### 4. SELECT *

```sql
-- ❌ MAUVAIS
select * from {{ ref('stg_sales') }}

-- ✅ BON
select
    customer_id,
    product_id,
    sale_date,
    revenue_billed
from {{ ref('stg_sales') }}
```

### 5. INNER JOIN sans réflexion

```sql
-- ❌ Peut perdre des lignes silencieusement
from sales
inner join customers on ...

-- ✅ Explicite sur le comportement attendu
from sales
left join customers on ...
```

---

## Checklist de code review

### Structure
- [ ] Le modèle est dans la bonne couche
- [ ] Le nommage suit les conventions (`stg_`, `int_`, `prod_`)
- [ ] Le bloc config est présent et cohérent

### SQL
- [ ] Pas de SELECT *
- [ ] Les types sont castés correctement
- [ ] Les jointures sont LEFT (sauf raison explicite)
- [ ] Les CTEs ont des noms explicites

### Tests & Documentation
- [ ] La clé primaire a `unique` + `not_null`
- [ ] Les clés étrangères ont `relationships`
- [ ] Le modèle a une description
- [ ] Les colonnes importantes sont documentées

---

## Exercice : Code review

Prenez le modèle `int_sales` et appliquez la checklist :

```
Structure :
✅ Couche intermediate
✅ Préfixe int_
✅ Config block présent

SQL :
✅ Colonnes explicites
✅ CTEs nommées (sales, customers, products, stores)
✅ LEFT JOINs
⚠️ Vérifier les types castés

Tests :
✅ unique + not_null sur key_transaction_id
⚠️ Ajouter relationships sur customer_id ?

Documentation :
⚠️ Description du modèle présente ?
⚠️ Colonnes documentées ?
```

---

## Récapitulatif de la formation

### Ce que vous avez appris

| Jour | Concepts |
|------|----------|
| J1 | Architecture dbt, sources, staging, ref(), materializations |
| J2 | Intermediate, production, incremental, tests génériques |
| J3 | Documentation, déploiement, bonnes pratiques |

### Commandes essentielles

```bash
dbt debug          # Vérifier connexion
dbt deps           # Installer packages
dbt run            # Exécuter modèles
dbt test           # Exécuter tests
dbt build          # Tout en un
dbt docs generate  # Générer documentation
dbt docs serve     # Visualiser documentation
```

### Architecture à retenir

```
Sources → Staging → Intermediate → Production → BI
          source()     ref()          ref()
          table        view           table/incremental
          1:1          jointures      agrégations
```

---

## Pour aller plus loin

### Sujets non couverts (formation complète)

| Sujet | Description |
|-------|-------------|
| Macros | Fonctions Jinja réutilisables |
| Seeds | Fichiers CSV chargés comme tables |
| Snapshots | Historisation (SCD Type 2) |
| Packages | dbt_utils, codegen |
| CI/CD | GitHub Actions, dbt Cloud |
| Incrémental avancé | Partitioning, clustering |

### Ressources

- [Documentation officielle](https://docs.getdbt.com/)
- [dbt Learn](https://courses.getdbt.com/) - Cours gratuits
- [dbt Community Slack](https://community.getdbt.com/)
- [dbt Best Practices](https://docs.getdbt.com/best-practices)

---

## Projet autonome (1h45)

### Objectif
Créer un nouveau modèle de A à Z, sans aide.

### Consigne
Créez un modèle `prod_customer_summary` qui affiche, pour chaque client :
- `customer_id`
- `customer_fullname`
- `loyalty_level`
- `first_purchase_date`
- `last_purchase_date`
- `nb_purchases`
- `total_revenue`

### Étapes
1. Créer le modèle SQL
2. Ajouter les tests (unique, not_null)
3. Documenter dans le schema.yml
4. Exécuter `dbt build --select prod_customer_summary`
5. Vérifier dans BigQuery

### Critères de réussite
- [ ] Le modèle compile sans erreur
- [ ] Les tests passent
- [ ] La documentation est visible dans `dbt docs`
- [ ] Les données sont correctes

---

## Points clés à retenir

- Les conventions rendent le projet lisible par tous
- Chaque couche a des règles (sources en staging, jointures en intermediate)
- Les anti-patterns sont évitables avec une checklist
- La code review est essentielle en équipe
- dbt = pratiques du software engineering pour le data engineering

---

## Félicitations !

Vous avez maintenant les bases pour :
- Créer un projet dbt de zéro
- Construire un pipeline complet
- Tester et documenter vos modèles
- Déployer en production

**Prochaines étapes suggérées :**
1. Pratiquer sur un projet réel
2. Explorer les macros et packages
3. Mettre en place un CI/CD

Bonne continuation avec dbt !
