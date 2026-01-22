#!/bin/bash
# Script para verificar la configuración antes del despliegue

echo "🔍 Verificando configuración de CbnFlight Monitor..."
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

# Verificar archivos necesarios
echo "📁 Verificando archivos necesarios..."
files=(
    "deploy.tf"
    "uptime.config.ts"
    "worker/wrangler.toml"
    ".github/workflows/deploy.yml"
    "deploy/init_d1.py"
    "deploy/migrate_kv.py"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file - FALTANTE"
        ((errors++))
    fi
done
echo ""

# Verificar configuración de nombres
echo "🏷️  Verificando nombres de recursos..."

# Check deploy.tf
if grep -q "uptimeflare_worker-cbnflight" deploy.tf; then
    echo -e "  ${GREEN}✓${NC} Worker name: uptimeflare_worker-cbnflight"
else
    echo -e "  ${RED}✗${NC} Worker name incorrecto en deploy.tf"
    ((errors++))
fi

if grep -q "uptimeflare-cbnflight" deploy.tf | grep -q "pages_project"; then
    echo -e "  ${GREEN}✓${NC} Pages name: uptimeflare-cbnflight"
else
    echo -e "  ${YELLOW}⚠${NC} Pages name podría estar incorrecto"
    ((warnings++))
fi

if grep -q "uptimeflare_d1-cbnflight" deploy.tf; then
    echo -e "  ${GREEN}✓${NC} D1 database name: uptimeflare_d1-cbnflight"
else
    echo -e "  ${RED}✗${NC} D1 database name incorrecto en deploy.tf"
    ((errors++))
fi

# Check wrangler.toml
if grep -q "uptimeflare_worker-cbnflight" worker/wrangler.toml; then
    echo -e "  ${GREEN}✓${NC} Wrangler config name: uptimeflare_worker-cbnflight"
else
    echo -e "  ${RED}✗${NC} Wrangler config name incorrecto"
    ((errors++))
fi

echo ""

# Verificar configuración de uptime
echo "⚙️  Verificando uptime.config.ts..."
if [ -f "uptime.config.ts" ]; then
    monitor_count=$(grep -c "id:" uptime.config.ts || echo "0")
    echo -e "  ${GREEN}✓${NC} Encontrados $monitor_count monitores configurados"

    if grep -q "pageConfig" uptime.config.ts && grep -q "workerConfig" uptime.config.ts; then
        echo -e "  ${GREEN}✓${NC} Configuración de page y worker presente"
    else
        echo -e "  ${YELLOW}⚠${NC} Configuración podría estar incompleta"
        ((warnings++))
    fi
else
    echo -e "  ${RED}✗${NC} uptime.config.ts no encontrado"
    ((errors++))
fi

echo ""

# Verificar .gitignore
echo "🚫 Verificando .gitignore..."
if [ -f ".gitignore" ]; then
    if grep -q "node_modules" .gitignore && grep -q ".env" .gitignore; then
        echo -e "  ${GREEN}✓${NC} .gitignore configurado correctamente"
    else
        echo -e "  ${YELLOW}⚠${NC} .gitignore podría necesitar actualizaciones"
        ((warnings++))
    fi
else
    echo -e "  ${YELLOW}⚠${NC} .gitignore no encontrado"
    ((warnings++))
fi

echo ""

# Check GitHub Actions workflow
echo "🔄 Verificando GitHub Actions workflow..."
if grep -q "CLOUDFLARE_API_TOKEN" .github/workflows/deploy.yml; then
    echo -e "  ${GREEN}✓${NC} Workflow usa CLOUDFLARE_API_TOKEN"
else
    echo -e "  ${RED}✗${NC} CLOUDFLARE_API_TOKEN no configurado en workflow"
    ((errors++))
fi

if grep -q "pip3 install requests" .github/workflows/deploy.yml; then
    echo -e "  ${GREEN}✓${NC} Python dependencies instaladas en workflow"
else
    echo -e "  ${RED}✗${NC} Python dependencies faltantes en workflow"
    ((errors++))
fi

if grep -q "uptimeflare-cbnflight" .github/workflows/deploy.yml; then
    echo -e "  ${GREEN}✓${NC} Nombres actualizados en workflow"
else
    echo -e "  ${YELLOW}⚠${NC} Nombres podrían no coincidir en workflow"
    ((warnings++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Resumen
if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "${GREEN}✅ ¡Todo listo para desplegar!${NC}"
    echo ""
    echo "Siguiente paso:"
    echo "  git add ."
    echo "  git commit -m 'Deploy CbnFlight Monitor'"
    echo "  git push origin main"
    echo ""
    echo "Asegúrate de haber configurado los secrets en GitHub:"
    echo "  - CLOUDFLARE_API_TOKEN (requerido)"
    echo "  - CLOUDFLARE_ACCOUNT_ID (opcional)"
    echo ""
    exit 0
elif [ $errors -eq 0 ]; then
    echo -e "${YELLOW}⚠ Hay $warnings advertencias pero puedes continuar${NC}"
    echo ""
    echo "Revisa las advertencias arriba antes de desplegar."
    echo ""
    exit 0
else
    echo -e "${RED}❌ Hay $errors errores que deben corregirse${NC}"
    echo ""
    echo "Por favor corrige los errores antes de desplegar."
    echo ""
    exit 1
fi

