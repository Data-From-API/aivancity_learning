# J2-03 : Les Tests

**Durée : 1h45** | **Jour 2, Après-midi**

## Objectifs
À la fin de ce module, vous saurez :
- [ ] Comprendre pourquoi tester les données
- [ ] Utiliser les 4 tests génériques de dbt
- [ ] Configurer les tests dans schema.yml
- [ ] Exécuter et interpréter les tests

---

## Pourquoi tester les données ?

### Le problème

```
Données brutes → Transformations → Dashboard
                                      ↓
                              "Les chiffres sont faux !"
```

### La solution

```
Données brutes → Transformations → Tests → Dashboard
                                     ↓
                              "Test échoué : 5 customer_id sont NULL"
                              (On corrige AVANT que ça arrive au dashboard)
```

---

## Les 4 tests génériques de dbt

dbt fournit 4 tests "out of the box" :

| Test | Vérifie que... | Exemple |
|------|---------------|---------|
| `unique` | Pas de doublons | La clé primaire est unique |
| `not_null` | Pas de valeurs NULL | L'ID client n'est jamais vide |
| `accepted_values` | Valeurs dans une liste | Statut est 'completed', 'pending', ou 'refunded' |
| `relationships` | Clé étrangère valide | Chaque customer_id existe dans stg_customers |

---

## Configurer les tests dans schema.yml

Les tests se déclarent dans des fichiers `.yml` à côté des modèles.

### Exemple : models/staging/staging.yml

```yaml
version: 2

models:
  - name: stg_customers
    description: "Clients nettoyés et typés"
    columns:
      - name: customer_id
        description: "Clé primaire du client"
        tests:
          - unique
          - not_null

      - name: fullname
        description: "Nom complet du client"
        tests:
          - not_null

      - name: is_loyalty_member
        description: "Est membre fidélité"
        tests:
          - not_null

  - name: stg_products
    description: "Produits nettoyés"
    columns:
      - name: product_id
        tests:
          - unique
          - not_null

      - name: product_name
        tests:
          - not_null

  - name: stg_sales
    description: "Ventes nettoyées"
    columns:
      - name: key_transaction_id
        tests:
          - unique
          - not_null

      - name: customer_id
        tests:
          - not_null
          - relationships:
              to: ref('stg_customers')
              field: customer_id

      - name: product_id
        tests:
          - not_null
          - relationships:
              to: ref('stg_products')
              field: product_id

      - name: status
        tests:
          - accepted_values:
              values: ['completed', 'pending', 'refunded']

      - name: revenue_billed
        tests:
          - not_null

  - name: stg_store
    description: "Magasins nettoyés"
    columns:
      - name: store_id
        tests:
          - unique
          - not_null
```

---

## Exécuter les tests

### Tous les tests

```bash
dbt test
```

### Tests d'un modèle spécifique

```bash
dbt test --select stg_customers
```

### Tests après exécution

```bash
dbt build  # = dbt run + dbt test
```

---

## Interpréter les résultats

### Test réussi
```
PASS stg_customers.unique_customer_id
```

### Test échoué
```
FAIL stg_customers.unique_customer_id
  Got 3 results, expected 0
```

Signifie : 3 lignes ont des `customer_id` dupliqués.

### Voir les lignes en échec

```bash
dbt test --select stg_customers --store-failures
```

Les lignes en échec sont stockées dans une table temporaire que vous pouvez examiner.

---

## Le test relationships

Ce test vérifie l'intégrité référentielle (clés étrangères).

```yaml
- name: customer_id
  tests:
    - relationships:
        to: ref('stg_customers')
        field: customer_id
```

Vérifie que : chaque `customer_id` dans `stg_sales` existe dans `stg_customers`.

### Pourquoi c'est important ?

Si un `customer_id` n'existe pas dans la table clients, vos jointures produiront des NULL.

---

## Exercice pratique

### 1. Créer staging.yml

Créez `models/staging/staging.yml` avec les tests ci-dessus.

### 2. Exécuter les tests

```bash
dbt test --select staging
```

### 3. Analyser les résultats

- Combien de tests passent ?
- Y a-t-il des échecs ? Lesquels ?

### 4. Ajouter des tests sur intermediate

Créez `models/intermediate/intermediate.yml` :

```yaml
version: 2

models:
  - name: int_sales
    description: "Ventes enrichies avec clients, produits, magasins"
    columns:
      - name: key_transaction_id
        tests:
          - unique
          - not_null

      - name: customer_id
        tests:
          - not_null

      - name: sale_date
        tests:
          - not_null

      - name: revenue_billed
        tests:
          - not_null
```

### 5. Créer production.yml

Créez `models/production/production.yml` :

```yaml
version: 2

models:
  - name: prod_sales_kpi
    description: "KPIs de ventes agrégés"
    columns:
      - name: sale_date
        tests:
          - not_null

      - name: revenue_billed
        tests:
          - not_null

      - name: nb_transactions
        tests:
          - not_null
```

### 6. Exécuter tous les tests

```bash
dbt test
```

---

## Bonnes pratiques pour les tests

### 1. Toujours tester les clés primaires
```yaml
- name: customer_id
  tests:
    - unique
    - not_null
```

### 2. Tester les clés étrangères
```yaml
- name: customer_id
  tests:
    - relationships:
        to: ref('stg_customers')
        field: customer_id
```

### 3. Tester les colonnes critiques pour le métier
```yaml
- name: revenue_billed
  tests:
    - not_null
```

### 4. Utiliser accepted_values pour les énumérations
```yaml
- name: status
  tests:
    - accepted_values:
        values: ['completed', 'pending', 'refunded']
```

---

## dbt build : la commande unifiée

```bash
dbt build
```

Équivalent à :
1. `dbt seed` (charger les CSV)
2. `dbt run` (exécuter les modèles)
3. `dbt test` (exécuter les tests)

Les tests sont exécutés **après** chaque modèle, pas tous à la fin.

---

## Points clés

- Les tests garantissent la qualité des données
- 4 tests génériques : `unique`, `not_null`, `accepted_values`, `relationships`
- Configurer dans `schema.yml` (ou `staging.yml`, `production.yml`, etc.)
- `dbt test` exécute les tests
- `dbt build` = run + test en une commande
- Toujours tester les clés primaires (unique + not_null)

---

## Livrable Jour 2

À la fin de cette session, vous devez avoir :
- [ ] Pipeline complet : staging → intermediate → production
- [ ] Tests configurés sur tous les modèles
- [ ] `dbt build` sans erreur

---

## Prochaine étape
→ [J3-01 : Documentation](./J3-01-documentation.md)
