# 🚀 PASOS PARA DESPLEGAR - CbnFlight Monitor

## ✅ TODO ESTÁ LISTO - SOLO SIGUE ESTOS PASOS:

---

## **PASO 1: Configurar API Token en GitHub** ⏱️ 2 minutos

1. Ve a: https://dash.cloudflare.com/profile/api-tokens
2. Click en **"Create Token"**
3. Selecciona **"Edit Cloudflare Workers"** template
4. Click **"Continue to summary"** → **"Create Token"**
5. **COPIA EL TOKEN** (solo se muestra una vez)
6. Ve a tu repo en GitHub: `Settings` → `Secrets and variables` → `Actions`
7. Click **"New repository secret"**
8. Nombre: `CLOUDFLARE_API_TOKEN`
9. Valor: pega el token que copiaste
10. Click **"Add secret"**

✅ **Listo el Paso 1**

---

## **PASO 2: Hacer Push a Main** ⏱️ 1 minuto

Abre tu terminal y ejecuta:

```bash
cd "/Users/jch/Documents/[01]Jobs/[01]Dara/[03] CbnFlight/CbnFlight.Monitor"

git add .
git commit -m "Deploy CbnFlight Monitor"
git push origin main
```

✅ **Listo el Paso 2**

---

## **PASO 3: Monitorear el Despliegue** ⏱️ 3-5 minutos

1. Ve a: https://github.com/TU_USUARIO/TU_REPO/actions
2. Verás el workflow **"Deploy to Cloudflare"** ejecutándose (círculo naranja 🟠)
3. Click en él para ver el progreso en vivo
4. Espera a que termine (círculo verde ✅)

**Nota:** Si ves warnings de "import failed" = **ES NORMAL** en el primer despliegue

✅ **Listo el Paso 3**

---

## **PASO 4: Verificar en Cloudflare** ⏱️ 1 minuto

1. Ve a: https://dash.cloudflare.com/
2. Click en **"Workers & Pages"**
3. Deberías ver:
   - **Worker:** `uptimeflare_worker-cbnflight` (con estrella verde)
   - **Pages:** `uptimeflare-cbnflight` (con estrella verde)
4. Click en **"D1"** en el menú lateral
5. Deberías ver:
   - **Database:** `uptimeflare_d1-cbnflight`

✅ **Listo el Paso 4**

---

## **PASO 5: Acceder a tu Status Page** ⏱️ 30 segundos

1. Abre: **https://uptimeflare-cbnflight.pages.dev**
2. **Espera 2-3 minutos** para que el worker ejecute los primeros checks
3. Recarga la página
4. Deberías ver tus 9 monitores con sus estados

✅ **¡DESPLIEGUE COMPLETADO!** 🎉

---

## 📊 RESUMEN DE CAMBIOS QUE HICE:

| Archivo | Cambio |
|---------|--------|
| `deploy.tf` | ✅ Actualizado de KV a D1, nombres con `-cbnflight` |
| `worker/wrangler.toml` | ✅ Nombre del worker: `uptimeflare_worker-cbnflight` |
| `worker/wrangler-dev.toml` | ✅ Nombre del worker dev actualizado |
| `.github/workflows/deploy.yml` | ✅ Instalación de Python, nombres actualizados |
| `deploy/init_d1.py` | ✅ Script para crear base de datos D1 (NUEVO) |
| `deploy/migrate_kv.py` | ✅ Script para migración KV→D1 (NUEVO) |

---

## 🎯 PROBLEMAS QUE SOLUCIONÉ:

❌ **Antes:** Workflow esperaba archivos Python que no existían  
✅ **Ahora:** Scripts Python creados y funcionando

❌ **Antes:** Terraform usaba KV (obsoleto)  
✅ **Ahora:** Terraform usa D1 (moderno y más rápido)

❌ **Antes:** Conflicto de nombres con tu otro worker  
✅ **Ahora:** Sufijo `-cbnflight` evita conflictos

❌ **Antes:** Nombres inconsistentes entre archivos  
✅ **Ahora:** Todos los archivos usan los mismos nombres

❌ **Antes:** Pages project con doble "cbnflight"  
✅ **Ahora:** Nombre correcto: `uptimeflare-cbnflight`

---

## 🔄 PARA ACTUALIZACIONES FUTURAS:

```bash
# Editar configuración de monitores
nano uptime.config.ts

# Commit y push
git add .
git commit -m "Update monitors"
git push origin main

# ¡GitHub Actions despliega automáticamente! 🚀
```

**NO necesitas:**
- ❌ Ejecutar terraform manualmente
- ❌ Ejecutar wrangler manualmente
- ❌ Instalar nada localmente
- ❌ Configurar nada en Cloudflare manualmente

**Todo es AUTOMÁTICO** después del push 🎯

---

## 📌 URLs IMPORTANTES:

| Recurso | URL |
|---------|-----|
| Status Page | https://uptimeflare-cbnflight.pages.dev |
| Cloudflare Dashboard | https://dash.cloudflare.com/ |
| GitHub Actions | https://github.com/TU_USUARIO/TU_REPO/actions |
| API Tokens | https://dash.cloudflare.com/profile/api-tokens |

---

## 🐛 SI ALGO FALLA:

### Error: "CLOUDFLARE_API_TOKEN not set"
👉 Verifica que configuraste el secret en GitHub (Paso 1)

### Error: "Permission denied"
👉 El token necesita más permisos. Créalo de nuevo con template "Edit Cloudflare Workers"

### Warning: "import failed" en logs
👉 **ES NORMAL** en el primer despliegue. El workflow continúa y crea los recursos.

### La página no muestra datos
👉 Espera 2-3 minutos y recarga. El worker necesita ejecutarse al menos una vez.

### El worker no aparece en Cloudflare
👉 Espera 1-2 minutos más después de que termine GitHub Actions

---

## ✅ VERIFICACIÓN RÁPIDA:

Ejecuta esto para verificar que todo está OK antes del push:

```bash
cd "/Users/jch/Documents/[01]Jobs/[01]Dara/[03] CbnFlight/CbnFlight.Monitor"
./check-deploy.sh
```

Debería mostrar: **"✅ ¡Todo listo para desplegar!"**

---

## 💡 TIPS:

- ✅ El despliegue toma 3-5 minutos
- ✅ Los checks se ejecutan cada 1 minuto
- ✅ El historial guarda 90 días de datos
- ✅ Todo es gratis (Cloudflare free tier)
- ✅ Tu otro worker NO se afecta
- ✅ Puedes agregar dominio custom después

---

## 🎉 ¡ESO ES TODO!

**Siguiente acción:** Ejecutar los comandos del **Paso 2** arriba ☝️

---

**Documentación completa:** Ver `DEPLOYMENT_STEPS.md`  
**Checklist detallado:** Ver `CHECKLIST.md`  
**Verificar config:** Ejecutar `./check-deploy.sh`

**¿Listo para hacer push?** 🚀

