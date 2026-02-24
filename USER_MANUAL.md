# DriveMate - Manual de Usuario

## Primeros Pasos

### 1. Instalar la app

**iOS**: Abre el proyecto en Xcode y ejecuta en tu iPhone o simulador.

**Android**: Abre el proyecto en Android Studio y ejecuta en tu dispositivo o emulador.

### 2. Obtener API Key de Gemini (Gratis)

DriveMate necesita una clave de Google Gemini para funcionar. Es completamente gratuita.

1. Ve a [Google AI Studio](https://aistudio.google.com/apikey)
2. Inicia sesion con tu cuenta de Google
3. Haz clic en **"Create API Key"** (Crear clave de API)
4. Copia la clave generada

**Limites del plan gratuito:**
- 15 peticiones por minuto
- 1,500 peticiones por dia
- Sin costo

### 3. Configurar la API Key

1. Abre DriveMate
2. Toca el icono de **engranaje** (esquina superior derecha)
3. En la seccion **"Google Gemini API"**, pega tu API Key
4. Vuelve a la pantalla principal

---

## Como Usar DriveMate

### Conversacion basica

1. **Toca el boton del microfono** (circulo azul grande en la parte inferior)
2. **Habla tu pregunta** — veras tu voz transcrita en tiempo real
3. **Espera** — el boton cambia a naranja mientras la IA piensa
4. **Escucha** — el boton cambia a verde y la IA responde en voz alta

### Estados del boton

| Color | Estado | Significado |
|-------|--------|-------------|
| Azul | Inactivo | Listo para escuchar |
| Rojo | Escuchando | Grabando tu voz |
| Naranja | Procesando | La IA esta pensando |
| Verde | Hablando | La IA esta respondiendo |

### Detener la interaccion

- **Mientras escucha (rojo)**: Toca el boton para dejar de grabar
- **Mientras habla (verde)**: Toca el boton para silenciar la respuesta
- **Mientras procesa (naranja)**: Espera a que termine

### Limpiar conversacion

Si quieres empezar una conversacion nueva, toca **"Limpiar conversacion"** debajo del boton del microfono. Esto borra todos los mensajes y el historial de la IA.

---

## Ajustes

### Idioma

Cambia el idioma de todo el sistema:
- **Reconocimiento de voz**: La app escucha en el idioma seleccionado
- **Respuesta de IA**: Gemini responde en ese idioma
- **Voz sintetica**: La app habla en ese idioma

Idiomas disponibles: Espanol, English, Francais, Deutsch, Portugues.

### Modelo de IA

Elige entre 10 modelos de Google Gemini:

| Modelo | Caracteristica |
|--------|---------------|
| Gemini 1.5 Flash | Estable, rapido |
| Gemini 1.5 Pro | Estable, mejor calidad |
| Gemini 2.0 Flash | **Recomendado** - buen balance |
| Gemini 2.0 Flash Lite | Ultra rapido, respuestas mas cortas |
| Gemini 2.5 Flash | Mejor calidad/velocidad |
| Gemini 2.5 Flash Lite | Ligero |
| Gemini 2.5 Pro | Maxima calidad |
| Gemini 3 Flash (Preview) | Nueva generacion, puede ser inestable |
| Gemini 3 Pro (Preview) | Nueva generacion, puede ser inestable |
| Gemini 3.1 Pro (Preview) | Lo mas nuevo, puede ser inestable |

**Recomendacion**: Usa **Gemini 2.0 Flash** para el mejor equilibrio entre velocidad y calidad.

### Velocidad de voz

Ajusta que tan rapido habla la IA:
- **iOS**: Rango de 0.1 a 0.75 (default: 0.5)
- **Android**: Rango de 0.5 a 2.0 (default: 1.0)

### Modo manos libres

Cuando esta activado, la app **vuelve a escuchar automaticamente** despues de que la IA termina de hablar. Ideal para conversaciones continuas mientras conduces sin tocar la pantalla.

### Modo oscuro forzado

Activa el tema oscuro independientemente de la configuracion del sistema. Recomendado para conduccion nocturna.

---

## Uso con CarPlay / Android Auto

### CarPlay (iOS)

DriveMate incluye soporte para CarPlay con interfaz de voz simplificada.

> **Nota**: CarPlay requiere un entitlement de Apple (`com.apple.developer.carplay-audio`) que debe solicitarse a Apple. El codigo esta preparado pero necesita aprobacion.

### Android Auto

DriveMate incluye los metadatos necesarios para Android Auto. La integracion completa requiere publicacion en Google Play y cumplir las guias de Android Auto.

---

## Solucion de Problemas

### "No se ha configurado la API Key de Gemini"
Ve a Ajustes y pega tu API Key. Obtenla gratis en [aistudio.google.com/apikey](https://aistudio.google.com/apikey).

### "Limite de peticiones alcanzado"
Has superado las 15 peticiones/minuto del plan gratuito. Espera 1 minuto y vuelve a intentar.

### "Reconocimiento de voz no disponible"
- **iOS**: Ve a Ajustes del sistema > Privacidad > Reconocimiento de voz y activa el permiso para DriveMate
- **Android**: Asegurate de haber concedido el permiso de microfono cuando la app lo solicito

### La IA no responde
1. Verifica que tienes conexion a internet
2. Verifica que la API Key es correcta
3. Intenta cambiar a otro modelo de Gemini en Ajustes
4. Si usas un modelo "Preview", cambia a Gemini 2.0 Flash (mas estable)

### La voz suena rara o no se escucha
- Ajusta la velocidad de voz en Ajustes
- Verifica que el volumen del dispositivo esta alto
- Intenta cambiar el idioma y volver a seleccionarlo

---

## Preguntas Frecuentes

**P: Es gratis?**
R: Si. DriveMate usa el plan gratuito de Google Gemini que incluye 15 peticiones/minuto sin costo.

**P: Funciona sin internet?**
R: El reconocimiento de voz y la sintesis de voz funcionan sin internet. Sin embargo, las respuestas de la IA requieren conexion a internet para comunicarse con Google Gemini.

**P: Mis conversaciones son privadas?**
R: Las conversaciones se envian a Google Gemini para procesamiento. No se almacenan en ningun servidor propio. Al cerrar la app, el historial se borra.

**P: Puedo usarlo mientras conduzco?**
R: Si, DriveMate esta disenado para uso con manos libres. Activa el "Modo manos libres" en Ajustes para conversacion continua sin tocar la pantalla. Siempre prioriza la seguridad al volante.
