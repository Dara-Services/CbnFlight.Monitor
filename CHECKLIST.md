# ✅ CHECKLIST DE DESPLIEGUE - CbnFlight Monitor

## 📋 ANTES DE HACER PUSH

### 1. Configurar Secrets en GitHub

Ir a: `https://github.com/TU_USUARIO/TU_REPO/settings/secrets/actions`

- [ ] **CLOUDFLARE_API_TOKEN** configurado
  - Crear en: https://dash.cloudflare.com/profile/api-tokens
  - Permisos necesarios:
    - ✅ Account > Cloudflare Pages: Edit
    - ✅ Account > Cloudflare Workers Scripts: Edit
    - ✅ Account > D1: Edit
    - ✅ Account > Account Settings: Read

- [ ] **CLOUDFLARE_ACCOUNT_ID** (opcional - se detecta automáticamente)

---

## 🚀 HACER PUSH

```bash
cd "/Users/jch/Documents/[01]Jobs/[01]Dara/[03] CbnFlight/CbnFlight.Monitor"

# Verificar cambios
git status

# Agregar todos los cambios
git add .

# Commit
git commit -m "Deploy CbnFlight Monitor - Configured for automatic deployment"

# Push a main (esto iniciará el despliegue automático)
git push origin main
```

---

## ⏰ MONITOREAR DESPLIEGUE (3-5 minutos)

- [ ] Ir a: `https://github.com/TU_USUARIO/TU_REPO/actions`
- [ ] Ver workflow: "Deploy to Cloudflare"
- [ ] Esperar a que termine (círculo verde ✅)

### Pasos que verás:
1. ✅ Setup Terraform
2. ✅ Setup Node.js
3. ✅ Fetch Account ID
4. ✅ Install packages
5. ✅ Build worker
6. ✅ Build page
7. ✅ Install Python dependencies
8. ✅ Create D1 database and tables
9. ✅ Migrate state from KV (si aplica)
10. ✅ Deploy using Terraform
11. ✅ Upload pages

---

## 🔍 VERIFICAR EN CLOUDFLARE

Ir a: `https://dash.cloudflare.com/`

### Workers & Pages

- [ ] **Worker:** `uptimeflare_worker-cbnflight`
  - Status: ✅ Active
  - Cron: ✅ * * * * * (cada minuto)
  - Bindings: ✅ UPTIMEFLARE_STATE (D1)

- [ ] **Pages:** `uptimeflare-cbnflight`
  - Status: ✅ Deployed
  - URL: https://uptimeflare-cbnflight.pages.dev
  - Bindings: ✅ UPTIMEFLARE_STATE (D1)

### D1 Database

- [ ] **Database:** `uptimeflare_d1-cbnflight`
  - Tablas: 
    - ✅ monitor_status
    - ✅ monitor_history
    - ✅ incidents

---

## 🌐 VERIFICAR STATUS PAGE

- [ ] Abrir: https://uptimeflare-cbnflight.pages.dev
- [ ] Esperar 2-3 minutos para el primer check
- [ ] Verificar que aparecen los 9 monitores:
  1. Identity Service
  2. Payment Service
  3. CRM Service
  4. Notifications Service
  5. RealEstate Service
  6. Shops Service
  7. FileGateway Service
  8. RabbitMQ Management API
  9. Python FreePBX Extension Server

- [ ] Verificar que se muestran los estados (verde/rojo/amarillo)
- [ ] Verificar que funcionan los gráficos de latencia

---

## 🎉 POST-DESPLIEGUE

### Opcional: Dominio Personalizado

Si quieres usar: `status.cbnflight.com`

- [ ] Ir a Pages project en Cloudflare
- [ ] Click "Custom domains"
- [ ] Add: `status.cbnflight.com`
- [ ] Agregar CNAME en DNS de cbnflight.com
- [ ] Esperar propagación

### Configurar Notificaciones (Opcional)

Editar `uptime.config.ts` para agregar webhook o notificaciones.

---

## 🐛 TROUBLESHOOTING

### ❌ Si GitHub Actions falla:

1. **Error: "CLOUDFLARE_API_TOKEN not set"**
   - [ ] Verificar que el secret está configurado en GitHub
   - [ ] Verificar el nombre exacto: `CLOUDFLARE_API_TOKEN`

2. **Error: "Permission denied"**
   - [ ] Verificar permisos del API token
   - [ ] Recrear el token con todos los permisos necesarios

3. **Warning: "import failed"**
   - [ ] ✅ NORMAL en primer despliegue
   - [ ] El workflow continúa y crea los recursos

### ⏰ Si no aparecen datos en la página:

- [ ] Esperar 2-3 minutos más
- [ ] Verificar logs del worker en Cloudflare
- [ ] Verificar que el cron trigger está activo
- [ ] Verificar que los endpoints en `uptime.config.ts` son accesibles

### 🔍 Revisar Logs:

- [ ] GitHub Actions: Tab "Actions" en el repo
- [ ] Worker logs: Cloudflare Dashboard > Worker > Logs
- [ ] Pages logs: Cloudflare Dashboard > Pages > Logs

---

## 📊 RECURSOS CONFIRMADOS

| Recurso | Nombre | Estado |
|---------|--------|--------|
| Worker | uptimeflare_worker-cbnflight | ⏳ Pendiente |
| Pages | uptimeflare-cbnflight | ⏳ Pendiente |
| D1 Database | uptimeflare_d1-cbnflight | ⏳ Pendiente |
| Cron Trigger | * * * * * | ⏳ Pendiente |

**Después del push, marca como ✅ cuando cada recurso esté activo.**

---

## ✅ CHECKLIST FINAL

- [ ] Secrets configurados en GitHub
- [ ] Push realizado a main
- [ ] GitHub Actions completado exitosamente
- [ ] Worker aparece en Cloudflare
- [ ] Pages desplegado
- [ ] D1 Database creada con tablas
- [ ] Status page accesible
- [ ] Monitores funcionando
- [ ] (Opcional) Dominio personalizado configurado

---

## 🔄 ACTUALIZACIONES FUTURAS

Cada vez que quieras actualizar:

```bash
# 1. Editar archivos (uptime.config.ts, etc.)
nano uptime.config.ts

# 2. Git add, commit, push
git add .
git commit -m "Update configuration"
git push origin main

# 3. ¡GitHub Actions se encarga del resto! 🚀
```

---

## 📝 NOTAS

- ✅ Nombres con sufijo `-cbnflight` evitan conflictos
- ✅ Tu otro worker NO se afecta
- ✅ Despliegue 100% automático
- ✅ No requiere herramientas locales
- ✅ Free tier de Cloudflare ($0/mes)
- ✅ Checks cada 1 minuto
- ✅ Historial de 90 días

---

## 🎯 SIGUIENTE PASO

**¿Ya configuraste CLOUDFLARE_API_TOKEN en GitHub?**

- ✅ **SÍ** → Ejecuta los comandos git arriba
- ❌ **NO** → Ve al Paso 1 primero

---

**Fecha de configuración:** $(date)
**Versión:** v1.0
**Status:** ✅ Listo para desplegar

---

💡 **Tip:** Guarda este archivo para futuras referencias.
📖 **Documentación completa:** Ver `DEPLOYMENT_STEPS.md`
🔍 **Verificar config:** Ejecutar `./check-deploy.sh`

