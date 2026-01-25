# J1-02 : Setup & Sources

**Durée : 1h30** | **Jour 1, Matin**

## Objectifs
À la fin de ce module, vous saurez :
- [ ] Configurer un projet dbt avec BigQuery
- [ ] Comprendre `dbt_project.yml` et `profiles.yml`
- [ ] Déclarer des sources dans `sources.yml`
- [ ] Utiliser `source()` dans vos modèles

---

## Partie 1 : Configuration (30 min)

### Étape 1 : Cloner le template

```bash
# Cloner le projet template
git clone <url_du_repo> mon_projet
cd mon_projet
```

### Étape 2 : Créer l'environnement Python

```bash
# Créer un environnement virtuel
python -m venv .venv

# Activer (Mac/Linux)
source .venv/bin/activate

# Activer (Windows PowerShell)
.\.venv\Scripts\Activate.ps1

# Installer dbt
pip install dbt-bigquery
```

**Note Windows :** Si erreur de politique d'exécution, exécuter d'abord :
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Étape 3 : Configurer profiles.yml

Copiez le fichier exemple :
```bash
# Mac/Linux
cp profiles.yml.example profiles.yml

# Windows (PowerShell)
copy profiles.yml.example profiles.yml
```

Éditez `profiles.yml` :
```yaml
aivancity_courses:              # Nom du profil (doit matcher dbt_project.yml)
  target: dev                   # Environnement par défaut
  outputs:
    dev:                        # Configuration développement
      type: bigquery
      method: service-account
      project: votre-projet-gcp # Votre projet GCP
      dataset: dbt_dev          # Dataset de destination
      location: EU              # Région
      keyfile: /chemin/vers/credentials.json  # Voir note ci-dessous
      threads: 4
```

**Chemin du keyfile :**
- Mac/Linux : `/Users/votre_nom/.gcp/credentials.json`
- Windows : `C:/Users/votre_nom/.gcp/credentials.json` (utiliser `/` pas `\`)

**Important :** Le fichier `profiles.yml` contient des credentials. Ne JAMAIS le committer !

### Étape 4 : Vérifier la connexion

```bash
dbt debug
```

Résultat attendu :
```
All checks passed!
```

### Étape 5 : Installer les packages

```bash
dbt deps
```

---

## Partie 2 : Le fichier dbt_project.yml (15 min)

C'est le fichier de configuration principal de votre projet.

```yaml
name: 'aivancity_courses'      # Nom du projet
version: '1.0.0'

profile: 'aivancity_courses'   # Doit matcher profiles.yml

model-paths: ["models"]        # Où sont les modèles
test-paths: ["tests"]          # Où sont les tests
seed-paths: ["seeds"]          # Où sont les CSV
macro-paths: ["macros"]        # Où sont les macros
snapshot-paths: ["snapshots"]  # Où sont les snapshots

clean-targets:
  - "target"
  - "dbt_packages"
```

### Lien profile ↔ dbt_project.yml

```
dbt_project.yml                     profiles.yml
┌──────────────────┐                ┌──────────────────┐
│ profile: 'xxx'   │ ──── doit ──→ │ xxx:             │
└──────────────────┘    matcher     │   target: dev    │
                                    │   outputs: ...   │
                                    └──────────────────┘
```

---

## Partie 3 : Les Sources (45 min)

### Qu'est-ce qu'une source ?

Une **source** est une table brute (raw) qui existe déjà dans votre warehouse. dbt ne la crée pas, il la référence.

```
Tables brutes (créées par Fivetran, Airbyte, etc.)
        ↓
    Sources dbt (référencées)
        ↓
    Modèles staging (créés par dbt)
```

### Pourquoi déclarer les sources ?

1. **Abstraction** : Si la table brute change de nom, on modifie un seul endroit
2. **Documentation** : On documente les tables sources
3. **Lineage** : Le DAG montre d'où viennent les données
4. **Freshness** : On peut tester si les données sont à jour

### Le fichier sources.yml

Créez `models/sources.yml` :

```yaml
version: 2

sources:
  - name: sources_tables        # Nom logique de la source
    description: "Tables brutes du projet"
    tables:
      - name: fact_sales        # Nom de la table dans BigQuery
        description: "Transactions de ventes"
        columns:
          - name: sale_date
            description: "Date de la vente"
          - name: customer_id
            description: "ID du client"
          - name: billed_amount
            description: "Montant facturé"

      - name: dim_customers
        description: "Dimension clients"
        columns:
          - name: customer_id
            description: "Clé primaire client"
          - name: first_name
            description: "Prénom"

      - name: dim_products
        description: "Dimension produits"
        columns:
          - name: product_id
            description: "Clé primaire produit"

      - name: dim_stores
        description: "Dimension magasins"
        columns:
          - name: store_id
            description: "Clé primaire magasin"
```

### Utiliser source() dans un modèle

```sql
-- models/staging/stg_customers.sql
select
    customer_id,
    first_name,
    last_name
from {{ source('sources_tables', 'dim_customers') }}
--         ↑ nom de la source    ↑ nom de la table
```

### Syntaxe source()

```sql
{{ source('nom_source', 'nom_table') }}
```

Cela génère :
```sql
`projet.dataset.dim_customers`
```

---

## Exercice pratique

### 1. Vérifiez votre connexion
```bash
dbt debug
```

### 2. Examinez le fichier sources.yml fourni
Ouvrez `models/sources.yml` et identifiez :
- Combien de sources sont déclarées ?
- Quelles sont les colonnes documentées ?

### 3. Créez un modèle de test
Créez `models/staging/test_source.sql` :
```sql
select *
from {{ source('sources_tables', 'dim_customers') }}
limit 10
```

### 4. Exécutez le modèle
```bash
dbt run --select test_source
```

### 5. Vérifiez dans BigQuery
Allez dans la console BigQuery et vérifiez que la vue `test_source` a été créée.

### 6. Supprimez le modèle de test
```bash
rm models/staging/test_source.sql
```

---

## Points clés

- `profiles.yml` = connexion au warehouse (credentials, NE PAS committer)
- `dbt_project.yml` = configuration du projet (versionné)
- Le `profile` doit matcher entre les deux fichiers
- `sources.yml` = déclaration des tables brutes
- `source('nom', 'table')` = référencer une source dans un modèle
- `dbt debug` = vérifier que tout est configuré

---

## Prochaine étape
→ [J1-03 : Modèles Staging](./J1-03-staging.md)
