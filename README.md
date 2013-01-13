## villes-france

## Régions, département, arrondissements, cantons et communes de France

Ce script permet d'obtenir une base de données des communes Françaises à partir des données de l'INSEE.

Sous réserve de quelques modifications simple, vous pourrez détourner sont usage pour importer dans une application existante

## Utilisation

### Prérequis

Pour utiliser ce script il vous faut :

* un serveur PostgreSQL,
* Ruby (1.9+),
* la gem Bundler

### Préparation

Avant de commencer, décompressez le fichier `./sources/insee/2012.tar.bz2` dans le répertoire `/sources/insee/`.
L'archive contient les fichiers CSV qui vont être nécessaire au remplissage de la base.

Ces fichiers sont issus du site de l'INSEE (voir les [sources](#sources)).
J'ai toutefois passé un coup d'`iconv` dessus, convertit les tabulations en virgules et supprimmé la dernière ligne du fichier des arrondissements.
Cette dernière ne me semblait pas très clean :

```
06,976,,,0,,,,

```

### Configuration

Configurer la base que vous souahitez utiliser de la manière suivante :

```
DB = Sequel.connect(adapter: 'postgres', host: 'localhost', database: 'my_database', user: 'my_user', password: 'my_password')
```

_Attention : Le script ne va pas créer la base si celle ci n'existe pas._


### Exécution

Pour remplir votre base de donnée, il faut simplement faire :

```
bundle install
bundle exec ruby ./script.rb
```

## Prochaines évolutions

* Ajouter les clés étrangères sur les tables
* Ajouter les codes postaux
* Ajouter les coordonnées GPS de chaque commune (WGS 84 décimal)
* Ajouter un point géographique (PostGIS)

## Sources

http://www.insee.fr/fr/methodes/nomenclatures/cog/telechargement.asp
http://www.insee.fr/fr/methodes/nomenclatures/cog/documentation.asp
