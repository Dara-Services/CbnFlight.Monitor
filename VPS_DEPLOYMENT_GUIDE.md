# Guía de Despliegue en VPS - UptimeFlare

## 📋 Análisis del Proyecto

**UptimeFlare** es un sistema de monitoreo de uptime y página de estado que originalmente está diseñado para ejecutarse en:
- **Frontend**: Cloudflare Pages (Next.js)
- **Backend Worker**: Cloudflare Workers (cron jobs para monitoreo)
- **Almacenamiento**: Cloudflare KV (key-value store)

### Arquitectura Actual
```
┌─────────────────────┐
│  Next.js Frontend   │ (Cloudflare Pages)
│  - Status Page      │
│  - API Routes       │
└──────────┬──────────┘
           │
           ├─> KV Storage (estado de monitores)
           │
┌──────────▼──────────┐
│  Cloudflare Worker  │
│  - Cron: cada 1 min │
│  - Checks HTTP/TCP  │
│  - Notificaciones   │
└─────────────────────┘
```

## 🎯 Estrategia de Migración a VPS

Para migrar a un VPS necesitamos:

### Opción 1: Despliegue Híbrido (Recomendado)
Mantener Cloudflare Workers (gratis hasta 100k requests/día) y solo hospedar el frontend en VPS.

**Ventajas:**
- ✅ Aprovecha la red global de Cloudflare para monitoreo
- ✅ Menor carga en el VPS
- ✅ Gratis con el plan gratuito de Cloudflare

**Desventajas:**
- ❌ Requiere cuenta de Cloudflare

### Opción 2: Despliegue Completo en VPS (Independiente)
Reemplazar todos los componentes de Cloudflare con alternativas open-source.

**Ventajas:**
- ✅ 100% auto-hospedado
- ✅ Control total
- ✅ No depende de servicios externos

**Desventajas:**
- ❌ Requiere adaptación del código
- ❌ Toda la carga en tu VPS

---

## 🚀 OPCIÓN 1: Despliegue Híbrido (Frontend en VPS)

### Requisitos del VPS
- **SO**: Ubuntu 20.04+ / Debian 11+
- **RAM**: Mínimo 1GB (2GB recomendado)
- **CPU**: 1 vCore
- **Node.js**: v18+
- **Nginx**: Como reverse proxy

### Paso 1: Preparar el VPS

```bash
# Conectar al VPS
ssh user@tu-vps-ip

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Instalar PM2 (gestor de procesos)
sudo npm install -g pm2

# Instalar Nginx
sudo apt install -y nginx

# Instalar Git
sudo apt install -y git
```

### Paso 2: Clonar y configurar el proyecto

```bash
# Crear directorio para la aplicación
sudo mkdir -p /var/www/uptimeflare
sudo chown $USER:$USER /var/www/uptimeflare

# Clonar el proyecto
cd /var/www/uptimeflare
# (o usar git clone si está en un repositorio)

# Instalar dependencias
npm install

# Construir la aplicación
npm run build
```

### Paso 3: Configurar Cloudflare Workers (Backend)

```bash
# Instalar Wrangler CLI
npm install -g wrangler

# Autenticar con Cloudflare
wrangler login

# Crear KV namespace
wrangler kv:namespace create "UPTIMEFLARE_STATE"
# Guarda el ID que te devuelve

# Configurar wrangler.toml en /worker/wrangler.toml
cd /var/www/uptimeflare/worker
```

Edita `wrangler.toml`:
```toml
name = "uptimeflare-worker"
main = "src/index.ts"
compatibility_date = "2023-11-08"

kv_namespaces = [
  { binding = "UPTIMEFLARE_STATE", id = "TU_KV_ID_AQUI" }
]

[triggers]
crons = ["* * * * *"]  # Cada minuto
```

```bash
# Compilar y desplegar el worker
npm install
npm run deploy
```

### Paso 4: Configurar el Frontend para conectar con Cloudflare

Crea un archivo `.env.local`:
```bash
cat > /var/www/uptimeflare/.env.local << EOF
NODE_ENV=production
UPTIMEFLARE_STATE_API=https://api.cloudflare.com/client/v4/accounts/TU_ACCOUNT_ID/storage/kv/namespaces/TU_KV_ID
CLOUDFLARE_API_TOKEN=tu_api_token_aqui
EOF
```

### Paso 5: Configurar PM2

```bash
cd /var/www/uptimeflare

# Crear ecosystem file para PM2
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'uptimeflare',
    script: 'npm',
    args: 'start',
    cwd: '/var/www/uptimeflare',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
}
EOF

# Iniciar la aplicación
pm2 start ecosystem.config.js

# Guardar configuración de PM2
pm2 save

# Configurar PM2 para iniciar al arrancar el sistema
pm2 startup
```

### Paso 6: Configurar Nginx

```bash
# Crear configuración de Nginx
sudo nano /etc/nginx/sites-available/uptimeflare
```

Contenido:
```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Habilitar el sitio
sudo ln -s /etc/nginx/sites-available/uptimeflare /etc/nginx/sites-enabled/

# Probar configuración
sudo nginx -t

# Recargar Nginx
sudo systemctl reload nginx
```

### Paso 7: Configurar SSL con Let's Encrypt

```bash
# Instalar Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtener certificado SSL
sudo certbot --nginx -d tu-dominio.com

# Renovación automática (ya está configurada por defecto)
sudo certbot renew --dry-run
```

---

## 🏠 OPCIÓN 2: Despliegue Completo en VPS

Esta opción requiere modificar el código para reemplazar Cloudflare KV con una base de datos.

### Arquitectura Adaptada
```
┌─────────────────────┐
│  Next.js Frontend   │
│  + API Routes       │
└──────────┬──────────┘
           │
           ├─> Redis (reemplazo de KV)
           │
┌──────────▼──────────┐
│  Node Cron Worker   │
│  (reemplazo de CF)  │
│  - node-cron        │
│  - Checks HTTP/TCP  │
└─────────────────────┘
```

### Cambios necesarios en el código:

#### 1. Instalar dependencias adicionales

```bash
npm install redis node-cron ioredis
```

#### 2. Crear adaptador para Redis

Archivo: `lib/redis-adapter.ts`
```typescript
import Redis from 'ioredis'

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD,
})

export const kvStore = {
  async get(key: string, options?: { type: 'json' | 'text' }) {
    const value = await redis.get(key)
    if (!value) return null
    return options?.type === 'json' ? JSON.parse(value) : value
  },

  async put(key: string, value: any, options?: any) {
    const stringValue = typeof value === 'string' ? value : JSON.stringify(value)
    await redis.set(key, stringValue)
  },
}

export default redis
```

#### 3. Crear worker interno

Archivo: `worker-standalone/monitor-worker.ts`
```typescript
import cron from 'node-cron'
import { workerConfig } from '../uptime.config'
import { getStatus } from '../worker/src/monitor'
import { kvStore } from '../lib/redis-adapter'

// Ejecutar cada minuto
cron.schedule('* * * * *', async () => {
  console.log('Running monitor checks...')
  
  // Lógica del worker original aquí
  // Adaptar el código de worker/src/index.ts
})

console.log('Monitor worker started')
```

#### 4. Modificar API routes

Actualizar `pages/api/data.ts` para usar Redis en lugar de KV:
```typescript
import { kvStore } from '@/lib/redis-adapter'

export default async function handler(req: NextRequest): Promise<Response> {
  const stateStr = await kvStore.get('state', { type: 'text' })
  // ... resto del código
}
```

### Instalación en VPS (Opción 2)

```bash
# Instalar Redis
sudo apt install -y redis-server

# Configurar Redis
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Clonar y configurar proyecto
cd /var/www/uptimeflare
npm install

# Variables de entorno
cat > .env.local << EOF
NODE_ENV=production
REDIS_HOST=localhost
REDIS_PORT=6379
EOF

# Build y PM2
npm run build

cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'uptimeflare-web',
      script: 'npm',
      args: 'start',
      cwd: '/var/www/uptimeflare',
      instances: 1,
      env: { NODE_ENV: 'production', PORT: 3000 }
    },
    {
      name: 'uptimeflare-worker',
      script: 'node',
      args: 'worker-standalone/monitor-worker.js',
      cwd: '/var/www/uptimeflare',
      instances: 1,
      env: { NODE_ENV: 'production' }
    }
  ]
}
EOF

pm2 start ecosystem.config.js
pm2 save
```

---

## 🐳 OPCIÓN 3: Docker (Más sencillo)

### Dockerfile
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Instalar dependencias
COPY package*.json ./
RUN npm ci --only=production

# Copiar código
COPY . .

# Build
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
```

### docker-compose.yml
```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - REDIS_HOST=redis
    depends_on:
      - redis
    restart: unless-stopped

  worker:
    build: .
    command: node worker-standalone/monitor-worker.js
    environment:
      - NODE_ENV=production
      - REDIS_HOST=redis
    depends_on:
      - redis
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - /etc/letsencrypt:/etc/letsencrypt
    depends_on:
      - web
    restart: unless-stopped

volumes:
  redis-data:
```

### Desplegar con Docker

```bash
# Instalar Docker y Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt install -y docker-compose

# Iniciar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f
```

---

## 📊 Comparación de Opciones

| Característica | Opción 1 (Híbrido) | Opción 2 (VPS Completo) | Opción 3 (Docker) |
|----------------|-------------------|------------------------|-------------------|
| Complejidad | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Costo | $ (CF gratis) | $$ | $$ |
| Red Global | ✅ | ❌ | ❌ |
| Auto-hospedado | Parcial | ✅ | ✅ |
| Modificación código | Mínima | Alta | Alta |
| Mantenimiento | Fácil | Medio | Fácil |

---

## 🔧 Troubleshooting

### Problema: Error de conexión a KV/Redis
```bash
# Verificar Redis
redis-cli ping
# Debe responder: PONG

# Verificar conexión
redis-cli
> keys *
```

### Problema: Next.js no inicia
```bash
# Ver logs de PM2
pm2 logs uptimeflare

# Reiniciar
pm2 restart uptimeflare
```

### Problema: Nginx no funciona
```bash
# Verificar sintaxis
sudo nginx -t

# Ver logs
sudo tail -f /var/log/nginx/error.log
```

---

## 🎯 Recomendación Final

**Para tu caso (Daramex API Status):**

👉 **Recomiendo OPCIÓN 1 (Híbrido)** porque:

1. ✅ Ya tienes el código funcionando con Cloudflare
2. ✅ Cloudflare Workers es gratis y confiable
3. ✅ Menos trabajo de adaptación
4. ✅ Mejor rendimiento global (checks desde múltiples ubicaciones)
5. ✅ Solo necesitas configurar el frontend en tu VPS

**Tiempo estimado**: 30-60 minutos

Si prefieres 100% auto-hospedado, la **OPCIÓN 3 (Docker)** es la segunda mejor opción por su facilidad de mantenimiento.

¿Necesitas ayuda para implementar alguna de estas opciones?

