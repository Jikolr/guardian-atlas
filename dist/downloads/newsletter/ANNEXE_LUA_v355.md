# Fichier retiré et scripts Lua ajoutés dans la comparaison 3.55

Cette annexe s'appuie sur les inventaires et les scripts déchiffrés de `outputs/20261002-144030-522b69/`. « Ajouté » signifie **présent dans la nouvelle capture et absent de l'ancienne au même chemin**. Cela ne suffit pas à dater l'apparition d'une fonctionnalité dans le jeu.

## Le seul fichier retiré

`apk/base/assets/bin/Data/8e70841960d6744b7b1a7f92fc12a4d4` est un petit asset Unity de **400 octets**. Son contenu identifiable est `UnityCloudBuildManifest.json`, avec notamment la branche Git, l'identifiant de commit, la date de début de compilation et la version d'Unity. L'ancien manifeste indique un début de compilation le **26 août 2026**. Dans le nouvel APK, `apk/base/assets/bin/Data/91ea1fa393f4c47f39710152b5020fd7` contient le même type de manifeste, également de 400 octets, pour une compilation commencée le **22 septembre 2026**. Les deux indiquent Unity `2022.3.62f2` et la branche `master-kakao-kr`.

**Rôle :** identifier la construction de l'application. Le changement de nom opaque correspond ici au renouvellement de cette ressource entre deux APK. Le diff ne montre aucune suppression de personnage, de niveau ou de script de jeu.

## Comment lire les 785 « nouveaux » chemins Lua

| Famille | Chemins ajoutés | Rôle visible dans le code |
| --- | ---: | --- |
| `stageeventcontrollers/` | 697 | Orchestration de niveaux, événements de terrain, énigmes, combats de boss, défis et scripts de Tour. |
| `utils/` | 69 | Fonctions partagées : musique de terrain, marqueurs de quêtes, démarrage de niveau, changement de membres, QTE, recherche de chemin, etc. |
| `worldexplore/` | 10 | Logique du mode d'exploration du monde et scripts de certaines étapes. |
| `Template/` | 6 | Modèles de code pour contrôleurs de quêtes, de niveaux et de mécanismes. |
| `Theatres/` | 2 | Séquences scénarisées et éléments d'interface de scènes. |
| `Test/` | 1 | Petit script de test interne. |

**Point essentiel :** 532 nouveaux fichiers de contrôleur correspondent exactement à une adresse déjà écrite dans un fichier Lua racine de l'ancienne capture. Ce fichier racine est toujours présent et inchangé dans la nouvelle capture. Par exemple, `GameScript/AfterWorld1At1.encrypted` contient seulement `controller = 'stageeventcontrollers/AfterWorld1At1.lua'`; le nouveau fichier de ce chemin contient **1 674 lignes** de logique de niveau. Le même schéma existe pour 523 scripts de `stageeventcontrollers/` et 9 de `worldexplore/`. Trois autres noms ont un fichier racine homonyme, avec une adresse différente ou une syntaxe légèrement différente. Les 250 autres chemins n'ont pas de fichier racine homonyme dans l'ancien inventaire.

Cette structure montre que la comparaison mesure en grande partie une différence de **couverture des scripts complets** entre les captures. Elle ne permet pas d'annoncer « 785 nouveaux contenus » ou « 697 nouveaux niveaux ».

## Exemples vérifiés de leur rôle

| Script | Ce qu'il fait d'après ses fonctions |
| --- | --- |
| `stageeventcontrollers/AfterWorld1At1` | Contrôleur de niveau : réagit aux chargements, débuts de niveau, entrées de zones et interactions ; gère plusieurs scènes et un minijeu. |
| `stageeventcontrollers/TowerBossEnemyCountController` | Suit le nombre d'ennemis pendant un combat de boss de la Tour et met à jour une interface de compteur. |
| `stageeventcontrollers/Blossom/Stage1` | Organise une étape de récit secondaire, notamment des portails, un cristal et une porte de combat. |
| `stageeventcontrollers/HellForest/AnimalTrapDoorOpener` | Surveille les dégâts et ouvre une porte lorsque sa condition est remplie. |
| `stageeventcontrollers/FireWorld/Wyvern/Substage` | Lance une sous-étape liée à `FireWorld/Wyvern`. Son nom ne prouve pas à lui seul qu'elle a été ajoutée dans cette version. |
| `worldexplore/WorldExploreController` | Gros contrôleur du mode d'exploration : phases, ressources (or, bois, pierre), unités, cases et interface. |
| `utils/FieldBGMManager/FieldBGMManager` | Change et précharge la musique de terrain selon les zones, le niveau et le début ou la fin d'un combat. |
| `utils/QuestMarker/QuestMarkerManager` | Ajoute, déplace et retire les marqueurs de quêtes sur le terrain. |
| `utils/StageStart/StageStartManager` | Choisit la logique de démarrage d'un niveau selon le code du chapitre. |
| `utils/QTEEvent` | Gère un événement d'action rapide via les entrées tactiles. |
| `Theatres/AfterWorldEvidence` | Affiche des indices et gère leur interface dans des sections scénarisées d'AfterWorld. |
| `Theatres/CarmenStreaming` | Anime une séquence de diffusion de Carmen : dialogue, public, dons et réactions. |
| `Template/GimmickTemplate` | Squelette de classe pour développer un mécanisme de niveau ; ce n'est pas un événement jouable en soi. |
| `Test/Test` | Lance une courte routine de test et écrit dans le journal. |

Les descriptions ci-dessus proviennent des noms de fonctions et des opérations visibles dans les Lua déchiffrés. Elles décrivent le **rôle du code**, sans démontrer quand il a été créé ou s'il est accessible aux joueurs dans la région considérée.
