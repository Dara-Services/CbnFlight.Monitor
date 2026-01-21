#!/bin/bash

# Script de inicio rápido con Docker
# UptimeFlare Docker Quick Start

set -e

echo "================================================"
echo "  UptimeFlare Docker Quick Start"
echo "================================================"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado. Instalando..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    print_info "Docker instalado. Reinicia tu terminal y vuelve a ejecutar este script."
    exit 0
fi

# Verificar Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose no está instalado"
    print_info "Instalando Docker Compose..."
    sudo apt install -y docker-compose || sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Verificar si existe .env
if [ ! -f .env ]; then
    print_warning "Archivo .env no encontrado. Creando desde .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        print_info "Archivo .env creado. Por favor, edítalo con tus configuraciones."
        read -p "¿Deseas editarlo ahora? (s/n): " edit_env
        if [ "$edit_env" == "s" ]; then
            ${EDITOR:-nano} .env
        fi
    else
        print_error "No se encontró .env.example"
        exit 1
    fi
fi

# Preguntar dominio
read -p "Ingresa tu dominio (deja en blanco para localhost): " domain
if [ ! -z "$domain" ]; then
    # Actualizar configuración de nginx
    if [ -f nginx/nginx.conf ]; then
        sed -i "s/server_name _;/server_name $domain;/" nginx/nginx.conf
        print_info "Dominio configurado en Nginx: $domain"
    fi
fi

# Mostrar menú
echo ""
echo "Selecciona una acción:"
echo "1) Iniciar servicios (primera vez o después de cambios)"
echo "2) Detener servicios"
echo "3) Ver logs"
echo "4) Reiniciar servicios"
echo "5) Ver estado de contenedores"
echo "6) Limpiar todo (CUIDADO: elimina volúmenes)"
read -p "Opción [1-6]: " action

case $action in
    1)
        print_info "Construyendo e iniciando servicios..."
        docker-compose down
        docker-compose build
        docker-compose up -d

        print_info "Esperando que los servicios estén listos..."
        sleep 10

        # Verificar estado
        docker-compose ps

        echo ""
        print_info "================================================"
        print_info "  Servicios iniciados correctamente!"
        print_info "================================================"
        echo ""
        if [ ! -z "$domain" ]; then
            print_info "Accede a: http://$domain"
        else
            local_ip=$(hostname -I | awk '{print $1}')
            print_info "Accede a: http://localhost o http://$local_ip"
        fi
        echo ""
        print_info "Para ver logs: docker-compose logs -f"
        print_info "Para detener: docker-compose down"
        ;;
    2)
        print_info "Deteniendo servicios..."
        docker-compose down
        print_info "Servicios detenidos"
        ;;
    3)
        print_info "Mostrando logs (Ctrl+C para salir)..."
        docker-compose logs -f
        ;;
    4)
        print_info "Reiniciando servicios..."
        docker-compose restart
        print_info "Servicios reiniciados"
        ;;
    5)
        print_info "Estado de contenedores:"
        docker-compose ps
        echo ""
        print_info "Uso de recursos:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
        ;;
    6)
        print_warning "ADVERTENCIA: Esto eliminará TODOS los datos en los volúmenes"
        read -p "¿Estás seguro? (escribe 'yes' para confirmar): " confirm
        if [ "$confirm" == "yes" ]; then
            print_info "Eliminando servicios y volúmenes..."
            docker-compose down -v
            docker system prune -f
            print_info "Limpieza completada"
        else
            print_info "Cancelado"
        fi
        ;;
    *)
        print_error "Opción inválida"
        exit 1
        ;;
esac

echo ""

