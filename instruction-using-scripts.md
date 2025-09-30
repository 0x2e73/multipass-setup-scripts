# Instructions d'utilisation des scripts d'installation

## Pour Windows

### Étape 1: Télécharger le script
1. Copie le contenu du script PowerShell dans un fichier
2. Nomme-le `setup-windows.ps1`
3. Sauvegarde-le sur ton Bureau ou dans un dossier facile d'accès

### Étape 2: Autoriser l'exécution de scripts PowerShell
Ouvre PowerShell **en tant qu'administrateur** et exécute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Étape 3: Exécuter le script
**Méthode 1 (recommandée):**
- Clic droit sur `setup-windows.ps1`
- Sélectionne "Exécuter avec PowerShell"

**Méthode 2:**
```powershell
cd chemin\vers\le\script
.\setup-windows.ps1
```

### Étape 4: Suivre les instructions
- Entre ton email quand demandé
- Patiente 5-10 minutes pendant l'installation
- Note l'adresse IP affichée à la fin

---

## Pour macOS

### Étape 1: Télécharger le script
1. Copie le contenu du script bash dans un fichier
2. Nomme-le `setup-macos.sh`
3. Sauvegarde-le dans ton dossier Home ou Downloads

### Étape 2: Rendre le script exécutable
Ouvre le Terminal et exécute:
```bash
cd ~/Downloads  # ou le dossier où tu as sauvegardé le script
chmod +x setup-macos.sh
```

### Étape 3: Exécuter le script
```bash
./setup-macos.sh
```

### Étape 4: Suivre les instructions
- Entre ton email quand demandé
- Patiente 5-10 minutes pendant l'installation
- Note l'adresse IP affichée à la fin

---

## Après l'installation (Windows et macOS)

### 1. Récupérer la clé SSH pour GitLab
```bash
multipass exec dev-server -- cat ~/.ssh/id_ed25519.pub
```

Copie cette clé et ajoute-la dans GitLab:
- Va sur gitlab.ictge.ch
- Settings > SSH Keys
- Colle la clé et sauvegarde

### 2. Tester la connexion GitLab
```bash
multipass shell dev-server
ssh -T git@gitlab.ictge.ch
```

Tu devrais voir: "Welcome to GitLab, @username!"

### 3. Configurer VSCode
1. Ouvre VSCode
2. Installe l'extension "Remote-SSH"
3. Ctrl/Cmd + Shift + P
4. "Remote-SSH: Connect to Host"
5. Entre: `ubuntu@ADRESSE_IP`
6. Connecte-toi

### 4. Tester ton serveur
Ouvre un navigateur et va à: `http://ADRESSE_IP`

Tu devrais voir la page phpinfo().

---

## Commandes utiles après installation

### Gestion de l'instance
```bash
# Se connecter
multipass shell dev-server

# Arrêter
multipass stop dev-server

# Démarrer
multipass start dev-server

# Redémarrer
multipass restart dev-server

# Voir les infos (dont l'IP)
multipass info dev-server
```

### Accès direct SSH
```bash
ssh ubuntu@ADRESSE_IP
```

### Transférer des fichiers
```bash
# Vers l'instance
multipass transfer fichier.txt dev-server:/home/ubuntu/

# Depuis l'instance
multipass transfer dev-server:/home/ubuntu/fichier.txt ~/
```

---

## Résolution de problèmes

### Le script échoue lors de la création de l'instance
**Solution:**
```bash
# Supprimer l'instance en échec
multipass delete dev-server
multipass purge

# Relancer le script
```

### L'IP change après un redémarrage
**Normal!** Récupère la nouvelle IP avec:
```bash
multipass info dev-server
```

Puis mets à jour ta config VSCode SSH.

### Le script se bloque pendant l'installation
**Solution:**
- Attends 2-3 minutes
- Si toujours bloqué, Ctrl+C
- Supprimer l'instance et relancer:
```bash
multipass delete dev-server
multipass purge
# Relancer le script
```

### Apache ne démarre pas
```bash
multipass shell dev-server
sudo systemctl status apache2
sudo systemctl restart apache2
```

### PHP ne fonctionne pas
```bash
multipass shell dev-server
php -v
sudo a2enmod php8.3
sudo systemctl restart apache2
```

---

## Pour désinstaller complètement

### Supprimer l'instance
```bash
multipass delete dev-server
multipass purge
```

### Supprimer Multipass

**Windows:**
- Panneau de configuration > Programmes > Désinstaller Multipass

**macOS:**
```bash
brew uninstall multipass
```

---

## Notes importantes pour l'examen

1. **L'IP peut changer** après un redémarrage de l'instance ou de ton PC
   - Toujours vérifier avec `multipass info dev-server`

2. **La doc complète** est dans le premier artifact
   - Imprime-la ou garde-la ouverte pendant l'examen

3. **Commandes de diagnostic rapide:**
```bash
# Dans l'instance
sudo systemctl status apache2
php -v
php -m
sudo tail -f /var/log/apache2/error.log
```

4. **Backup avant l'examen:**
```bash
multipass exec dev-server -- tar -czf /tmp/backup.tar.gz /var/www/html
multipass transfer dev-server:/tmp/backup.tar.gz ~/backup-exam.tar.gz
```

5. **Si tout plante le jour de l'examen:**
   - Tu peux relancer le script en 5 minutes
   - Ou suivre la doc manuelle

---

## Checklist avant l'examen

- [ ] Instance dev-server fonctionne
- [ ] Apache répond sur http://ADRESSE_IP
- [ ] PHP fonctionne (phpinfo() visible)
- [ ] Clé SSH GitLab ajoutée et testée
- [ ] VSCode Remote-SSH configuré
- [ ] Doc complète imprimée ou accessible
- [ ] Tu connais l'IP de l'instance
- [ ] Tu sais récupérer l'IP si elle change

Bon courage pour ton examen!