#!/bin/bash
# Script d'installation automatique Multipass + PHP pour macOS
# Auteur: Configuration automatisée
# Usage: chmod +x setup-macos.sh && ./setup-macos.sh

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}Installation Multipass + PHP${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Vérifier que Multipass est installé
echo -e "${YELLOW}[1/10] Vérification de Multipass...${NC}"
if ! command -v multipass &> /dev/null; then
    echo -e "${RED}✗ Multipass n'est pas installé!${NC}"
    echo -e "${YELLOW}Installation via Homebrew...${NC}"
    if command -v brew &> /dev/null; then
        brew install multipass
        echo -e "${GREEN}✓ Multipass installé${NC}"
    else
        echo -e "${RED}Homebrew n'est pas installé.${NC}"
        echo -e "${YELLOW}Téléchargez Multipass depuis: https://multipass.run/${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Multipass est installé${NC}"
fi

# Demander l'email pour SSH
echo ""
read -p "Entrez votre adresse email pour les clés SSH: " email
if [ -z "$email" ]; then
    email="user@example.com"
    echo -e "${YELLOW}Email par défaut utilisé: $email${NC}"
fi

# Vérifier si l'instance existe déjà
echo ""
echo -e "${YELLOW}[2/10] Vérification de l'instance existante...${NC}"
if multipass list | grep -q "dev-server"; then
    echo -e "${YELLOW}⚠ L'instance 'dev-server' existe déjà${NC}"
    read -p "Voulez-vous la supprimer et recréer? (o/N): " response
    if [ "$response" = "o" ] || [ "$response" = "O" ]; then
        echo -e "${YELLOW}Suppression de l'instance...${NC}"
        multipass delete dev-server
        multipass purge
        echo -e "${GREEN}✓ Instance supprimée${NC}"
        skip_creation=false
    else
        echo -e "${YELLOW}Utilisation de l'instance existante${NC}"
        skip_creation=true
    fi
else
    skip_creation=false
fi

# Créer l'instance Multipass
if [ "$skip_creation" = false ]; then
    echo ""
    echo -e "${YELLOW}[3/10] Création de l'instance Multipass...${NC}"
    echo -e "${CYAN}Cela peut prendre quelques minutes...${NC}"
    multipass launch --name dev-server -c 2 -m 4GB -d 20GB
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Instance créée avec succès${NC}"
    else
        echo -e "${RED}✗ Erreur lors de la création de l'instance${NC}"
        exit 1
    fi
else
    echo "[3/10] Création ignorée (instance existante)"
fi

# Attendre que l'instance soit prête
echo ""
echo -e "${YELLOW}[4/10] Attente du démarrage de l'instance...${NC}"
sleep 5

# Créer le script de configuration
echo ""
echo -e "${YELLOW}[5/10] Préparation du script de configuration...${NC}"

cat > /tmp/setup-multipass.sh << 'EOFSCRIPT'
#!/bin/bash
set -e

echo ""
echo "==================================="
echo "Configuration de l'environnement"
echo "==================================="
echo ""

# Mise à jour du système
echo "[1/8] Mise à jour du système..."
sudo apt update -qq
sudo apt upgrade -y -qq
sudo apt autoremove -y -qq
echo "✓ Système mis à jour"

# Installation des logiciels essentiels
echo ""
echo "[2/8] Installation d'Apache, Git, Curl, Zsh..."
sudo apt install apache2 git curl zsh -y -qq
echo "✓ Logiciels essentiels installés"

# Installation de PHP et modules
echo ""
echo "[3/8] Installation de PHP et modules..."
sudo apt install php php-cli php-mysql php-xml php-mbstring php-curl php-zip php-gd php-xdebug -y -qq
echo "✓ PHP installé"

# Activation des modules Apache
echo ""
echo "[4/8] Activation des modules Apache..."
sudo a2enmod php8.3 >/dev/null 2>&1
sudo a2enmod rewrite >/dev/null 2>&1
sudo systemctl restart apache2
echo "✓ Modules Apache activés"

# Configuration de PHP
echo ""
echo "[5/8] Configuration de PHP..."
sudo sed -i 's/^display_errors = Off/display_errors = On/' /etc/php/8.3/apache2/php.ini
sudo sed -i 's/^error_reporting = .*/error_reporting = E_ALL/' /etc/php/8.3/apache2/php.ini
sudo sed -i 's/^memory_limit = .*/memory_limit = 256M/' /etc/php/8.3/apache2/php.ini
sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/' /etc/php/8.3/apache2/php.ini
sudo sed -i 's/^post_max_size = .*/post_max_size = 25M/' /etc/php/8.3/apache2/php.ini
sudo sed -i 's|^;date.timezone =.*|date.timezone = Europe/Zurich|' /etc/php/8.3/apache2/php.ini
echo "✓ PHP configuré"

# Configuration de XDebug
echo ""
echo "[6/8] Configuration de XDebug..."
sudo bash -c 'cat > /etc/php/8.3/mods-available/xdebug.ini << EOL
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=localhost
xdebug.client_port=9003
xdebug.discover_client_host=1
xdebug.log=/tmp/xdebug.log
xdebug.log_level=7
EOL'
sudo phpenmod xdebug
sudo systemctl restart apache2
echo "✓ XDebug configuré"

# Configuration des permissions
echo ""
echo "[7/8] Configuration des permissions..."
sudo usermod -a -G www-data ubuntu
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 775 /var/www/html
sudo chmod g+s /var/www/html
echo "✓ Permissions configurées"

# Configuration SSH
echo ""
echo "[8/8] Configuration SSH..."
sudo systemctl enable ssh >/dev/null 2>&1
sudo systemctl start ssh >/dev/null 2>&1
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Génération clé SSH pour GitLab
ssh-keygen -t ed25519 -C "EMAIL_PLACEHOLDER" -f ~/.ssh/id_ed25519 -N "" >/dev/null 2>&1

# Configuration GitLab
cat > ~/.ssh/config << EOL
Host gitlab.ictge.ch
    HostName gitlab.ictge.ch
    User git
    Port 22002
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
EOL
chmod 600 ~/.ssh/config

# Installer Oh My Zsh
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 || true
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="bira"/' ~/.zshrc 2>/dev/null || true

echo "✓ SSH configuré"

# Créer une page de test
echo ""
echo "Création d'une page de test..."
echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/index.php >/dev/null
sudo chown www-data:www-data /var/www/html/index.php

echo ""
echo "==================================="
echo "✓ Configuration terminée!"
echo "==================================="
echo ""
echo "Clé SSH publique pour GitLab:"
echo "----------------------------"
cat ~/.ssh/id_ed25519.pub
echo ""
echo "Ajoutez cette clé dans GitLab: Settings > SSH Keys"
echo ""
EOFSCRIPT

# Remplacer l'email dans le script
sed -i.bak "s/EMAIL_PLACEHOLDER/$email/g" /tmp/setup-multipass.sh
rm /tmp/setup-multipass.sh.bak

# Transférer et exécuter le script
echo ""
echo -e "${YELLOW}[6/10] Transfert du script vers l'instance...${NC}"
multipass transfer /tmp/setup-multipass.sh dev-server:/tmp/setup.sh

echo ""
echo -e "${YELLOW}[7/10] Exécution de la configuration (cela prend 3-5 minutes)...${NC}"
echo -e "${CYAN}Veuillez patienter...${NC}"
multipass exec dev-server -- bash /tmp/setup.sh

# Nettoyer
rm /tmp/setup-multipass.sh

# Obtenir l'IP de l'instance
echo ""
echo -e "${YELLOW}[8/10] Récupération de l'adresse IP...${NC}"
ip=$(multipass info dev-server | grep "IPv4" | awk '{print $2}')
if [ -n "$ip" ]; then
    echo -e "${GREEN}✓ IP de l'instance: $ip${NC}"
else
    echo -e "${RED}✗ Impossible de récupérer l'IP${NC}"
    ip="ERREUR"
fi

# Générer une clé SSH sur macOS si elle n'existe pas
echo ""
echo -e "${YELLOW}[9/10] Vérification de votre clé SSH locale...${NC}"
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo -e "${YELLOW}Génération d'une clé SSH locale...${NC}"
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""
    echo -e "${GREEN}✓ Clé SSH créée${NC}"
else
    echo -e "${GREEN}✓ Clé SSH existe déjà${NC}"
fi

# Copier la clé publique locale dans l'instance
echo ""
echo -e "${YELLOW}[10/10] Configuration de l'accès SSH depuis macOS...${NC}"
public_key=$(cat ~/.ssh/id_ed25519.pub)
multipass exec dev-server -- bash -c "echo '$public_key' >> ~/.ssh/authorized_keys"
echo -e "${GREEN}✓ Clé SSH ajoutée à l'instance${NC}"

# Afficher le résumé
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ INSTALLATION TERMINÉE!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${CYAN}Informations importantes:${NC}"
echo -e "${CYAN}------------------------${NC}"
echo -e "IP de l'instance: ${WHITE}$ip${NC}"
echo -e "URL du serveur: ${WHITE}http://$ip${NC}"
echo ""
echo -e "${CYAN}Commandes utiles:${NC}"
echo "  Se connecter: multipass shell dev-server"
echo "  SSH direct: ssh ubuntu@$ip"
echo "  Arrêter: multipass stop dev-server"
echo "  Redémarrer: multipass restart dev-server"
echo ""
echo -e "${CYAN}Configuration VSCode SSH:${NC}"
echo "  Host: ubuntu@$ip"
echo ""
echo -e "${YELLOW}IMPORTANT: Clé SSH pour GitLab${NC}"
echo -e "${YELLOW}------------------------------${NC}"
echo -e "${YELLOW}Pour obtenir la clé publique à ajouter sur GitLab:${NC}"
echo "  multipass exec dev-server -- cat ~/.ssh/id_ed25519.pub"
echo ""
echo -e "${CYAN}Testez votre serveur: http://$ip${NC}"
echo ""

# Ouvrir le navigateur
read -p "Ouvrir le navigateur maintenant? (o/N): " response
if [ "$response" = "o" ] || [ "$response" = "O" ]; then
    open "http://$ip"
fi

echo ""
echo "Installation terminée avec succès!"