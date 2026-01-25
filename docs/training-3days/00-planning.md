# Formation dbt - 3 Jours

## Vue d'ensemble

Cette formation condense l'essentiel de dbt pour permettre à un développeur SQL confirmé d'être **autonome en 3 jours**.

### Public cible
- Développeur/Analyste SQL confirmé
- Jamais utilisé dbt
- Familier avec les concepts de data warehouse

### Objectif final
À la fin de la formation, l'apprenant sera capable de :
- Créer un projet dbt de A à Z
- Construire un pipeline staging → intermediate → production
- Tester et documenter ses modèles
- Déployer en production

---

## Planning Jour par Jour

### Jour 1 : Les Fondamentaux
**Objectif : Comprendre dbt et créer ses premiers modèles staging**

| Horaire | Module | Contenu | Durée |
|---------|--------|---------|-------|
| 09:00-09:30 | Accueil | Installation vérifiée, questions | 30 min |
| 09:30-10:30 | [J1-01 Introduction](./J1-01-introduction.md) | Qu'est-ce que dbt, architecture, Modern Data Stack | 1h |
| 10:30-10:45 | Pause | | 15 min |
| 10:45-12:15 | [J1-02 Setup & Sources](./J1-02-setup-sources.md) | Configuration, profiles.yml, source(), sources.yml | 1h30 |
| 12:15-13:30 | Déjeuner | | 1h15 |
| 13:30-15:30 | [J1-03 Modèles Staging](./J1-03-staging.md) | ref(), materializations, config block, premiers modèles | 2h |
| 15:30-15:45 | Pause | | 15 min |
| 15:45-17:00 | Pratique guidée | Créer stg_customers, stg_products, stg_sales, stg_store | 1h15 |
| 17:00-17:30 | Récap J1 | Questions, points bloquants, preview J2 | 30 min |

**Livrable J1 :** 4 modèles staging fonctionnels

---

### Jour 2 : Construire le Pipeline
**Objectif : Pipeline complet avec tests**

| Horaire | Module | Contenu | Durée |
|---------|--------|---------|-------|
| 09:00-09:15 | Récap J1 | Questions de la veille | 15 min |
| 09:15-10:45 | [J2-01 Intermediate](./J2-01-intermediate.md) | Jointures, logique métier, ephemeral, int_sales | 1h30 |
| 10:45-11:00 | Pause | | 15 min |
| 11:00-12:30 | [J2-02 Production](./J2-02-production.md) | Agrégations, incremental basique, prod_sales_kpi | 1h30 |
| 12:30-13:45 | Déjeuner | | 1h15 |
| 13:45-15:30 | [J2-03 Tests](./J2-03-tests.md) | Tests génériques, schema.yml, dbt test | 1h45 |
| 15:30-15:45 | Pause | | 15 min |
| 15:45-17:00 | Pratique guidée | Compléter le pipeline, ajouter les tests | 1h15 |
| 17:00-17:30 | Récap J2 | dbt build, résolution erreurs, preview J3 | 30 min |

**Livrable J2 :** Pipeline complet staging → intermediate → production avec tests

---

### Jour 3 : Industrialisation
**Objectif : Documenter, déployer, être autonome**

| Horaire | Module | Contenu | Durée |
|---------|--------|---------|-------|
| 09:00-09:15 | Récap J2 | Questions de la veille | 15 min |
| 09:15-10:30 | [J3-01 Documentation](./J3-01-documentation.md) | schema.yml, descriptions, dbt docs | 1h15 |
| 10:30-10:45 | Pause | | 15 min |
| 10:45-12:15 | [J3-02 Déploiement](./J3-02-deployment.md) | Commandes dbt, sélecteurs, environnements | 1h30 |
| 12:15-13:30 | Déjeuner | | 1h15 |
| 13:30-14:30 | [J3-03 Bonnes Pratiques](./J3-03-best-practices.md) | Conventions, anti-patterns, code review | 1h |
| 14:30-14:45 | Pause | | 15 min |
| 14:45-16:30 | Projet autonome | L'apprenant crée un nouveau modèle de A à Z | 1h45 |
| 16:30-17:30 | Clôture | Récap formation, ressources, Q&A final | 1h |

**Livrable J3 :** Projet documenté, déployable, + 1 modèle créé en autonomie

---

## Contenu simplifié vs Formation complète

| Sujet | 3 jours | Formation complète |
|-------|---------|-------------------|
| Introduction & Setup | Condensé (1 module) | 2 modules détaillés |
| Sources | Intégré au setup | Module dédié |
| Staging | Essentiel | Détaillé |
| Intermediate | Essentiel | Détaillé |
| Production | Basique (incremental simple) | Avancé (partitioning, clustering) |
| Tests | Génériques uniquement | Génériques + singuliers + dbt_utils |
| Documentation | Essentiel | Avancé (exposures, persist_docs) |
| Macros | Mentionné seulement | Module dédié |
| Seeds | Mentionné seulement | Module dédié |
| Snapshots | Non couvert | Module dédié |
| Incremental deep dive | Non couvert | Module dédié |
| Packages | Mentionné seulement | Module dédié |
| CI/CD | Overview | Détaillé |
| Selectors.yml | Non couvert | Couvert |

---

## Prérequis techniques

**Guide d'installation détaillé : [Prérequis Windows](./00-prerequis-windows.md)**

Avant le Jour 1, l'apprenant doit avoir :
- [ ] Python 3.11 installé
- [ ] Git installé
- [ ] VS Code installé
- [ ] Un compte Google Cloud avec accès BigQuery
- [ ] Le fichier credentials JSON téléchargé
- [ ] Le projet template cloné
- [ ] `dbt debug` qui affiche "All checks passed!"

---

## Structure du projet template

L'apprenant travaille sur le dossier `template/` qui contient :
```
template/
├── dbt_project.yml          # Pré-configuré
├── packages.yml             # dbt_utils déclaré
├── profiles.yml.example     # À copier et configurer
├── models/
│   ├── sources.yml          # Sources définies
│   ├── staging/             # À créer
│   ├── intermediate/        # À créer
│   └── production/          # À créer
└── ...
```

---

## Commandes essentielles (aide-mémoire)

```bash
dbt debug          # Vérifier la connexion
dbt deps           # Installer les packages
dbt run            # Exécuter les modèles
dbt test           # Exécuter les tests
dbt build          # Tout en un (run + test)
dbt docs generate  # Générer la documentation
dbt docs serve     # Visualiser la documentation
```

---

## Ressources

- [Documentation officielle dbt](https://docs.getdbt.com/)
- [dbt Learn (cours gratuits)](https://courses.getdbt.com/)
- [dbt Community Slack](https://community.getdbt.com/)
