# J3-02 : Déploiement

**Durée : 1h30** | **Jour 3, Matin**

## Objectifs
À la fin de ce module, vous saurez :
- [ ] Maîtriser les commandes dbt essentielles
- [ ] Utiliser les sélecteurs pour cibler des modèles
- [ ] Basculer entre environnements (dev/prod)
- [ ] Comprendre le workflow de déploiement

---

## Les commandes dbt essentielles

| Commande | Action |
|----------|--------|
| `dbt debug` | Vérifier la connexion |
| `dbt deps` | Installer les packages |
| `dbt run` | Exécuter les modèles |
| `dbt test` | Exécuter les tests |
| `dbt build` | run + test (tout en un) |
| `dbt compile` | Compiler sans exécuter |
| `dbt docs generate` | Générer la documentation |
| `dbt docs serve` | Visualiser la documentation |

---

## La commande dbt build

`dbt build` est la commande la plus utilisée en production.

```bash
dbt build
```

Elle exécute dans l'ordre :
1. Seeds (fichiers CSV)
2. Models (dans l'ordre du DAG)
3. Tests (après chaque modèle)

### Avantage
Si un modèle échoue, ses descendants ne sont pas exécutés → on ne propage pas les erreurs.

---

## Les sélecteurs

Les sélecteurs permettent de cibler des sous-ensembles de modèles.

### Syntaxe de base

| Syntaxe | Signification |
|---------|---------------|
| `--select model_name` | Un modèle spécifique |
| `--select +model_name` | Le modèle + ses ancêtres |
| `--select model_name+` | Le modèle + ses descendants |
| `--select +model_name+` | Ancêtres + modèle + descendants |

### Exemples

```bash
# Un seul modèle
dbt run --select stg_customers

# Un modèle et tout ce qui est en amont
dbt run --select +prod_sales_kpi

# Un modèle et tout ce qui est en aval
dbt run --select stg_sales+

# Tous les modèles d'un dossier
dbt run --select staging

# Tous les modèles avec un tag
dbt run --select tag:daily
```

### Sélecteurs avancés

```bash
# Exclure des modèles
dbt run --select staging --exclude stg_store

# Combiner
dbt run --select +prod_sales_kpi --exclude stg_store
```

---

## Les environnements

### Dev vs Prod

Le même code s'exécute dans des datasets différents.

```
Dev  : dbt_dev.stg_customers
Prod : dbt_prod.stg_customers
```

### Configuration dans profiles.yml

```yaml
aivancity_courses:
  target: dev  # Environnement par défaut
  outputs:
    dev:
      type: bigquery
      dataset: dbt_dev        # Dataset dev
      # ... autres configs

    prod:
      type: bigquery
      dataset: dbt_prod       # Dataset prod
      # ... autres configs
```

### Basculer d'environnement

```bash
# Développement (par défaut)
dbt run

# Production
dbt run --target prod
```

---

## Workflow de développement

### 1. Développer en local (dev)

```bash
# Créer/modifier un modèle
vim models/staging/stg_new_model.sql

# Tester
dbt run --select stg_new_model
dbt test --select stg_new_model

# Vérifier le pipeline complet
dbt build
```

### 2. Versionner

```bash
git add .
git commit -m "Add stg_new_model"
git push
```

### 3. Déployer en production

```bash
dbt build --target prod
```

---

## Le full-refresh

Pour les modèles incrémentaux, `--full-refresh` reconstruit la table complètement.

```bash
# Reconstruction complète
dbt run --select prod_sales_kpi --full-refresh
```

### Quand l'utiliser ?

- Changement de structure (ajout de colonne)
- Correction d'une erreur dans les données historiques
- Premier déploiement en prod

---

## Exercice pratique

### 1. Maîtriser les sélecteurs

Exécutez ces commandes et observez ce qui est exécuté :

```bash
# Lister les modèles qui seraient exécutés
dbt ls --select staging
dbt ls --select +prod_sales_kpi
dbt ls --select int_sales+

# Exécuter un sous-ensemble
dbt run --select staging
dbt run --select +int_sales
```

### 2. Tester le pipeline complet

```bash
# Build complet
dbt build

# Vérifier le résultat
# Combien de modèles ? Combien de tests ? Combien d'erreurs ?
```

### 3. Simuler un déploiement prod

```bash
# Vérifier la connexion prod
dbt debug --target prod

# Si configuré, déployer
dbt build --target prod
```

### 4. Tester full-refresh

```bash
# Comparer les temps d'exécution
time dbt run --select prod_sales_kpi
time dbt run --select prod_sales_kpi --full-refresh
```

---

## Bonnes pratiques de déploiement

### 1. Toujours tester avant de déployer
```bash
dbt build  # en dev d'abord
# Si tout passe :
dbt build --target prod
```

### 2. Utiliser git
```bash
git add .
git commit -m "Description claire"
git push
```

### 3. Documenter les changements
Dans votre commit, expliquez :
- Pourquoi ce changement
- Ce qui a été modifié
- Impact potentiel

### 4. Déploiement progressif
```bash
# D'abord un modèle
dbt run --select mon_nouveau_modele --target prod

# Puis tout le pipeline
dbt build --target prod
```

---

## Résumé des commandes clés

```bash
# Développement quotidien
dbt build                    # Tout construire et tester
dbt run --select model       # Un modèle spécifique
dbt test --select model      # Tester un modèle

# Sélecteurs
dbt run --select +model      # Avec ancêtres
dbt run --select model+      # Avec descendants
dbt run --select folder      # Tout un dossier

# Environnements
dbt build --target prod      # Déployer en prod
dbt run --full-refresh       # Reconstruire complètement

# Documentation
dbt docs generate && dbt docs serve
```

---

## Points clés

- `dbt build` = la commande principale (run + test)
- Les sélecteurs (`+`, `model+`, `folder`) ciblent précisément
- Dev et Prod = même code, datasets différents (`--target prod`)
- `--full-refresh` pour reconstruire les incrémentaux
- Toujours tester en dev avant de déployer en prod

---

## Prochaine étape
→ [J3-03 : Bonnes Pratiques](./J3-03-best-practices.md)
