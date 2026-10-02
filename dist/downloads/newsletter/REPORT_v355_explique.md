# Comparaison Guardian Tales : lecture des changements

Source : `REPORT_v355.md`, généré le 2 octobre 2026, et les fichiers détaillés de la même exécution (`outputs/20261002-144030-522b69/`). Les noms internes des contenus ne prouvent pas à eux seuls leur disponibilité immédiate dans le jeu.

## Résumé

Le changement le plus net est l'ajout des données d'un personnage nommé en interne `wyverns_purple`, avec ses formes évoluées et mythique, armes, projectiles, compétences, éveil, illustrations et effets. La capture contient aussi des configurations de nouveaux événements (croissance du héros, machine gacha géante, pass, raid de guilde) et des visuels de packs « 5anni ».

Un ajustement chiffré ressort : la valeur `ScarecrowTotalDmg` augmente d'environ **22 %** pour les niveaux 0 à 150, dans les deux tables `LevelExps` et `LevelExps.Kong`. Les données consultées ne révèlent pas comment le jeu exploite exactement ce champ ; ce n'est pas une preuve que les dégâts infligés par tous les personnages augmentent de 22 %.

Le total brut est de 114 fichiers modifiés, 867 ajoutés, 1 supprimé et 17 016 inchangés. Ces totaux mélangent contenu de jeu, fichiers techniques et différences dues à la composition des captures. Ils ne doivent pas être lus comme 867 nouveautés de jeu.

## Changements de jeu identifiables

| Sujet | Ce que montrent les données | Portée |
| --- | --- | --- |
| Personnage `wyverns_purple` | Quatre entrées de héros ajoutées (ID 701, 702, 703 et 20701), dont une forme `myth`. Une arme épique et une arme mythique, des pierres d'évolution, un costume, des collections, des arbres d'éveil et des ressources visuelles sont également ajoutés. | Ajout cohérent d'un personnage complet. Le nom destiné aux joueurs est à confirmer par les textes ou l'interface. |
| Combat de ce personnage | Nouvelles actions de soutien, d'endurance et mythiques, six projectiles, des options et des buffs. L'action de soutien mythique décrit une connexion aérienne, un rayon de 2 et un soin (`HealRatio`) de 0,2. | Données de capacités présentes ; leur effet réel demande une validation en jeu ou du code concerné. |
| `BridgeMessenger` | `GraphSupport:BridgeMessenger/BaseDamageType` passe de `Melee` à `Projectile`. | Classification de l'action de soutien alignée avec son graphe, qui indiquait déjà `Oak.DamageType = Projectile` dans les deux captures. Voir l'analyse ci-dessous. |
| Valeur de l'épouvantail | `ScarecrowTotalDmg` augmente d'environ 22 % sur 151 niveaux (0 à 150). | Effet exact du champ non établi ; pas une hausse générale démontrée des statistiques de héros. |
| Initialisation des combats | `battle_state_base:new` accepte maintenant `parent_class` et copie `action`, `owner` et `cs_action` quand ce paramètre est fourni. La modification apparaît dans le Lua de l'APK et dans sa copie chiffrée. | Changement réel de logique, sans effet de gameplay déterminable à partir de ce seul diff. |

### Précisions sur les dégâts et l'épouvantail

Dans les données internes, `Projectile` est une valeur de `Oak.DamageType`, aux côtés de `Melee`. Elle décrit le type de dégâts d'une **action**, pas la classe permanente du héros ni nécessairement la forme physique de son animation. La fiche de `BridgeMessenger` n'a pas changé dans la table des héros ; seul `BaseDamageType` de `GraphSupport:BridgeMessenger` change. Les autres paramètres de cette action restent les mêmes (`TotalDpsMult = 3`, `Radius = 3.5`, `Duration = 1.2`, `Connect = Poison`). Le graphe Unity `SupportBridgeMessenger` est identique entre les deux captures et contient déjà `Oak.DamageType = Projectile`. L'interprétation la mieux étayée est donc une correction de cohérence de la configuration de l'action de soutien. Le rapport ne démontre ni un changement de toutes les attaques du héros ni l'effet exact sur chaque bonus/résistance mêlée ou distance.

Le *scarecrow* est l'épouvantail de guilde : une cible utilisée pour tester les dégâts d'une équipe, avec des variantes élémentaires et des classements. Le champ modifié figure dans `exps2`, à côté de `ArenaMaxDmg`, `ConquestTotalDmg` et `RaidTotalDmg`. Sur les niveaux 0 à 150, les anciennes et nouvelles valeurs diffèrent d'environ 22 % (par exemple, au niveau 0 : 21 278 175 → 25 959 375). À tous ces niveaux, `ScarecrowTotalDmg` vaut presque exactement `RaidTotalDmg × 2,321684` dans l'ancienne table et `RaidTotalDmg × 2,832455` dans la nouvelle. `RaidTotalDmg` et les autres colonnes ne changent pas ; la table `LevelExps.Switch` ne change pas non plus. Cela indique une mise à l'échelle systématique d'un barème par niveau, pas une modification des statistiques de chaque héros.

La fonction précise de ce barème reste indéterminée. Les deux seules occurrences de la clé dans les sorties décodées sont les anciennes et nouvelles copies d'`exps2` ; aucun script Lua décodé ne la référence. Dans les métadonnées d'une autre build 3.54.0 inspectée localement, `Oak.LevelExpSpec` expose les champs de niveau/expérience mais aucun des champs de dégâts (`ScarecrowTotalDmg`, `RaidTotalDmg`, etc.). Cette build n'est pas identique aux deux APK comparés, et les métadonnées des APK de cette comparaison restent chiffrées : on ne peut donc pas démontrer que le client actuel ignore le champ. Il pourrait servir de cible, de plafond, de normalisation, de simple donnée historique ou être exploité côté serveur. Il ne faut pas l'interpréter comme « tous les héros infligent 22 % de dégâts supplémentaires ».

Enfin, `battle_state_base:new(mt, parent_class)` transmet à un nouvel état Lua les références `action`, `owner` et `cs_action` de sa classe parente lorsqu'elle est fournie. Le constructeur était auparavant limité à `mt`. Cela facilite l'initialisation d'états dérivés ; le diff ne montre aucun changement direct de multiplicateur, de type de dégâts ou de comportement de l'épouvantail.

## Événements et calendrier repérés

- **Croissance du nouveau héros** : une saison et 30 nouvelles missions (niveau, évolution, éveil, bénédiction, etc.) sont ajoutées. Pour `KakaoGlobal`, la période liée à l'événement est configurée du **13 au 27 octobre 2026** dans la table `seasondate`.
- **Machine gacha géante** : événement `giant_gacha_27`, nouvelles missions et tables de récompenses. Sa période `KakaoGlobal` est également configurée du **13 au 27 octobre 2026**.
- **Pass** : deux saisons (ID 56 et 57) et 68 missions nouvelles apparaissent. La période du pass global (ID 5007001) va du **13 octobre au 9 novembre 2026** ; une période distincte est définie pour `Kong`.
- **Raid de guilde** : une saison (ID 44) et une configuration `Kong` sont ajoutées, avec une bannière associée à `wyverns_purple`. La période `KakaoGlobal` de l'ID 5400044 est du **15 au 21 octobre 2026**.
- **Autres contenus** : deux saisons de festival pass, une saison de Guild Punch King et un événement de présence nommé `year_5_anniversary_jp` figurent dans les tables. Des bannières de packs « 5anni » sont présentes. Leur simple présence ne garantit pas qu'ils soient actifs dans toutes les régions.

Les horodatages de `seasondate` utilisent plusieurs formats et des champs distincts par région (`KakaoGlobal`, `KakaoKorea`, `Kong`, etc.). Les dates ci-dessus reprennent les champs `KakaoGlobal` tels qu'enregistrés ; elles ne constituent pas une annonce officielle.

## Pourquoi certains chiffres sont trompeurs

**Localisation anglaise.** Le rapport annonce 168 955 changements pour chacun des deux fichiers `strings-bin-enUS` (cache et données installées). Il s'agit surtout d'une **renumérotation des identifiants** : 170 335 des 170 387 anciennes entrées retrouvent exactement le même texte dans la nouvelle table, souvent sous un autre ID. La nouvelle table a 100 entrées de plus. Il existe des textes réellement ajoutés ou retirés, notamment autour du nouveau personnage et du cinquième anniversaire, mais il serait erroné de parler de 168 955 traductions réécrites. Les deux fichiers reflètent essentiellement la même table.

**Scripts « ajoutés ».** Parmi les 785 nouveaux chemins Lua chiffrés, 697 sont dans `GameScript/stageeventcontrollers`. L'ancien inventaire ne contient qu'**un** fichier dans ce dossier, contre **699** dans le nouveau. Pour **532** des nouveaux chemins, un petit fichier Lua déjà présent à la racine dans les deux versions indique précisément le chemin du contrôleur désormais capturé (par exemple `AfterWorld1At1` pointe vers `stageeventcontrollers/AfterWorld1At1.lua`). Il s'agit donc de l'arrivée de l'implémentation dans la capture, pas d'une preuve que la fonctionnalité vient d'être créée en 3.55. Trois autres scripts ont un fichier racine homonyme, mais la correspondance du chemin n'est pas aussi directe. Les **250** autres chemins n'ont pas de fichier racine homonyme dans l'ancien inventaire ; leur date réelle d'introduction demande aussi une comparaison complète. Voir [l'annexe consacrée aux fichiers Lua](ANNEXE_LUA_v355.md).

**État de la couverture.** Le traitement s'est terminé avec `complete-with-gaps` et 7 624 diagnostics, principalement liés à l'inspection des AssetBundles Unity (3 808 côté précédent, 3 816 côté nouveau). Les 7 129 fichiers `.encrypted` présents dans la nouvelle capture ont toutefois été décodés, de même que les 130 fichiers de `static_data` considérés dans ce comptage. Les différences des fichiers Unity non interprétés restent visibles par empreinte, mais pas expliquées au niveau de leurs objets.

**Fichiers techniques.** Les APK, bibliothèques natives, fichiers DEX, icônes, index et caches changent aussi. Le rapport ne décompile pas les bibliothèques natives et ne permet pas d'attribuer un effet précis à leurs modifications. L'unique suppression est `apk/base/assets/bin/Data/8e70841960d6744b7b1a7f92fc12a4d4`, un petit fichier Unity contenant `UnityCloudBuildManifest.json` et les métadonnées de compilation de l'ancien APK. Le nouvel APK contient le même type de manifeste sous le nom `91ea1fa393f4c47f39710152b5020fd7`. Il s'agit du remplacement d'une ressource de construction, sans indication de retrait de contenu jouable.

## Conclusion pratique

Les nouveautés de contenu les mieux étayées sont le personnage `wyverns_purple`, son matériel associé et plusieurs configurations d'événements. Les changements à examiner en priorité pour un site sont ses fiches de héros et d'équipement, le calendrier régional, la hausse de `ScarecrowTotalDmg` et le type de dégâts de `BridgeMessenger`. Avant de publier une liste exhaustive des scripts ou des textes « nouveaux », il faut refaire la comparaison avec deux exports terminés et vérifier les changements de logique et les AssetBundles qui n'ont pas pu être décodés.
