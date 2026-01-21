# 🚀 Guía Rápida de Despliegue en VPS

## 📌 Resumen Ejecutivo

Este documento te guiará para desplegar UptimeFlare en un VPS en **menos de 30 minutos**.

### ¿Qué necesitas?
- ✅ Un VPS con Ubuntu 20.04+ (1GB RAM mínimo)
- ✅ Acceso SSH root o sudo
- ✅ Un dominio apuntando a tu VPS (opcional pero recomendado)

---

## 🎯 Método 1: Despliegue Automático (Recomendado)

### Paso 1: Conecta a tu VPS

```bash
ssh root@tu-vps-ip
```

### Paso 2: Descarga el proyecto

```bash
cd /tmp
# Opción A: Si tienes el proyecto en Git
git clone https://github.com/tu-usuario/uptimeflare.git /var/www/uptimeflare

# Opción B: Si lo subes manualmente
scp -r /ruta/local/uptimeflare root@tu-vps-ip:/var/www/
```

### Paso 3: Ejecuta el script de instalación

```bash
cd /var/www/uptimeflare
chmod +x vps-setup.sh
./vps-setup.sh
```

El script te preguntará:
1. ¿Qué tipo de despliegue quieres? (híbrido, completo, o docker)
2. ¿Cuál es tu dominio?
3. ¿Quieres SSL?

¡Y listo! El script configurará todo automáticamente.

### Paso 4: Inicia la aplicación

**Si elegiste opción híbrida (1):**
```bash
cd /var/www/uptimeflare
npm install
npm run build
pm2 start ecosystem.config.js
pm2 save
```

**Si elegiste Docker (3):**
```bash
cd /var/www/uptimeflare
chmod +x docker-start.sh
./docker-start.sh
# Selecciona opción 1 para iniciar
```

---

## 🐳 Método 2: Despliegue con Docker (Más Simple)

### Instalación en 5 comandos

```bash
# 1. Clonar proyecto
git clone tu-repo /var/www/uptimeflare
cd /var/www/uptimeflare

# 2. Configurar variables
cp .env.example .env
nano .env  # Edita según tus necesidades

# 3. Dar permisos y ejecutar
chmod +x docker-start.sh
./docker-start.sh

# 4. Selecciona opción 1 (Iniciar servicios)
```

¡Listo! Tu aplicación estará corriendo en http://tu-ip

### Comandos útiles de Docker

```bash
# Ver logs
docker-compose logs -f

# Reiniciar
docker-compose restart

# Detener
docker-compose down

# Ver estado
docker-compose ps
```

---

## ⚡ Método 3: Manual con PM2

### Para quienes prefieren control total

```bash
# 1. Instalar dependencias del sistema
sudo apt update
sudo apt install -y nodejs npm nginx redis-server
sudo npm install -g pm2

# 2. Preparar aplicación
cd /var/www/uptimeflare
npm install
npm run build

# 3. Configurar Redis (si usas opción auto-hospedada)
sudo systemctl start redis-server
sudo systemctl enable redis-server

# 4. Iniciar con PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# 5. Configurar Nginx
sudo cp nginx/nginx.conf /etc/nginx/sites-available/uptimeflare
sudo ln -s /etc/nginx/sites-available/uptimeflare /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# 6. SSL con Let's Encrypt
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d tu-dominio.com
```

---

## 🔧 Configuración de uptime.config.ts

Edita el archivo `uptime.config.ts` para configurar tus monitores:

```typescript
const workerConfig = {
    kvWriteCooldownMinutes: 3,
    monitors: [
        {
            id: 'mi_servicio',
            name: 'Mi Servicio',
            method: 'GET',
            target: 'https://mi-api.com/health',
            expectedCodes: [200],
            timeout: 10000,
        },
        // ... más monitores
    ],
}
```

---

## 📊 Verificación Post-Despliegue

### 1. Verifica que los servicios estén corriendo

**Con PM2:**
```bash
pm2 status
pm2 logs uptimeflare-web
```

**Con Docker:**
```bash
docker-compose ps
docker-compose logs
```

### 2. Prueba el endpoint de estado

```bash
curl http://localhost:3000/api/data
```

Deberías ver un JSON con el estado de tus monitores.

### 3. Verifica Nginx

```bash
sudo nginx -t
curl http://tu-dominio.com
```

### 4. Verifica SSL (si configuraste)

```bash
curl https://tu-dominio.com
```

---

## 🐛 Troubleshooting Rápido

### Problema: "Puerto 3000 ya en uso"
```bash
# Encontrar proceso
sudo lsof -i :3000
# Matar proceso
sudo kill -9 PID
```

### Problema: "Redis connection refused"
```bash
# Verificar Redis
redis-cli ping
# Si no responde, reiniciar
sudo systemctl restart redis-server
```

### Problema: "502 Bad Gateway en Nginx"
```bash
# Verificar que la app esté corriendo
pm2 status
# Ver logs de Nginx
sudo tail -f /var/log/nginx/error.log
```

### Problema: "Cannot find module"
```bash
# Reinstalar dependencias
cd /var/www/uptimeflare
rm -rf node_modules
npm install
npm run build
pm2 restart all
```

---

## 🔒 Seguridad Básica

### 1. Configurar Firewall

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 2. Cambiar puerto SSH (recomendado)

```bash
sudo nano /etc/ssh/sshd_config
# Cambia Port 22 a Port 2222
sudo systemctl restart sshd
```

### 3. Deshabilitar login root

```bash
sudo nano /etc/ssh/sshd_config
# PermitRootLogin no
sudo systemctl restart sshd
```

### 4. Actualizar automáticamente

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

---

## 📈 Monitoreo y Mantenimiento

### Ver uso de recursos

```bash
# CPU y RAM
htop

# Espacio en disco
df -h

# Logs de la aplicación
pm2 logs

# Docker
docker stats
```

### Backup automático

```bash
# Crear script de backup
sudo nano /usr/local/bin/backup-uptimeflare.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backups/uptimeflare"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup de configuración
cp /var/www/uptimeflare/uptime.config.ts $BACKUP_DIR/uptime.config.ts.$DATE

# Backup de Redis (si usas)
redis-cli save
cp /var/lib/redis/dump.rdb $BACKUP_DIR/redis.$DATE.rdb

# Mantener solo últimos 7 días
find $BACKUP_DIR -type f -mtime +7 -delete
```

```bash
sudo chmod +x /usr/local/bin/backup-uptimeflare.sh

# Agregar a cron (diario a las 2am)
sudo crontab -e
# 0 2 * * * /usr/local/bin/backup-uptimeflare.sh
```

---

## 🎓 Próximos Pasos

1. ✅ Configura notificaciones (Discord, Telegram, Email)
2. ✅ Personaliza la interfaz en `uptime.config.ts`
3. ✅ Agrega más monitores
4. ✅ Configura backup automático
5. ✅ Monitorea los logs regularmente

---

## 📞 ¿Necesitas Ayuda?

- 📖 [Documentación completa](VPS_DEPLOYMENT_GUIDE.md)
- 🐛 [Reportar issues](https://github.com/lyc8503/UptimeFlare/issues)
- 💬 [Comunidad](https://github.com/lyc8503/UptimeFlare/discussions)

---

## ⏱️ Tiempo estimado por método

| Método | Tiempo | Dificultad | Recomendado para |
|--------|--------|------------|------------------|
| Automático | 15-30 min | ⭐ Fácil | Principiantes |
| Docker | 10-20 min | ⭐⭐ Media | Todos |
| Manual | 30-60 min | ⭐⭐⭐ Avanzada | Expertos |

---

**¡Felicidades!** 🎉 Tu sistema de monitoreo está listo.

