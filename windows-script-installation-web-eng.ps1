# Script d'installation automatique Multipass + PHP pour Windows
# Auteur: Configuration automatisée
# Usage: Clic droit > Exécuter avec PowerShell (en tant qu'admin si possible)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Installation Multipass + PHP" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que Multipass est installé
Write-Host "[1/10] Vérification de Multipass..." -ForegroundColor Yellow
try {
    $multipassVersion = multipass version 2>&1
    Write-Host "✓ Multipass est installé" -ForegroundColor Green
} catch {
    Write-Host "✗ Multipass n'est pas installé!" -ForegroundColor Red
    Write-Host "Téléchargez-le depuis: https://multipass.run/" -ForegroundColor Yellow
    pause
    exit 1
}


# Vérifier si l'instance existe déjà
Write-Host ""
Write-Host "[2/10] Vérification de l'instance existante..." -ForegroundColor Yellow
$existingInstance = multipass list | Select-String "dev-server"
if ($existingInstance) {
    Write-Host "⚠ L'instance 'dev-server' existe déjà" -ForegroundColor Yellow
    $response = Read-Host "Voulez-vous la supprimer et recréer? (o/N)"
    if ($response -eq "o" -or $response -eq "O") {
        Write-Host "Suppression de l'instance..." -ForegroundColor Yellow
        multipass delete dev-server
        multipass purge
        Write-Host "✓ Instance supprimée" -ForegroundColor Green
    } else {
        Write-Host "Utilisation de l'instance existante" -ForegroundColor Yellow
        $skipCreation = $true
    }
}

# Créer l'instance Multipass
if (-not $skipCreation) {
    Write-Host ""
    Write-Host "[3/10] Création de l'instance Multipass..." -ForegroundColor Yellow
    Write-Host "Cela peut prendre quelques minutes..." -ForegroundColor Gray
    multipass launch --name dev-server -c 2 -m 4GB -d 20GB
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Instance créée avec succès" -ForegroundColor Green
    } else {
        Write-Host "✗ Erreur lors de la création de l'instance" -ForegroundColor Red
        pause
        exit 1
    }
} else {
    Write-Host "[3/10] Création ignorée (instance existante)" -ForegroundColor Gray
}

# Attendre que l'instance soit prête
Write-Host ""
Write-Host "[4/10] Attente du démarrage de l'instance..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Créer le script de configuration
Write-Host ""
Write-Host "[5/10] Préparation du script de configuration..." -ForegroundColor Yellow

$configScript = @"
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
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" >/dev/null 2>&1

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
sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 || true
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
"@

# Sauvegarder le script temporairement
$tempScript = [System.IO.Path]::GetTempFileName()
$configScript | Out-File -FilePath $tempScript -Encoding ASCII

# Transférer et exécuter le script
Write-Host ""
Write-Host "[6/10] Transfert du script vers l'instance..." -ForegroundColor Yellow
multipass transfer $tempScript dev-server:/tmp/setup.sh

Write-Host ""
Write-Host "[7/10] Exécution de la configuration (cela prend 3-5 minutes)..." -ForegroundColor Yellow
Write-Host "Veuillez patienter..." -ForegroundColor Gray
multipass exec dev-server -- bash /tmp/setup.sh

# Nettoyer
Remove-Item $tempScript

# Obtenir l'IP de l'instance
Write-Host ""
Write-Host "[8/10] Récupération de l'adresse IP..." -ForegroundColor Yellow
$ipInfo = multipass info dev-server | Select-String "IPv4:"
if ($ipInfo) {
    $ip = ($ipInfo -split "\s+")[1]
    Write-Host "✓ IP de l'instance: $ip" -ForegroundColor Green
} else {
    Write-Host "✗ Impossible de récupérer l'IP" -ForegroundColor Red
    $ip = "ERREUR"
}

# Générer une clé SSH sur Windows si elle n'existe pas
Write-Host ""
Write-Host "[9/10] Vérification de votre clé SSH locale..." -ForegroundColor Yellow
$sshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519"
if (-not (Test-Path $sshKeyPath)) {
    Write-Host "Génération d'une clé SSH locale..." -ForegroundColor Yellow
    $sshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir | Out-Null
    }
    ssh-keygen -t ed25519 -f $sshKeyPath -N '""'
    Write-Host "✓ Clé SSH créée" -ForegroundColor Green
} else {
    Write-Host "✓ Clé SSH existe déjà" -ForegroundColor Green
}

# Copier la clé publique locale dans l'instance
Write-Host ""
Write-Host "[10/10] Configuration de l'accès SSH depuis Windows..." -ForegroundColor Yellow
$publicKey = Get-Content "$sshKeyPath.pub"
multipass exec dev-server -- bash -c "echo '$publicKey' >> ~/.ssh/authorized_keys"
Write-Host "✓ Clé SSH ajoutée à l'instance" -ForegroundColor Green

# Afficher le résumé
Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "✓ INSTALLATION TERMINÉE!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "Informations importantes:" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Cyan
Write-Host "IP de l'instance: $ip" -ForegroundColor White
Write-Host "URL du serveur: http://$ip" -ForegroundColor White
Write-Host ""
Write-Host "Commandes utiles:" -ForegroundColor Cyan
Write-Host "  Se connecter: multipass shell dev-server" -ForegroundColor Gray
Write-Host "  SSH direct: ssh ubuntu@$ip" -ForegroundColor Gray
Write-Host "  Arrêter: multipass stop dev-server" -ForegroundColor Gray
Write-Host "  Redémarrer: multipass restart dev-server" -ForegroundColor Gray
Write-Host ""
Write-Host "Configuration VSCode SSH:" -ForegroundColor Cyan
Write-Host "  Host: ubuntu@$ip" -ForegroundColor Gray
Write-Host ""
Write-Host "IMPORTANT: Clé SSH pour GitLab" -ForegroundColor Yellow
Write-Host "------------------------------" -ForegroundColor Yellow
Write-Host "Pour obtenir la clé publique à ajouter sur GitLab:" -ForegroundColor Yellow
Write-Host "  multipass exec dev-server -- cat ~/.ssh/id_ed25519.pub" -ForegroundColor White
Write-Host ""
Write-Host "Testez votre serveur: http://$ip" -ForegroundColor Cyan
Write-Host ""

# Ouvrir le navigateur
$response = Read-Host "Ouvrir le navigateur maintenant? (o/N)"
if ($response -eq "o" -or $response -eq "O") {
    Start-Process "http://$ip"
}

Write-Host ""
Write-Host "Appuyez sur une touche pour terminer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")