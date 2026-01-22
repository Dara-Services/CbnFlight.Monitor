# 🚀 Guía de Despliegue - CbnFlight Monitor

## 📋 Pasos para Desplegar (Configuración Única)

### ✅ Requisitos Previos
- ✔️ Cuenta de Cloudflare configurada
- ✔️ Repositorio en GitHub
- ✔️ Los nombres de recursos tienen el sufijo `-cbnflight` para evitar conflictos

---

## 🔧 Paso 1: Configurar Secrets en GitHub

1. Ve a tu repositorio en GitHub
2. Click en **Settings** > **Secrets and variables** > **Actions**
3. Agrega estos secrets (click en **New repository secret**):

   - **CLOUDFLARE_API_TOKEN**
     - Ve a https://dash.cloudflare.com/profile/api-tokens
     - Click en "Create Token"
     - Usa la plantilla "Edit Cloudflare Workers" o crea uno custom con estos permisos:
       - Account > Cloudflare Pages: Edit
       - Account > Cloudflare Workers Scripts: Edit
       - Account > Account Settings: Read
       - Account > D1: Edit
     - Copia el token y pégalo en GitHub
   
   - **CLOUDFLARE_ACCOUNT_ID** (opcional - se detecta automáticamente)
     - Ve a https://dash.cloudflare.com/
     - Selecciona tu cuenta
     - El Account ID está en la URL o en la barra lateral
     - Ejemplo: `1234567890abcdef1234567890abcdef`

---

## 🎯 Paso 2: Hacer Push a Main

Una vez configurados los secrets, simplemente:

```bash
git add .
git commit -m "Deploy CbnFlight Monitor"
git push origin main
```

**¡Y listo!** El workflow de GitHub Actions se encargará automáticamente de:

1. ✅ Instalar dependencias (Node.js + Python)
2. ✅ Compilar el worker de Cloudflare
3. ✅ Compilar la aplicación Next.js
4. ✅ Crear/verificar la base de datos D1
5. ✅ Inicializar las tablas necesarias
6. ✅ Desplegar el worker con Terraform
7. ✅ Configurar el cron trigger (cada 1 minuto)
8. ✅ Desplegar el Pages project
9. ✅ Configurar los bindings de D1

---

## 🔍 Paso 3: Verificar el Despliegue

### Ver el progreso
1. Ve a tu repositorio en GitHub
2. Click en la pestaña **Actions**
3. Verás el workflow "Deploy to Cloudflare" ejecutándose
4. Toma ~3-5 minutos

### Verificar en Cloudflare
Una vez completado, ve a tu dashboard de Cloudflare:

1. **Worker**: https://dash.cloudflare.com/ > Workers & Pages
   - Deberías ver: `uptimeflare_worker-cbnflight`
   - Status: Active
   - Cron trigger: Cada 1 minuto

2. **Pages**: Mismo panel de Workers & Pages
   - Deberías ver: `uptimeflare-cbnflight`
   - Production deployment activo
   - URL: `https://uptimeflare-cbnflight.pages.dev`

3. **D1 Database**: Workers & Pages > D1
   - Deberías ver: `uptimeflare_d1-cbnflight`
   - Con tablas: `monitor_status`, `monitor_history`, `incidents`

---

## 🎉 Paso 4: Acceder a tu Status Page

Tu página estará disponible en:
```
https://uptimeflare-cbnflight.pages.dev
```

### Configurar dominio personalizado (opcional)
1. Ve a tu proyecto de Pages en Cloudflare
2. Click en **Custom domains**
3. Agrega tu dominio (ej: `status.cbnflight.com`)
4. Configura el DNS record CNAME en tu dominio

---

## 🔄 Actualizaciones Futuras

Para cualquier cambio futuro, simplemente:

```bash
# 1. Edita los archivos necesarios (uptime.config.ts, etc.)
git add .
git commit -m "Update monitors configuration"
git push origin main

# 2. El despliegue es AUTOMÁTICO 🎯
```

---

## ⚙️ Configuración de Monitores

Edita el archivo `uptime.config.ts` para agregar/modificar monitores:

```typescript
monitors: [
    {
        id: 'my_service',
        name: 'My Service',
        method: 'GET',
        target: 'https://api.example.com/health',
        expectedCodes: [200],
        timeout: 10000,
    },
    // ... más monitores
]
```

---

## 📊 Recursos Creados

| Recurso | Nombre | Descripción |
|---------|--------|-------------|
| Worker | `uptimeflare_worker-cbnflight` | Ejecuta checks cada minuto |
| Pages | `uptimeflare-cbnflight` | Status page público |
| D1 Database | `uptimeflare_d1-cbnflight` | Base de datos para historial |
| Cron Trigger | `* * * * *` | Ejecuta worker cada minuto |

---

## 🐛 Troubleshooting

### Error: "Worker script import failed"
- **Normal en primer despliegue** - el workflow continúa y crea el recurso nuevo

### Error: "Pages project import failed"
- **Normal en primer despliegue** - el workflow continúa y crea el recurso nuevo

### Error: "D1 database already exists"
- **Está bien** - el script detecta la DB existente y la usa

### El worker no aparece en Cloudflare
1. Verifica que el workflow de GitHub Actions terminó exitosamente
2. Revisa los logs en la pestaña Actions
3. Espera 2-3 minutos después del despliegue

### La página no muestra datos
1. **Espera 1-2 minutos** - el worker necesita ejecutarse al menos una vez
2. Verifica que el cron trigger está activo
3. Revisa los logs del worker en Cloudflare dashboard

---

## 📝 Notas Importantes

✅ **Los nombres tienen sufijo `-cbnflight`** para evitar conflictos con otros servicios
✅ **El despliegue es completamente automático** después del push a main
✅ **No necesitas Terraform local** - GitHub Actions lo ejecuta
✅ **No necesitas Wrangler CLI local** - GitHub Actions lo ejecuta
✅ **La base de datos se crea automáticamente** en el primer despliegue
✅ **Los workers anteriores NO se afectan** - tienen nombres diferentes

---

## 🔐 Seguridad

Para proteger la página con contraseña, edita `uptime.config.ts`:

```typescript
const workerConfig = {
    kvWriteCooldownMinutes: 3,
    passwordProtection: 'username:password',  // Descomenta esta línea
    monitors: [
        // ...
    ]
}
```

---

## 📞 Soporte

Si algo falla:
1. Revisa los logs en GitHub Actions
2. Revisa los logs del worker en Cloudflare
3. Verifica que los secrets están configurados correctamente

---

## ✨ Resumen

```bash
# Primer despliegue:
1. Configurar secrets en GitHub (CLOUDFLARE_API_TOKEN)
2. git push origin main
3. Esperar ~5 minutos
4. ¡Listo! 🎉

# Actualizaciones:
1. git push origin main
2. ¡Listo! 🎯
```

