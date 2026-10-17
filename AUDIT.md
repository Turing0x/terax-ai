# Auditoría

Base: upstream `main` (v0.9.0, `1a68067`).

## Orden acordado (2026-10-17)

### Fase A: seguridad (acotada)

Modelo de amenaza (de `SECURITY.md`): entrada no confiable = salida de terminal, contenido de ficheros/repos, resultados de herramientas IA (prompt injection), web preview, updater. Fuera: atacante local.

| # | Superficie | Pregunta | Estado |
| --- | --- | --- | --- |
| A1 | Herramientas IA | ¿Prompt injection ejecuta sin aprobación? ¿Bypass path guard / deny-list? | Revisada. Hardening abajo; resto en privado |
| A2 | Comandos IPC Tauri | ¿Validan rutas contra `WorkspaceRegistry`? ¿Capabilities mínimas? | Pendiente |
| A3 | OSC 52/8/7 | Portapapeles sin permiso, enlaces peligrosos, cwd falso | Pendiente |
| A4 | Red y preview | Proxy, CSP, orígenes alcanzables | Pendiente |
| A5 | Credenciales | Fugas en logs, errores, contexto IA | Pendiente |
| A6 | Control plane CLI | Permisos de socket, autenticación | Pendiente |
| A7 | Updater | Firma, https | Pendiente |

Método: revisar PRs abiertos del área, leer código, hipótesis concretas, PoC en build local. Sin PoC no hay hallazgo.

Clasificación:
- Explotable: email privado a security@terax.app. Se registra SOLO en `../terax-private/SECURITY-FINDINGS.md` (fuera de git) hasta fix publicado. Esta rama es pública.
- Hardening sin impacto explotable: PR `security/<área>`, aquí como A-n.
- Falso positivo: descartado con motivo.

### Fase B: funcional (uso diario)

1. Arranque y sesión 2. Terminal 3. Tabs y splits 4. Atajos y paleta 5. Ajustes 6. Explorador y editor 7. Git 8. IA

Por área: checklist de comportamiento esperado (referencia iTerm/Warp/VS Code), prueba manual de Turing0x, lectura de código buscando casos límite. Hallazgos F-n: bug (PR directo) | UX (issue antes) | feature (issue antes).

## Formato de hallazgo

```
### A-<n> / F-<n>: <título corto>
- Área / severidad: <seguridad|corrección|rendimiento|UX|docs|tests> / <alta|media|baja>
- Ubicación: `ruta:línea`
- Problema: qué falla y en qué escenario concreto
- Propuesta: cambio mínimo + test que fija el invariante
- Estado: abierto | PR #<n> | descartado (motivo)
```

## Observaciones previas

- `bash_kill` sin aprobación: solo procesos de `bash_background` ya aprobados. Intencionado. Documentado en #1358.
- Traducciones `docs/readme/*` mencionan xterm.js (11 idiomas). Esperar #1307.

## PRs abiertos relevantes para A1

#1255 (deny aprobaciones pendientes), #876 (YOLO toggle), #1062/#1060/#1181 (tests IA), #973 (security hardening, grande).

## Hallazgos

### A-1: write guard no cubre ficheros de persistencia de usuario
- Área / severidad: seguridad (hardening) / media
- Ubicación: `src/modules/ai/lib/security.ts:106-125`
- Problema: prefijos anclados a raíz. `~/Library/LaunchAgents`, `~/Library/LaunchDaemons`, `~/.zshrc`, `~/.bashrc`, `~/.gitconfig`, `/Applications` pasan `checkWritable`. Sigue haciendo falta aprobación.
- Propuesta: cubrir variantes de usuario; test en `security.test.ts`.
- Estado: PR #1360

### A-2: open_preview acepta cualquier puerto loopback sin aprobación
- Área / severidad: seguridad (hardening) / baja
- Ubicación: `src/modules/ai/tools/terminal.ts:63-93`
- Propuesta: aprobación si el puerto no es de un `bash_background` activo.
- Estado: abierto

### A-3: plan mode solo por prompt; applyAll no recomprueba
- Área / severidad: seguridad (hardening) / baja
- Ubicación: `agent.ts:301-302`, `tools/shell.ts`, `planStore.applyAll`
- Propuesta: bloquear `bash_*` con plan activo; `checkWritableCanonical` en apply.
- Estado: abierto

### A-4: spawn_coding_agent no filtra control chars
- Área / severidad: seguridad (hardening) / baja
- Ubicación: `useAiLiveBridge.ts` (~120-155)
- Problema: `\x1b[201~` embebido cierra bracketed paste. `send_to_agent` sí filtra.
- Propuesta: reutilizar `hasControlChars`.
- Estado: abierto

### A-5: bash_logs / bash_kill no ligados a la sesión de chat
- Área / severidad: seguridad (hardening) / baja
- Ubicación: `src-tauri/src/.../shell/mod.rs` (~187-215)
- Propuesta: guardar sessionId dueño en `BackgroundProc`.
- Estado: abierto

### A-6: deny-list de shell es conveniencia, no frontera
- Área / severidad: seguridad (hardening) / baja
- Problema: `rm -rf /*`, `rm -r -f /`, `bash <(curl …)`, `| /bin/sh`, `| python3` pasan. El código ya dice que el usuario es el gate.
- Propuesta: ampliar patrones obvios con tests. Prioridad baja.
- Estado: abierto

### Refutado en A1 (no volver a comprobar)
`..`, mayúsculas, `.SSH`, ADS, punto/espacio final, `\\?\`; symlink a ruta protegida (canonicaliza); escritura vía symlink colgante; subagentes (solo lectura); ejecución antes de aprobar; auto-approve (no existe); imagen markdown zero-click (CSP `img-src`); XSS markdown (sanitize + CSP); sentinel shell; preview no loopback.
