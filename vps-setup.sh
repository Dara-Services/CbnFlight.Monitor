#!/bin/bash

# Script de configuración automática para VPS
# UptimeFlare Deployment Script
# Uso: bash vps-setup.sh

set -e

echo "================================================"
echo "  UptimeFlare VPS Setup Script"
echo "================================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si estamos en Ubuntu/Debian
if ! [ -f /etc/debian_version ]; then
    print_error "Este script solo funciona en sistemas Debian/Ubuntu"
    exit 1
fi

print_info "Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar Node.js 18
print_info "Instalando Node.js 18..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
else
    print_info "Node.js ya está instalado ($(node -v))"
fi

# Instalar PM2
print_info "Instalando PM2..."
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
else
    print_info "PM2 ya está instalado"
fi

# Instalar Nginx
print_info "Instalando Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo apt install -y nginx
else
    print_info "Nginx ya está instalado"
fi

# Preguntar qué opción de despliegue
echo ""
echo "Selecciona el tipo de despliegue:"
echo "1) Híbrido (Frontend en VPS + Cloudflare Workers)"
echo "2) Completo en VPS (con Redis)"
echo "3) Docker (Recomendado para producción)"
read -p "Opción [1-3]: " deployment_option

case $deployment_option in
    1)
        print_info "Configuración híbrida seleccionada"

        # Instalar Wrangler para Cloudflare
        print_info "Instalando Wrangler CLI..."
        npm install -g wrangler

        print_warning "Necesitarás configurar Cloudflare Workers manualmente"
        print_warning "Ejecuta: wrangler login"
        ;;
    2)
        print_info "Configuración completa en VPS seleccionada"

        # Instalar Redis
        print_info "Instalando Redis..."
        sudo apt install -y redis-server
        sudo systemctl enable redis-server
        sudo systemctl start redis-server

        print_info "Verificando Redis..."
        if redis-cli ping | grep -q "PONG"; then
            print_info "Redis funcionando correctamente"
        else
            print_error "Redis no responde"
        fi

        # Instalar dependencias adicionales
        print_info "Instalando dependencias adicionales..."
        npm install redis ioredis node-cron
        ;;
    3)
        print_info "Configuración con Docker seleccionada"

        # Instalar Docker
        print_info "Instalando Docker..."
        if ! command -v docker &> /dev/null; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            rm get-docker.sh
        else
            print_info "Docker ya está instalado"
        fi

        # Instalar Docker Compose
        print_info "Instalando Docker Compose..."
        if ! command -v docker-compose &> /dev/null; then
            sudo apt install -y docker-compose
        else
            print_info "Docker Compose ya está instalado"
        fi

        # Agregar usuario actual al grupo docker
        print_info "Agregando usuario al grupo docker..."
        sudo usermod -aG docker $USER
        print_warning "Necesitarás cerrar sesión y volver a entrar para usar Docker sin sudo"
        ;;
    *)
        print_error "Opción inválida"
        exit 1
        ;;
esac

# Crear directorio de la aplicación
APP_DIR="/var/www/uptimeflare"
print_info "Creando directorio de aplicación: $APP_DIR"
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Preguntar por el dominio
echo ""
read -p "Ingresa tu dominio (ej: status.daramex.com): " domain

if [ ! -z "$domain" ]; then
    print_info "Configurando Nginx para dominio: $domain"

    # Crear configuración de Nginx
    sudo tee /etc/nginx/sites-available/uptimeflare > /dev/null <<EOF
server {
    listen 80;
    server_name $domain;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Habilitar el sitio
    sudo ln -sf /etc/nginx/sites-available/uptimeflare /etc/nginx/sites-enabled/

    # Probar configuración
    if sudo nginx -t; then
        print_info "Configuración de Nginx válida"
        sudo systemctl reload nginx
    else
        print_error "Error en la configuración de Nginx"
    fi

    # Preguntar si instalar SSL
    read -p "¿Deseas instalar certificado SSL con Let's Encrypt? (s/n): " install_ssl
    if [ "$install_ssl" == "s" ]; then
        print_info "Instalando Certbot..."
        sudo apt install -y certbot python3-certbot-nginx

        print_info "Obteniendo certificado SSL..."
        sudo certbot --nginx -d $domain --non-interactive --agree-tos --register-unsafely-without-email || print_warning "Certbot falló, configúralo manualmente"
    fi
fi

# Configurar firewall
print_info "Configurando firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw --force enable
    print_info "Firewall configurado"
fi

echo ""
print_info "================================================"
print_info "  Instalación completada!"
print_info "================================================"
echo ""
print_info "Próximos pasos:"
echo ""

if [ $deployment_option -eq 1 ]; then
    echo "1. Copia tu proyecto a: $APP_DIR"
    echo "2. cd $APP_DIR && npm install"
    echo "3. Configura Cloudflare Workers: cd worker && wrangler login && wrangler deploy"
    echo "4. Construye el frontend: npm run build"
    echo "5. Inicia con PM2: pm2 start ecosystem.config.js"
elif [ $deployment_option -eq 2 ]; then
    echo "1. Copia tu proyecto a: $APP_DIR"
    echo "2. cd $APP_DIR && npm install"
    echo "3. Configura Redis en .env.local"
    echo "4. Construye: npm run build"
    echo "5. Inicia: pm2 start ecosystem.config.js"
elif [ $deployment_option -eq 3 ]; then
    echo "1. Copia tu proyecto a: $APP_DIR"
    echo "2. cd $APP_DIR"
    echo "3. Crea archivos Dockerfile y docker-compose.yml"
    echo "4. Ejecuta: docker-compose up -d"
fi

echo ""
print_info "Visita: http://$domain (o http://$(hostname -I | awk '{print $1}')"
echo ""

