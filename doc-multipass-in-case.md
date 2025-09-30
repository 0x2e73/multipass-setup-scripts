# Guide Multipass - Environnement de développement PHP

Ce guide vous permet de créer un environnement de développement web isolé avec Ubuntu, Apache, PHP et une configuration complète pour le développement.

## Table des matières

- [Installation rapide (scripts automatisés)](#installation-rapide-scripts-automatisés)
- [Installation manuelle](#installation-manuelle)
- [Vérification et tests](#vérification-et-tests)
- [Erreurs courantes et résolutions](#erreurs-courantes-et-résolutions)
- [Commandes utiles](#commandes-utiles)

## Installation rapide (scripts automatisés)

### Windows (PowerShell)
```powershell
# Télécharger et exécuter le script
# Voir le script fourni séparément
```

### macOS
```bash
# Télécharger et exécuter le script
# Voir le script fourni séparément
```

## Installation manuelle

### Prérequis
- Multipass installé sur votre système
- Accès à GitLab (clé SSH configurée)
- VSCode avec l'extension Remote-SSH

### 1. Installation de Multipass

**Windows:**
Téléchargez depuis [multipass.run](https://multipass.run/)

**macOS:**
```bash
brew install multipass
```

### 2. Création de l'instance

```bash
# Créer une instance avec 2 CPU, 4GB RAM et 20GB disque
multipass launch --name dev-server -c 2 -m 4GB -d 20GB

# Vérifier que l'instance est créée
multipass list

# Se connecter à l'instance
multipass shell dev-server
```

### 3. Mise à jour du système Ubuntu

```bash
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
```

### 4. Installation des logiciels essentiels

```bash
# Installer Apache2
sudo apt install apache2 -y

# Installer Git et curl
sudo apt install git curl -y

# Installer Zsh
sudo apt install zsh -y
```

### 5. Installation et configuration de PHP

#### Installation de PHP et modules essentiels
```bash
# Installer PHP 8.3 et les modules courants
sudo apt install php php-cli php-mysql php-xml php-mbstring php-curl php-zip php-gd -y

# Vérifier l'installation
php -v

# Vérifier les modules installés
php -m
```

#### Activer le module PHP dans Apache
```bash
# Activer le module PHP
sudo a2enmod php8.3

# Activer mod_rewrite (utile pour les URLs propres)
sudo a2enmod rewrite

# Redémarrer Apache
sudo systemctl restart apache2
```

#### Configuration de base de PHP
```bash
# Éditer le fichier php.ini pour Apache
sudo nano /etc/php/8.3/apache2/php.ini
```

**Paramètres importants à vérifier/modifier:**
```ini
# Affichage des erreurs (pour développement)
display_errors = On
error_reporting = E_ALL

# Limite de mémoire
memory_limit = 256M

# Taille max des uploads
upload_max_filesize = 20M
post_max_size = 25M

# Timezone
date.timezone = Europe/Zurich
```

**Après modification:**
```bash
# Redémarrer Apache pour appliquer les changements
sudo systemctl restart apache2
```

#### Test de PHP
```bash
# Créer un fichier de test PHP
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php

# Vérifier les permissions
sudo chown www-data:www-data /var/www/html/info.php
```

Ouvrir dans le navigateur: `http://IP_DE_LINSTANCE/info.php`

**⚠️ Supprimer le fichier après le test (sécurité):**
```bash
sudo rm /var/www/html/info.php
```

#### Logs PHP
```bash
# Voir les erreurs PHP en temps réel
sudo tail -f /var/log/apache2/error.log

# Voir les logs d'accès Apache
sudo tail -f /var/log/apache2/access.log
```

### 6. Configuration de Zsh et Oh My Zsh

```bash
# Installer Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Changer le shell par défaut vers zsh
chsh -s $(which zsh)

# Configurer le thème
nano ~/.zshrc
# Modifier la ligne : ZSH_THEME="bira"
```

### 7. Configuration SSH dans l'instance

#### Génération de clé SSH pour GitLab
```bash
# Générer une clé SSH pour GitLab (dans l'instance)
ssh-keygen -t ed25519 -C "votre-email@example.com"

# Afficher la clé publique pour l'ajouter à GitLab
cat ~/.ssh/id_ed25519.pub
```

#### Configuration GitLab
```bash
# Créer le fichier de configuration SSH
mkdir -p ~/.ssh
nano ~/.ssh/config
```

Contenu du fichier `~/.ssh/config` :
```
# Configuration pour GitLab ICTGE
Host gitlab.ictge.ch
    HostName gitlab.ictge.ch
    User git
    Port 22002
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
```

### 8. Configuration des permissions Apache

```bash
# Ajouter l'utilisateur ubuntu au groupe www-data
sudo usermod -a -G www-data $USER

# Se déconnecter et reconnecter pour appliquer les changements
exit
multipass shell dev-server

# Vérifier l'appartenance au groupe
groups

# Configurer les permissions du dossier web
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 775 /var/www/html

# Configurer les permissions par défaut
sudo chmod g+s /var/www/html
```

### 9. Configuration de la connexion SSH externe

#### Dans l'instance - autoriser la connexion SSH
```bash
sudo systemctl enable ssh
sudo systemctl start ssh

# Créer le dossier des clés autorisées
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### Générer une clé SSH sur votre machine hôte

**Windows (PowerShell):**
```powershell
ssh-keygen -t ed25519 -C "votre-email@example.com"
# Sauvegarder dans C:\Users\VotreNom\.ssh\id_ed25519

# Copier le contenu de votre clé publique
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | Set-Clipboard
```

**macOS:**
```bash
ssh-keygen -t ed25519 -C "votre-email@example.com"
# Sauvegarder dans ~/.ssh/id_ed25519

# Copier le contenu de votre clé publique
pbcopy < ~/.ssh/id_ed25519.pub
```

#### Dans l'instance Ubuntu
```bash
# Coller votre clé publique dans le fichier authorized_keys
nano ~/.ssh/authorized_keys
# Coller le contenu de votre clé publique et sauvegarder
```

### 10. Obtenir l'adresse IP de l'instance

```bash
# Sur votre système hôte
multipass info dev-server
# Noter l'adresse IPv4
```

### 11. Configuration VSCode

1. Installer l'extension "Remote-SSH" dans VSCode
2. Ouvrir la palette de commandes (Ctrl/Cmd + Shift + P)
3. Taper "Remote-SSH: Connect to Host"
4. Ajouter une nouvelle connexion SSH :

**Format de connexion:**
```
ubuntu@IP_DE_LINSTANCE
```

5. Éditer le fichier de configuration SSH de VSCode si nécessaire

### 12. Installation et configuration de XDebug

#### Installation via apt (méthode recommandée)
```bash
# Installer XDebug
sudo apt install php-xdebug -y

# Vérifier l'installation
php -m | grep xdebug
```

#### Configuration de XDebug
```bash
# Créer le fichier de configuration XDebug
sudo nano /etc/php/8.3/mods-available/xdebug.ini
```

**Contenu du fichier xdebug.ini:**
```ini
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=localhost
xdebug.client_port=9003
xdebug.discover_client_host=1
xdebug.log=/tmp/xdebug.log
xdebug.log_level=7
```

#### Activer XDebug et redémarrer
```bash
# Activer le module
sudo phpenmod xdebug

# Redémarrer Apache
sudo systemctl restart apache2

# Vérifier que XDebug est actif
php -v
# Devrait afficher "with Xdebug v3.x.x"
```

#### Test de XDebug
```bash
# Créer un fichier de test
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/xdebug-test.php
```

Ouvrir `http://IP_DE_LINSTANCE/xdebug-test.php` et chercher "xdebug" dans la page.

#### Configuration VSCode pour XDebug
Dans VSCode, créer `.vscode/launch.json` dans votre projet:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for XDebug",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "pathMappings": {
                "/var/www/html": "${workspaceFolder}"
            }
        }
    ]
}
```

## Vérification et tests

### Test du serveur Apache
```bash
# Vérifier le statut d'Apache
sudo systemctl status apache2

# Créer une page de test
echo "<h1>Serveur de développement actif</h1>" | sudo tee /var/www/html/index.html
```

Ouvrir un navigateur et aller à `http://IP_DE_LINSTANCE`

### Test de la connexion SSH
```bash
# Depuis votre système hôte
ssh ubuntu@IP_DE_LINSTANCE
```

### Test de GitLab
```bash
# Dans l'instance
ssh -T git@gitlab.ictge.ch
```

### Test de PHP
```bash
# Vérifier la version PHP
php -v

# Tester un script PHP
php -r "echo 'PHP fonctionne correctement\n';"

# Tester PHP avec Apache
curl http://localhost
```

## Erreurs courantes et résolutions

### 🔴 Erreurs PHP

#### PHP ne s'exécute pas (code affiché en brut dans le navigateur)
**Symptôme:** Le code PHP `<?php ... ?>` s'affiche tel quel dans le navigateur.

**Causes:**
- Module PHP non activé dans Apache
- Fichier ne se termine pas par `.php`

**Solution:**
```bash
# Vérifier que PHP est installé
php -v

# Activer le module PHP
sudo a2enmod php8.3

# Redémarrer Apache
sudo systemctl restart apache2

# Vérifier que le fichier a bien l'extension .php
ls -la /var/www/html/
```

#### Fatal error: Allowed memory size exhausted
**Symptôme:** `Fatal error: Allowed memory size of X bytes exhausted`

**Solution:**
```bash
# Éditer php.ini
sudo nano /etc/php/8.3/apache2/php.ini

# Augmenter la limite (trouver la ligne memory_limit)
memory_limit = 512M

# Redémarrer Apache
sudo systemctl restart apache2
```

#### Warning: file_put_contents(): Permission denied
**Symptôme:** PHP ne peut pas écrire de fichiers.

**Solution:**
```bash
# Vérifier les permissions du dossier
ls -la /var/www/html/

# Donner les bonnes permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 775 /var/www/html

# Si besoin d'écrire dans un dossier spécifique (ex: uploads/)
sudo mkdir -p /var/www/html/uploads
sudo chown www-data:www-data /var/www/html/uploads
sudo chmod 775 /var/www/html/uploads
```

#### Extension PHP manquante (ex: mysqli, curl, etc.)
**Symptôme:** `Fatal error: Uncaught Error: Call to undefined function mysqli_connect()`

**Solution:**
```bash
# Lister les modules PHP installés
php -m

# Installer le module manquant (exemples)
sudo apt install php-mysql    # Pour MySQL/MariaDB
sudo apt install php-curl     # Pour cURL
sudo apt install php-gd       # Pour les images
sudo apt install php-mbstring # Pour les chaînes multi-bytes
sudo apt install php-xml      # Pour XML

# Redémarrer Apache
sudo systemctl restart apache2
```

#### Parse error ou Syntax error
**Symptôme:** `Parse error: syntax error, unexpected...`

**Diagnostic:**
```bash
# Vérifier la syntaxe PHP d'un fichier
php -l /var/www/html/votre-fichier.php

# Voir les erreurs détaillées dans les logs
sudo tail -f /var/log/apache2/error.log
```

**Causes courantes:**
- Oubli d'un `;` en fin de ligne
- Parenthèses ou accolades non fermées
- Guillemets non fermés
- Mauvais encodage du fichier

### 🟠 Erreurs Apache

#### Apache ne démarre pas
**Solution:**
```bash
# Voir l'erreur exacte
sudo systemctl status apache2

# Voir les logs détaillés
sudo journalctl -u apache2 -n 50 --no-pager

# Tester la configuration Apache
sudo apache2ctl configtest

# Si erreur dans la config, la corriger puis:
sudo systemctl restart apache2
```

#### Port 80 déjà utilisé
**Symptôme:** `(98)Address already in use: AH00072: make_sock: could not bind to address [::]:80`

**Solution:**
```bash
# Voir quel processus utilise le port 80
sudo lsof -i :80

# Si c'est un autre Apache, le tuer
sudo killall apache2

# Redémarrer proprement
sudo systemctl start apache2
```

#### .htaccess ignoré (URL rewriting ne fonctionne pas)
**Symptôme:** Les règles dans `.htaccess` ne s'appliquent pas.

**Solution:**
```bash
# Activer mod_rewrite
sudo a2enmod rewrite

# Éditer la config du site
sudo nano /etc/apache2/sites-available/000-default.conf
```

**Ajouter dans la section `<VirtualHost>`:**
```apache
<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
```

```bash
# Tester la configuration
sudo apache2ctl configtest

# Redémarrer Apache
sudo systemctl restart apache2
```

#### 403 Forbidden
**Symptôme:** Erreur 403 lors de l'accès à une page.

**Causes et solutions:**
```bash
# 1. Problème de permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# 2. Pas de fichier index
ls /var/www/html/
# Créer un index.php ou index.html

# 3. Configuration Apache stricte
sudo nano /etc/apache2/sites-available/000-default.conf
# Vérifier que "Require all granted" est présent
```

### 🟡 Erreurs XDebug

#### XDebug ne se connecte pas dans VSCode
**Diagnostic:**
```bash
# Vérifier que XDebug est chargé
php -v | grep -i xdebug

# Vérifier la configuration
php -i | grep xdebug

# Voir les logs XDebug
tail -f /tmp/xdebug.log
```

**Solutions:**
1. Vérifier que le port 9003 n'est pas bloqué
2. Vérifier `xdebug.client_host` dans la config
3. Dans VSCode, installer l'extension "PHP Debug"
4. Redémarrer Apache après tout changement:
```bash
sudo systemctl restart apache2
```

#### XDebug ralentit le site
**Solution:**
```bash
# Désactiver temporairement XDebug
sudo phpdismod xdebug
sudo systemctl restart apache2

# Réactiver quand nécessaire
sudo phpenmod xdebug
sudo systemctl restart apache2
```

### 🔵 Erreurs SSH & GitLab

#### Permission denied (publickey)
**Symptôme:** `Permission denied (publickey)` lors d'un `git clone` ou `ssh -T`.

**Solution:**
```bash
# Vérifier que la clé SSH existe
ls -la ~/.ssh/

# Vérifier le contenu de la clé publique
cat ~/.ssh/id_ed25519.pub

# Tester la connexion avec debug
ssh -vT git@gitlab.ictge.ch

# Vérifier la config SSH
cat ~/.ssh/config

# Vérifier les permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/config
```

**Vérifier sur GitLab:**
- La clé publique est bien ajoutée dans Settings > SSH Keys
- La clé n'est pas expirée

#### Port 22002: Connection refused
**Symptôme:** Impossible de se connecter à GitLab.

**Solution:**
```bash
# Tester avec telnet
telnet gitlab.ictge.ch 22002

# Vérifier la config SSH
cat ~/.ssh/config

# Vérifier qu'il n'y a pas de firewall qui bloque
```

#### Could not resolve hostname
**Symptôme:** `Could not resolve hostname gitlab.ictge.ch`

**Solution:**
```bash
# Vérifier la connexion internet de l'instance
ping google.com

# Vérifier le DNS
nslookup gitlab.ictge.ch

# Si le DNS ne fonctionne pas, redémarrer l'instance
exit
multipass restart dev-server
multipass shell dev-server
```

### 🟢 Erreurs Multipass & Connexion

#### L'instance ne répond plus / freeze
**Solution:**
```bash
# Sur la machine hôte
# Arrêter proprement
multipass stop dev-server

# Attendre 10 secondes, puis redémarrer
multipass start dev-server

# Si ça ne fonctionne pas, redémarrage forcé
multipass restart dev-server
```

#### Connexion SSH VSCode perdue
**Symptôme:** VSCode ne peut plus se connecter, message "Could not establish connection".

**Cause:** L'IP de l'instance a changé après redémarrage.

**Solution:**
```bash
# Obtenir la nouvelle IP
multipass info dev-server

# Noter l'IP dans la ligne "IPv4:"
# Exemple: 192.168.64.5
```

Dans VSCode:
1. Ouvrir la palette (Ctrl/Cmd + Shift + P)
2. "Remote-SSH: Open SSH Configuration File"
3. Modifier l'IP:
```
Host dev-server
    HostName NOUVELLE_IP_ICI
    User ubuntu
```

#### Instance Multipass disparue
**Symptôme:** `multipass list` ne montre plus l'instance.

**Solution:**
```bash
# Lister toutes les instances (même supprimées)
multipass list --all

# Si elle est marquée "deleted"
multipass recover dev-server

# Si vraiment perdue, vérifier dans la corbeille
multipass purge  # ATTENTION: supprime définitivement
```

#### Pas assez d'espace disque dans l'instance
**Symptôme:** Erreur "No space left on device"

**Diagnostic:**
```bash
# Voir l'utilisation du disque
df -h

# Voir les plus gros dossiers
du -sh /var/* | sort -h
```

**Solutions:**
```bash
# Nettoyer les packages inutiles
sudo apt autoremove -y
sudo apt clean

# Nettoyer les logs
sudo journalctl --vacuum-time=3d

# Supprimer les anciennes versions de kernels
sudo apt autoremove --purge
```

### 🟣 Erreurs de permissions

#### "Operation not permitted" même avec sudo
**Solution:**
```bash
# Vérifier que vous êtes bien dans le bon groupe
groups

# Vous devriez voir: ubuntu www-data

# Si www-data manque:
sudo usermod -a -G www-data $USER

# Se déconnecter et reconnecter
exit
multipass shell dev-server
```

#### Fichiers créés par PHP non modifiables
**Symptôme:** Fichiers créés par PHP appartiennent à www-data, vous ne pouvez plus les modifier.

**Solution:**
```bash
# Méthode 1: Changer le propriétaire temporairement
sudo chown ubuntu:ubuntu /var/www/html/le-fichier.php

# Méthode 2: S'ajouter au groupe www-data (fait normalement lors de la config)
sudo usermod -a -G www-data ubuntu

# Méthode 3: Utiliser sudo pour éditer
sudo nano /var/www/html/le-fichier.php
```

### 📋 Commandes de diagnostic rapide

**En cas de problème, lancer ces commandes:**
```bash
# Status des services
sudo systemctl status apache2
sudo systemctl status ssh

# Versions installées
php -v
apache2 -v

# Modules PHP
php -m

# Tester la config Apache
sudo apache2ctl configtest

# Voir les logs en temps réel
sudo tail -f /var/log/apache2/error.log

# Info instance
multipass info dev-server

# Connexion réseau
ping google.com
curl http://localhost
```

### 🆘 En dernier recours

Si rien ne fonctionne:
```bash
# Sur la machine hôte
# Sauvegarder vos fichiers si possible
multipass exec dev-server -- tar -czf /tmp/backup.tar.gz /var/www/html

# Copier le backup sur la machine hôte
multipass transfer dev-server:/tmp/backup.tar.gz ~/backup.tar.gz

# Supprimer et recréer l'instance
multipass delete dev-server
multipass purge
multipass launch --name dev-server -c 2 -m 4GB -d 20GB

# Recommencer la configuration depuis le début
```

## Commandes utiles

### Gestion des instances Multipass
```bash
# Lister toutes les instances
multipass list

# Obtenir des informations détaillées sur une instance
multipass info dev-server

# Arrêter une instance
multipass stop dev-server

# Démarrer une instance
multipass start dev-server

# Redémarrer une instance
multipass restart dev-server

# Se connecter à une instance
multipass shell dev-server

# Supprimer une instance
multipass delete dev-server
multipass purge

# Monter un dossier local dans l'instance
multipass mount /chemin/local dev-server:/chemin/distant

# Transférer un fichier vers l'instance
multipass transfer fichier.txt dev-server:/home/ubuntu/

# Transférer un fichier depuis l'instance
multipass transfer dev-server:/home/ubuntu/fichier.txt ~/
```

### Gestion d'Apache
```bash
# Démarrer Apache
sudo systemctl start apache2

# Arrêter Apache
sudo systemctl stop apache2

# Redémarrer Apache
sudo systemctl restart apache2

# Recharger la configuration sans redémarrer
sudo systemctl reload apache2

# Voir le statut d'Apache
sudo systemctl status apache2

# Activer Apache au démarrage
sudo systemctl enable apache2

# Tester la configuration
sudo apache2ctl configtest

# Lister les modules activés
apache2ctl -M
```

### Gestion de PHP
```bash
# Vérifier la version PHP
php -v

# Lister les modules PHP installés
php -m

# Voir la configuration PHP
php -i

# Tester un fichier PHP
php -l fichier.php

# Exécuter du code PHP en ligne de commande
php -r "echo 'Hello World';"

# Afficher les erreurs PHP
php -d display_errors=1 fichier.php
```

## Sécurité

- Changez les mots de passe par défaut
- Configurez un firewall si nécessaire
- Utilisez uniquement des clés SSH pour l'authentification
- Maintenez le système à jour
- Ne laissez pas `phpinfo()` accessible en production
- Limitez les permissions au minimum nécessaire

## Maintenance

### Mise à jour régulière
```bash
# Mise à jour des packages
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y

# Nettoyage des logs
sudo journalctl --vacuum-time=7d

# Vérifier l'espace disque
df -h
```

### Backup
```bash
# Sauvegarder le dossier web
sudo tar -czf ~/backup-web-$(date +%Y%m%d).tar.gz /var/www/html

# Sauvegarder les configurations
sudo tar -czf ~/backup-config-$(date +%Y%m%d).tar.gz /etc/apache2 /etc/php
```