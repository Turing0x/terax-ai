# Auditoría

Estado: **pendiente**. Base prevista: upstream `main` (v0.9.0, `1a68067`).

## Formato de cada hallazgo

```
### A-<n>: <título corto>
- Área / severidad: <seguridad|corrección|rendimiento|UX|docs|tests> / <alta|media|baja>
- Ubicación: `ruta:línea`
- Problema: qué falla y en qué escenario concreto
- Propuesta: cambio mínimo + test que fija el invariante
- Estado: abierto | PR #<n> | descartado (motivo)
```

## Orden propuesto

1. Seguridad: herramientas de IA y aprobaciones, deny-list, `WorkspaceRegistry`, proxy de red, control plane CLI, OSC 52/8/7.
2. Corrección en Rust: PTY (sesiones, cierre, Windows), fs (mutaciones atómicas, symlinks), git (argumentos, pathspecs).
3. Frontend: estado de tabs/splits, sesiones de IA, editor (guardado, conflictos).
4. Rendimiento: rutas calientes (renderer, PTY stream, streaming IA, explorer).
5. Tests: invariantes de subsistemas core sin cobertura.
6. Docs: deriva restante (traducciones de README).

## Observaciones previas (sin verificar a fondo)

- `bash_kill` se ejecuta sin aprobación. Solo afecta a procesos de `bash_background` (ya aprobados); parece intencionado. Documentado en #1358.
- Traducciones `docs/readme/*` siguen mencionando xterm.js (11 idiomas). Esperar a que se resuelva #1307.
- Doc `pty-transport-v2.md` cita `ipc/channel.rs` de Tauri 2.11 (fichero externo, correcto).

## Hallazgos

(ninguno todavía)
