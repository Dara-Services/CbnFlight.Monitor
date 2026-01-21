# Multi-stage build para optimizar tamaño
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./
COPY worker/package*.json ./worker/

# Instalar dependencias
RUN npm ci --only=production && \
    cd worker && npm ci --only=production && cd ..

# Copiar código fuente
COPY . .

# Build de Next.js
RUN npm run build

# Etapa de producción
FROM node:18-alpine

WORKDIR /app

# Instalar solo dependencias de producción
COPY package*.json ./
RUN npm ci --only=production

# Copiar build desde etapa anterior
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/uptime.config.ts ./
COPY --from=builder /app/uptime.types.ts ./

# Variables de entorno
ENV NODE_ENV=production
ENV PORT=3000

# Exponer puerto
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/api/data', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Usuario no root por seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 && \
    chown -R nextjs:nodejs /app

USER nextjs

# Comando de inicio
CMD ["npm", "start"]

