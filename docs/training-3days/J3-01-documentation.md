# J3-01 : Documentation

**Durée : 1h15** | **Jour 3, Matin**

## Objectifs
À la fin de ce module, vous saurez :
- [ ] Documenter les modèles et colonnes dans schema.yml
- [ ] Générer et visualiser la documentation
- [ ] Naviguer dans le DAG

---

## Pourquoi documenter ?

### Sans documentation
```
"C'est quoi cette colonne loyalty_level ?"
"Je sais pas, demande à Jean-Pierre... ah il est parti."
```

### Avec documentation dbt
```
"C'est quoi cette colonne loyalty_level ?"
→ dbt docs serve → "Niveau de fidélité : Silver, Gold, ou Platinum"
```

---

## Où documenter ?

La documentation se fait dans les fichiers `.yml` que vous avez déjà créés pour les tests.

```yaml
version: 2

models:
  - name: stg_customers
    description: "Table clients nettoyée et enrichie"  # ← Documentation du modèle
    columns:
      - name: customer_id
        description: "Clé primaire unique du client"   # ← Documentation de colonne
        tests:
          - unique
          - not_null
```

---

## Documenter un modèle complet

### Exemple : models/staging/staging.yml

```yaml
version: 2

models:
  - name: stg_customers
    description: >
      Table des clients nettoyée à partir de dim_customers.
      Contient les informations démographiques et de fidélité.
      Un client = une ligne.
    columns:
      - name: customer_id
        description: "Identifiant unique du client (clé primaire)"
        tests:
          - unique
          - not_null

      - name: first_name
        description: "Prénom du client"
        tests:
          - not_null

      - name: last_name
        description: "Nom de famille du client"
        tests:
          - not_null

      - name: fullname
        description: "Nom complet (prénom + nom)"
        tests:
          - not_null

      - name: gender
        description: "Genre du client (male, female)"

      - name: is_loyalty_member
        description: "Booléen indiquant si le client est membre du programme fidélité"
        tests:
          - not_null

      - name: loyalty_level
        description: "Niveau de fidélité : Silver, Gold, ou Platinum (NULL si non membre)"

      - name: signup_date
        description: "Date d'inscription du client"
        tests:
          - not_null
```

### Description multi-ligne

Utilisez `>` pour les descriptions longues :

```yaml
description: >
  Première ligne de description.
  Deuxième ligne, continuation.
  Etc.
```

---

## Générer la documentation

### Étape 1 : Générer

```bash
dbt docs generate
```

Crée un fichier `target/manifest.json` et `target/catalog.json`.

### Étape 2 : Visualiser

```bash
dbt docs serve
```

Ouvre un navigateur avec :
- Liste de tous les modèles
- Descriptions
- Colonnes
- Tests
- **Le DAG interactif**

---

## Le DAG (Lineage Graph)

Le DAG montre les dépendances entre les modèles :

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Sources   │ →  │   Staging   │ →  │ Intermediate│ →  Production
└─────────────┘    └─────────────┘    └─────────────┘
```

### Navigation dans le DAG

- Cliquez sur un modèle pour voir ses détails
- Voyez les ancêtres (upstream) et descendants (downstream)
- Identifiez les dépendances

---

## Exercice pratique

### 1. Compléter la documentation staging

Mettez à jour `models/staging/staging.yml` pour documenter toutes les colonnes de tous les modèles staging.

### 2. Documenter intermediate

Mettez à jour `models/intermediate/intermediate.yml` :

```yaml
version: 2

models:
  - name: int_sales
    description: >
      Ventes enrichies avec les informations clients, produits et magasins.
      Chaque ligne représente une transaction de vente.
      C'est le modèle central pour les analyses.
    columns:
      - name: key_transaction_id
        description: "Clé primaire de la transaction"
        tests:
          - unique
          - not_null

      - name: sale_date
        description: "Date de la vente"
        tests:
          - not_null

      - name: customer_id
        description: "ID du client"
        tests:
          - not_null

      - name: customer_fullname
        description: "Nom complet du client"

      - name: is_customer_loyal
        description: "Le client est-il membre fidélité ?"

      - name: loyalty_level
        description: "Niveau fidélité (Silver/Gold/Platinum)"

      - name: product_id
        description: "ID du produit"

      - name: product_name
        description: "Nom du produit"

      - name: product_category
        description: "Catégorie du produit"

      - name: store_channel
        description: "Canal de vente (boutique, ecommerce, click_collect)"

      - name: revenue_billed
        description: "Montant facturé en euros"
        tests:
          - not_null

      - name: status
        description: "Statut de la commande (completed, pending, refunded)"
```

### 3. Documenter production

Mettez à jour `models/production/production.yml` :

```yaml
version: 2

models:
  - name: prod_sales_kpi
    description: >
      Table de KPIs agrégés par date, canal, catégorie et niveau fidélité.
      Utilisée pour les dashboards de suivi des ventes.
    columns:
      - name: sale_date
        description: "Date de la vente"
        tests:
          - not_null

      - name: store_channel
        description: "Canal de vente"

      - name: product_category
        description: "Catégorie produit"

      - name: loyalty_level
        description: "Niveau fidélité client"

      - name: revenue_ordered
        description: "CA commandé (peut inclure annulations)"

      - name: revenue_billed
        description: "CA facturé (ventes effectives)"
        tests:
          - not_null

      - name: nb_transactions
        description: "Nombre de transactions distinctes"
        tests:
          - not_null

      - name: nb_customers
        description: "Nombre de clients distincts"

      - name: nb_distinct_products_sold
        description: "Nombre de produits différents vendus"

      - name: total_products_sold
        description: "Nombre total de lignes produit"
```

### 4. Générer et visualiser

```bash
dbt docs generate
dbt docs serve
```

### 5. Explorer le DAG

- Naviguez jusqu'à `prod_sales_kpi`
- Affichez le lineage complet
- Vérifiez que la documentation apparaît

---

## Bonnes pratiques

### 1. Documenter au minimum
- Description de chaque modèle
- Description des colonnes clés (surtout métriques et dimensions principales)
- Description des clés primaires et étrangères

### 2. Être précis
```yaml
# ❌ Trop vague
description: "Le chiffre d'affaires"

# ✅ Précis
description: "Chiffre d'affaires facturé en euros, après remises et annulations"
```

### 3. Documenter au fil de l'eau
Ne pas attendre la fin du projet. Documenter en même temps que vous créez le modèle.

---

## Points clés

- Documentation dans les fichiers `.yml` (même fichier que les tests)
- `dbt docs generate` crée la documentation
- `dbt docs serve` la visualise
- Le DAG montre le lineage des données
- Documenter les modèles ET les colonnes importantes

---

## Prochaine étape
→ [J3-02 : Déploiement](./J3-02-deployment.md)
