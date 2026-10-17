# Auditoría

Base: upstream `main` (v0.9.0, `1a68067`).

## Orden acordado (2026-10-17)

### Fase A: seguridad (acotada)

Modelo de amenaza (de `SECURITY.md`): entrada no confiable = salida de terminal, contenido de ficheros/repos, resultados de herramientas IA (prompt injection), web preview, updater. Fuera: atacante local.

| # | Superficie | Pregunta | Estado |
| --- | --- | --- | --- |
| A1 | Herramientas IA | ¿Prompt injection ejecuta sin aprobación? ¿Bypass path guard / deny-list? | En curso |
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

(ninguno todavía)
