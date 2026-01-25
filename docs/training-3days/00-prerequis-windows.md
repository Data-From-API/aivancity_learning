# Prérequis - Installation Windows

Ce guide doit être suivi **AVANT le Jour 1** de la formation.

---

## 1. Installer Python

### Option A : Microsoft Store (recommandé)
1. Ouvrir le Microsoft Store
2. Chercher "Python 3.11"
3. Cliquer "Installer"
4. Vérifier dans PowerShell :
```powershell
python --version
# Doit afficher : Python 3.11.x
```

### Option B : python.org
1. Aller sur https://www.python.org/downloads/
2. Télécharger Python 3.11.x (pas 3.12, compatibilité dbt)
3. **IMPORTANT** : Cocher "Add Python to PATH" pendant l'installation
4. Terminer l'installation
5. Vérifier :
```powershell
python --version
```

---

## 2. Installer Git

1. Télécharger Git : https://git-scm.com/download/win
2. Installer avec les options par défaut
3. Vérifier :
```powershell
git --version
# Doit afficher : git version 2.x.x
```

---

## 3. Installer VS Code

1. Télécharger : https://code.visualstudio.com/
2. Installer
3. Extensions recommandées :
   - "Python" (Microsoft)
   - "dbt Power User" (optionnel mais utile)

---

## 4. Configurer Google Cloud

### 4.1 Créer un compte GCP
Si vous n'avez pas de compte :
1. Aller sur https://console.cloud.google.com/
2. Créer un compte (carte bancaire requise mais $300 de crédit gratuit)

### 4.2 Créer un projet
1. Dans la console GCP, cliquer "Créer un projet"
2. Nom : `dbt-training` (ou autre)
3. Noter l'ID du projet

### 4.3 Activer BigQuery
1. Dans le menu, aller dans "BigQuery"
2. L'API s'active automatiquement

### 4.4 Créer un Service Account
1. Menu → IAM et administration → Comptes de service
2. "Créer un compte de service"
3. Nom : `dbt-service-account`
4. Rôle : "BigQuery Admin"
5. Cliquer "OK"

### 4.5 Télécharger les credentials
1. Cliquer sur le compte de service créé
2. Onglet "Clés"
3. "Ajouter une clé" → "Créer une clé" → JSON
4. Le fichier se télécharge automatiquement
5. **Renommer** en `credentials.json`
6. **Déplacer** dans un dossier sécurisé, par exemple :
   ```
   C:\Users\VotreNom\.gcp\credentials.json
   ```

**IMPORTANT :** Ne JAMAIS committer ce fichier !

---

## 5. Cloner le projet template

Ouvrir PowerShell et exécuter :

```powershell
# Aller dans votre dossier de travail
cd C:\Users\VotreNom\Documents

# Cloner le template
git clone https://github.com/VOTRE_COMPTE/dbt-training-template.git

# Entrer dans le dossier
cd dbt-training-template
```

---

## 6. Créer l'environnement Python

```powershell
# Créer un environnement virtuel
python -m venv .venv

# Activer l'environnement (PowerShell)
.\.venv\Scripts\Activate.ps1

# Si erreur de politique d'exécution, exécuter d'abord :
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Installer dbt-bigquery
pip install dbt-bigquery
```

Vérifier l'installation :
```powershell
dbt --version
```

Résultat attendu :
```
Core:
  - installed: 1.x.x

Plugins:
  - bigquery: 1.x.x
```

---

## 7. Configurer profiles.yml

### 7.1 Créer le dossier .dbt
```powershell
mkdir $HOME\.dbt
```

### 7.2 Créer profiles.yml
Créer le fichier `C:\Users\VotreNom\.dbt\profiles.yml` avec ce contenu :

```yaml
aivancity_courses:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: VOTRE_PROJET_GCP       # Remplacer
      dataset: dbt_dev
      location: EU
      keyfile: C:/Users/VotreNom/.gcp/credentials.json  # Chemin vers vos credentials
      threads: 4
```

**Note :** Utiliser des `/` (pas des `\`) dans le chemin du keyfile.

---

## 8. Vérifier la connexion

```powershell
# S'assurer d'être dans le dossier du projet
cd C:\Users\VotreNom\Documents\dbt-training-template

# Activer l'environnement (si pas déjà fait)
.\.venv\Scripts\Activate.ps1

# Tester la connexion
dbt debug
```

Résultat attendu :
```
All checks passed!
```

---

## 9. Installer les packages dbt

```powershell
dbt deps
```

---

## Checklist finale

Avant le Jour 1, vérifiez que :

- [ ] `python --version` fonctionne
- [ ] `git --version` fonctionne
- [ ] VS Code est installé
- [ ] Le projet est cloné
- [ ] L'environnement virtuel est créé (`.venv`)
- [ ] `dbt --version` fonctionne (dans l'environnement activé)
- [ ] `dbt debug` affiche "All checks passed!"
- [ ] `dbt deps` s'exécute sans erreur

---

## Problèmes courants

### "python n'est pas reconnu"
→ Python n'est pas dans le PATH. Réinstaller en cochant "Add to PATH".

### "dbt n'est pas reconnu"
→ L'environnement virtuel n'est pas activé. Exécuter :
```powershell
.\.venv\Scripts\Activate.ps1
```

### Erreur de politique d'exécution PowerShell
→ Exécuter :
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Could not connect to BigQuery"
→ Vérifier :
1. Le chemin du `keyfile` dans profiles.yml (utiliser `/` pas `\`)
2. Le fichier credentials.json existe
3. Le projet GCP est correct
4. Le service account a les droits BigQuery Admin

### "Profile not found"
→ Vérifier que le nom du profile dans `dbt_project.yml` correspond à celui dans `profiles.yml`.

---

## Support

Si vous êtes bloqué, contactez le formateur avec :
1. La commande exécutée
2. Le message d'erreur complet
3. Une capture d'écran si possible
