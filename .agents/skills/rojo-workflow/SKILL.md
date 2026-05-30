---
name: rojo-workflow
description: >
  Defines the correct development workflow when working with Rojo in Roblox Studio.
  Ensures the AI agent modifies files locally instead of directly in Studio via MCP,
  to prevent synchronization errors, duplicate scripts, or accidental data loss.
  Trigger this when working on Roblox code or when the user mentions "Rojo".
---

# Roblox + Rojo Development Workflow

Este documento define la forma correcta de programar e interactuar con este proyecto de Roblox que utiliza Rojo. Sigue estas reglas estrictamente para evitar pérdida de datos o duplicación de scripts.

## La Regla de Oro
**El sistema de archivos local (`src/`) es la única fuente de la verdad.** 
Todos los scripts deben ser creados, modificados y eliminados exclusivamente desde la PC local. Rojo se utiliza como una sincronización en UNA SOLA DIRECCIÓN (One-Way Sync) desde la PC hacia Roblox Studio.

## Estructura y Mapeo (`default.project.json`)
El archivo de configuración dicta exactamente en qué lugar de Roblox Studio se inyectarán los archivos locales:
- `src/server` ➡️ `ServerScriptService.Server`
- `src/client` ➡️ `StarterPlayer.StarterPlayerScripts.Client`
- `src/shared` ➡️ `ReplicatedStorage.Shared`

## Reglas Estrictas para Agentes de IA
1. **Nunca crear scripts en Studio:** No crees ni edites scripts directamente dentro de Roblox Studio a través de herramientas MCP (como `mcp_Roblox_Studio_multi_edit`).
2. **Trabajar Siempre en Local:** Utiliza siempre herramientas de edición de archivos locales (`write_to_file`, `replace_file_content`) para crear o modificar archivos `.server.luau`, `.client.luau` y `.luau` dentro de la carpeta `src/`.
3. **Confiar en el Auto-Sync:** Una vez que el archivo local se guarda, Rojo se encargará de inyectarlo o actualizarlo de forma inmediata en Roblox Studio.
4. **Evitar Duplicidad:** Si encuentras un script ejecutándose directamente en `ServerScriptService` (o similar) que no proviene de la carpeta `src/`, debes migrarlo a `src/` y destruir la versión huérfana en Studio para evitar que el código se ejecute dos veces.
