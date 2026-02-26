---
name: actualizar_docs
description: Actualiza la documentacion del proyecto (CHANGELOG.md, README.md, USER_MANUAL.md) basandose en los cambios recientes del repositorio.
argument-hint: "[changelog|readme|manual|all]"
---

# Actualizar Documentacion de DriveMate

Actualiza los archivos de documentacion del proyecto para reflejar los cambios mas recientes.

## Pasos obligatorios

1. **Revisar cambios recientes**: Ejecuta `git log --oneline -10` y `git diff HEAD~1 --stat` para entender que cambio.
2. **Leer la documentacion actual**: Lee CHANGELOG.md, README.md y USER_MANUAL.md antes de editarlos.
3. **Actualizar segun argumento**:
   - `$ARGUMENTS` == "changelog" o vacio → actualizar CHANGELOG.md
   - `$ARGUMENTS` == "readme" → actualizar README.md
   - `$ARGUMENTS` == "manual" → actualizar USER_MANUAL.md
   - `$ARGUMENTS` == "all" o vacio → actualizar los tres archivos
   - Si no se proporciona argumento, actualizar los tres.

## Reglas por archivo

### CHANGELOG.md
- Formato: Keep a Changelog (keepachangelog.com)
- Secciones: Added, Changed, Fixed, Removed, Breaking Changes (solo las necesarias)
- Separar cambios iOS y Android con sub-encabezados `#### iOS` y `#### Android`
- Incrementar version siguiendo semver:
  - MAJOR: cambios incompatibles
  - MINOR: nueva funcionalidad retrocompatible
  - PATCH: correcciones de bugs
- Fecha en formato YYYY-MM-DD

### README.md
- Mantener estructura existente (Features, Project Structure, Quick Start, Tech Stack, Architecture)
- Actualizar Project Structure si hay archivos/directorios nuevos
- Actualizar tabla Tech Stack si cambian dependencias
- Actualizar Features si hay funcionalidad nueva
- Idioma: ingles

### USER_MANUAL.md
- Idioma: espanol
- Actualizar secciones afectadas por los cambios
- Agregar instrucciones paso a paso para funcionalidad nueva
- Mantener tabla de estados del boton actualizada
- Actualizar seccion CarPlay/Android Auto si hay cambios en integracion vehicular
- Actualizar FAQ si aplica

## Restricciones
- NO inventar funcionalidad que no exista en el codigo
- NO cambiar el formato/estilo general de los archivos
- NO agregar secciones innecesarias
- Verificar que los cambios documentados correspondan a codigo real del repositorio
