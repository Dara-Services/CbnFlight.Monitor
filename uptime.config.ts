const pageConfig = {
    title: "Cbnflight API Status Page",
    links: [
        {link: 'https://github.com/Dara-Services', label: 'GitHub'},
        {link: 'mailto:jc1997hdez@dara-services.com', label: 'Email Me', highlight: true},
    ],
}

const workerConfig = {
    kvWriteCooldownMinutes: 3,
    // passwordProtection: 'username:password',
    monitors: [
        {
            id: 'identity_service',
            name: 'Identity Service',
            method: 'GET',
            target: 'https://api.cbnflight.com/api/identity/alive',
            tooltip: '',
            expectedCodes: [200],
            timeout: 10000,
        },
        {
            id: 'payment_service',
            name: 'Payment Service',
            method: 'GET',
            target: 'https://api.cbnflight.com/api/payment/alive',
            tooltip: '',
            expectedCodes: [200],
            timeout: 10000,
        },
        {
            id: 'crm_service',
            name: 'CRM Service',
            method: 'GET',
            target: 'https://api.cbnflight.com/api/crm/alive',
            tooltip: '',
            expectedCodes: [200],
            timeout: 10000,
        },
        {
            id: 'notifications_service',
            name: 'Notifications Service',
            method: 'GET',
            target: 'https://api.cbnflight.com/api/notifications/alive',
            tooltip: '',
            expectedCodes: [200],
            timeout: 10000,
        },
        {
            id: 'realestate_service',
            name: 'RealEstate Service',
            method: 'GET',
            target: 'https://api.cbnflight.com/api/realestate/alive',
            tooltip: '',
            expectedCodes: [200],
            timeout: 10000,
        },
        {
            id: 'shops_service',
            name: 'Shops Service',
            method: 'GET',
            target: 'https://api.cbnflight.com/api/shops/alive',
            tooltip: '',
            expectedCodes: [200],
            timeout: 10000,
        },
        {
            id: 'filegw_service',
            name: 'FileGateway Service',
            method: 'GET',
            target: 'https://api.cbnflight.com/api/filegw/alive',
            tooltip: '',
            expectedCodes: [200],
            timeout: 10000,
        },
        {
            id: 'rabbitmq_management',
            name: 'RabbitMQ Management API',
            method: 'GET',
            target: 'https://broker.cbnflight.com/api/overview',
            tooltip: 'Chequeo de la API de administración de RabbitMQ',
            expectedCodes: [200],
            timeout: 10000,
            headers: {
                'Authorization': 'Basic ' + btoa('cbnflight:GHORiveBT3XBY3PXFJIS4Jsbs25PzDCfuITqTDOQ'),
            }
        },
        {
            id: 'extension_server_freepbx',
            name: 'Python FreePBX Extension Server',
            method: 'GET',
            target: 'http://64.23.183.189:9001/keepalive',
            tooltip: 'Chequeo del servidor de extensiones de FreePBX',
            expectedCodes: [200],
            timeout: 10000,
        }
    ],
    callbacks: {
        onStatusChange: async (
            env: any,
            monitor: any,
            isUp: boolean,
            timeIncidentStart: number,
            timeNow: number,
            reason: string
        ) => {

            const appriseApiServer: string = "https://apprise.cbnflight.com/notify";
            const recipientUrl: string = "tgram://7867477051:AAGuYw37lW8RonYvhSfnDch-GePH0TT6yQs/-1002019874675";
            // const recipientUrl: string = "tgram://7867477051:AAGuYw37lW8RonYvhSfnDch-GePH0TT6yQs/-4539254140"; => Test Channel
            const timeZone: string = "America/Havana";

            const incidentTime = new Date().toLocaleString('en-US', {timeZone});
            let title, message;

            const downtimeDuration = timeNow - timeIncidentStart; // seconds

            if (isUp && downtimeDuration >= 300) { // notify only if the monitor is up and the downtime is greater than 5 minutes
                const downtimeHours = Math.floor(downtimeDuration / 3600);
                const downtimeMinutes = Math.floor((downtimeDuration % 3600) / 60);
                const downtimeSeconds = downtimeDuration % 60;

                title = `✅ ${monitor.name} está OPERATIVO`;
                message = `✅ *Servicio Recuperado*
*Monitor*: ${monitor.name}
*ID*: ${monitor.id}
*Method*: ${monitor.method}
*Target*: ${monitor.target}

*Hora del reporte*: ${incidentTime}
*Duración de la Caída*: ${downtimeHours} horas, ${downtimeMinutes} minutos y ${downtimeSeconds} segundos`;

                try {
                    await fetch(appriseApiServer, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Basic ' + btoa('cbnflight:M8gEu0qQYAhUndMitZHAygr2oYd4DOUYN6tn3RBA'),
                        },
                        body: JSON.stringify({
                            urls: recipientUrl,
                            title: title,
                            body: message,
                            format: 'markdown',
                        }),
                    });
                } catch (error) {
                    console.error('Error al enviar la notificación de estado:', error);
                }

            }
        },
        onIncident: async (
            env: any,
            monitor: any,
            timeIncidentStart: number,
            timeNow: number,
            reason: string
        ) => {

            const appriseApiServer: string = "https://apprise.cbnflight.com/notify";
            const recipientUrl: string = "tgram://7867477051:AAGuYw37lW8RonYvhSfnDch-GePH0TT6yQs/-1002019874675";
            // const recipientUrl: string = "tgram://7867477051:AAGuYw37lW8RonYvhSfnDch-GePH0TT6yQs/-4539254140"; => Test Channel
            const timeZone: string = "America/Havana";

            const downtimeDuration = timeNow - timeIncidentStart; // seconds
            const incidentTime = new Date().toLocaleString('en-US', {timeZone});

            if (downtimeDuration <= 270 || downtimeDuration > 330) return; // notify only in the 5th minute

            const title = `🚨 ${monitor.name} está CAÍDO hace ${downtimeDuration} segundos`;
            const message = `🚨 *Incidente Detectado*
*Monitor*: ${monitor.name}
*ID*: ${monitor.id}
*Method*: ${monitor.method}
*Target*: ${monitor.target}
*Razón*: ${reason}

*Hora del reporte*: ${incidentTime}`;

            try {
                await fetch(appriseApiServer, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Basic ' + btoa('cbnflight:M8gEu0qQYAhUndMitZHAygr2oYd4DOUYN6tn3RBA'),
                    },
                    body: JSON.stringify({
                        urls: recipientUrl,
                        title: title,
                        body: message,
                        format: 'markdown',
                    }),
                });
            } catch (error) {
                console.error('Error al enviar la notificación de estado:', error);
            }

        },
    }
}

export {pageConfig, workerConfig}
