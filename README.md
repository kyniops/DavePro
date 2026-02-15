# DAVE PRO TOOL V3
DAVE PRO TOOL est un script complet pour Roblox regroupant Aimbot, ESP, Movement, Visuals, Téléportation, emotes et quelques outils divers, le tout dans une interface propre et configurable.

## ⚙️ Installation / Chargement
1. Ouvre ton exécuteur/script‑executor Roblox (Synapse, KRNL, etc.).
2. Copie le contenu de daveprotool.lua ou utilise ton propre loader pour l’exécuter.
3. Une fois le script chargé, l’interface DAVE PRO TOOL apparaît à l’écran.
4. Tu peux masquer/afficher le menu avec la touche configurée (par défaut Insert ou RightControl ). Le tool sauvegarde automatiquement une config dans un fichier JSON (si writefile et readfile sont disponibles).
## 🧠 Onglet Aimbot
Fonctions principales :

- Activer Aimbot
   Active/désactive le lock automatique sur les joueurs dans le FOV.
- Touche Aimbot
   Touche pour activer/désactiver le lock (Aimlock).
- Lissage (Smooth)
   Plus la valeur est élevée, plus le mouvement de caméra vers la cible est fluide.
- Rayon FOV
   Zone dans laquelle l’aimbot peut lock une cible.
- Afficher FOV
   Affiche un cercle à l’écran représentant le FOV de l’aimbot.
- Team Check
   Ignore les joueurs de ta propre équipe.
- Visible Check
   Ne lock que les cibles réellement visibles (raycast).
- Ignorer Véhicules
   Ignore les hits sur les véhicules.
- Sticky Lock
   Reste sur la même cible tant qu’elle est valide.
- Auto Shoot
   Simule automatiquement le clic de tir quand une cible est lock.
- Tirs droits (No Spread)
   Stabilise la dispersion des balles.
- Distance Max
   Distance maximale à laquelle une cible peut être prise par l’aimbot.
- Cible: Tête / Torse
   Permet de changer la partie du corps ciblée par l’aimbot.
## 👁️ Onglet ESP
Affiche des informations visuelles sur les joueurs:

- Activer ESP
- Boxes (boîtes autour des joueurs)
- Squelettes
- Barre de Vie
- Noms
- Distance
- Traceurs (Tracers)
- Team Check
- Visible uniquement
- ESP Loot/Items (placeholder)
- Distance Max
Les couleurs de l’ESP sont configurables dans l’onglet Visuels .

## 👟 Onglet Mouvement
Tous les mouvements avancés sont regroupés ici :

- Mode Vol (Fly)
   Vol libre avec vitesse réglable.
- Touche Vol
   Touche pour activer/désactiver le fly.
- Vitesse Vol
   Slider de 10 à 500 .
- NoClip
   Désactive les collisions de ton personnage.
- Touche NoClip
   Touche pour activer/désactiver le NoClip.
- Speed Hack + Valeur Vitesse
   Augmente ta vitesse de marche.
- Anti‑dégâts de chute (Fly)
   Réduit/évite les dégâts de chute pendant le fly.
- Sprint amélioré + Multiplicateur Sprint
- Super Saut + Puissance Saut
- Double Saut
- Réduire Dégâts Chute
- AutoJump
- Bunny Hop
- Saut Infini
## ⚔️ Onglet Combat
- SpinBot
- AimAssist (aim assist léger différent de l’aimbot principal)
- Hitbox Expander
- Reach
- KillAura
- AutoClicker
- FOV Changer
- GodMode (selon le jeu, peut ou non fonctionner)
Ces options modifient la portée, la hitbox et certains comportements de combat.

## ✨ Onglet Visuels
Tout ce qui touche au rendu du jeu :

- Chams (Wallhack)
- Highlight ESP
- FullBright
- NoFog
- Transparence FOV
- Time Changer (heure du monde)
- Crosshair
- Anti‑Lag (FPS Boost)
- Mode Streamer
Section couleurs :

- Couleur du menu
- Couleur ESP
- Couleur FOV
- Bouton Reset Couleurs
## 🕺 Onglet Émotes
Système d’emotes custom avec fallback pour certains serveurs :

- Lancement d’emotes via ID d’animation.
- Mode “hélicoptère” custom si les émotes classiques ne fonctionnent pas.
- Gestion d’arrêt propre des émotes.
## 📍 Onglet Téléportation
Outils de TP et troll sur joueurs :

- Liste des joueurs + recherche
   Sélectionne la cible pour les actions suivantes.
- Click Teleport (Ctrl+LClick)
   Téléportation vers la position de la souris, avec paliers pour franchir de longues distances.
- Rafraîchir la liste
- Téléporter vers le joueur
   TP direct sur le joueur sélectionné.
- Fling Player
   Utilise un handle invisible + collisions pour projeter le joueur sélectionné.
- Téléportation aléatoire
   TP vers un joueur aléatoire.
- Annoy Player
- Bang Player
### Waypoints
- Création de waypoints nommés (Point 1, etc.).
- Liste des waypoints enregistrés.
- Boutons pour :
  - Se téléporter au waypoint
  - Sauvegarder la position actuelle
  - Vider tous les waypoints
## 📜 Onglet Scripts
- Boutons pour charger certains scripts externes (par exemple Blox Fruit via loadstring(game:HttpGet(...)) ).
## 🛠️ Onglet Divers (Misc)
- Anti‑AFK
- Chat Spammer
  - Message configurable
  - Délai entre chaque message
- Profils / Config
  - Sauvegarder config
  - Charger profil
  - Reset config aux valeurs par défaut
## 🧪 Tests internes
À la fin du script, plusieurs tests de modules/logique sont exécutés et logués dans la console (ESP, Aimbot, Mouvement, UI, etc.).
 Un message final confirme le chargement complet :

```
💎 PRO TOOL V3.3 - TOOL V3.3 - TOUS LES 
ONGLETS CORRIGÉS ✅
```
## ⚠️ Avertissement
- L’utilisation de scripts, cheats ou tools sur Roblox peut entraîner:
  - des bannissements de jeux spécifiques,
  - voire des sanctions sur ton compte.
- Utilise ce tool à tes risques et périls et uniquement là où tu acceptes les conséquences.
