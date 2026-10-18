# Estado

Última actualización: 2026-10-18. Upstream en `1a68067` (v0.9.0, publicada 2026-10-16).

## Plan

| Fase | Estado |
| --- | --- |
| 1. Conocer el proyecto (docs, stack, arquitectura) | Hecho |
| 2. PR de sincronización de documentación | Abierto (#1358) |
| 3a. Auditoría de seguridad (A1-A7), `AUDIT.md` | A1 hecha: A-1 en PR #1360, A-2..A-6 pendientes de PR; informe privado redactado, pendiente de envío. Siguiente: A2 IPC |
| 3b. Auditoría funcional (8 áreas de uso diario) | Áreas 6 y 7 hechas (F-1..F-14 en `AUDIT.md`). Resto pendiente |
| 4. PRs pequeños a partir de la auditoría | En curso (#1360). Ola 1 B6/B7 (P1-P4) en implementación; issue #1366 (P5) abierto |
| 5. Funcionalidad: atajo terminal en home (#1359) | Lista, probada. Falta OK del mantenedor para abrir PR |

## PRs

| PR | Título | Rama | Estado | Notas |
| --- | --- | --- | --- | --- |
| [#1360](https://github.com/crynta/terax-ai/pull/1360) | security(ai): block agent writes to user persistence paths | `security/ai-write-guard-user-paths` | Abierto | A-1. Worktree ../terax-ai-write-guard |
| [#1358](https://github.com/crynta/terax-ai/pull/1358) | docs: sync architecture docs with the current code | `docs/sync-architecture-docs` | Abierto, CodeRabbit pendiente | 9 ficheros, +57/-27. Excluye README (lo cubre #1307 de otro contribuidor) y traducciones |

## Ola 1 B6/B7 (en curso)

| PR | Hallazgo | Rama | Worktree | Estado |
| --- | --- | --- | --- | --- |
| P1 | F-4 | `fix/git-log-merge-pagination` | ../terax-ai-git-log-pagination | implementando |
| P2 | F-8 | `fix/fs-write-through-symlink` | ../terax-ai-write-symlink | implementando |
| P3 | F-9 | `fix/editor-rename-keeps-edits` | ../terax-ai-rename-dirty | implementando |
| P4 | F-5 | `fix/git-commit-timeout` | ../terax-ai-commit-timeout | implementando |

Rust de los 4 worktrees comparte `CARGO_TARGET_DIR` del checkout principal (ahorro de disco). `node_modules` de los worktrees es symlink al principal (lockfile idéntico a upstream).

## PRs ajenos relevantes

- [#1307](https://github.com/crynta/terax-ai/pull/1307): README xterm.js -> libghostty. Por eso no tocamos README.
- [#1255](https://github.com/crynta/terax-ai/pull/1255): deny de aprobaciones pendientes en IA. Revisar antes de auditar el flujo de aprobación.
- [#1306](https://github.com/crynta/terax-ai/pull/1306): inyección de `cd` en procesos en primer plano. Revisar antes de auditar terminal.

Antes de trabajar en un área, buscar PRs abiertos que la toquen:
`gh pr list -R crynta/terax-ai --state open --search "<área>"`.

## Próximos pasos

1. Turing0x: revisar y enviar el informe privado A1 a security@terax.app (borrador en `../terax-private/`). Anotar fecha de envío allí.
2. Seguir #1358 y #1360 (CodeRabbit / mantenedor). En #1360 falta la prueba manual en `pnpm tauri dev`.
3. Auditoría A2: comandos IPC de Tauri (validación de rutas, `WorkspaceRegistry`, capabilities). Luego A3-A7 y fase B funcional.
4. PRs de hardening A-2..A-6 (ver `AUDIT.md`), uno por PR. Esperar respuesta del mantenedor al informe privado antes de los que toquen el flujo de aprobación.
5. Feature `tab.newHome` (#1359): esperando OK del mantenedor. Rama `feat/new-terminal-home` (729f826) en `fork`. Al recibir OK: worktree desde `origin/main`, cherry-pick, push, PR.

## Decisiones y lecciones

- Hallazgos explotables: nunca en esta rama (es pública). Solo en `../terax-private/` (fuera de git) hasta que haya fix publicado. Informe por email, lo envía Turing0x.
- No construimos pruebas de concepto de explotación. Los informes van con `fichero:línea`, impacto y propuesta de fix.
- Un solo agente por worktree. Un agente interrumpido puede seguir vivo en segundo plano: comprobar con ListAgents y pararlo antes de relanzar. (En A-1 dos agentes escribieron a la vez; se resolvió con reset a `origin/main` y reimplementación limpia.)
- No ejecutar `biome format --write` sobre ficheros enteros: mete reformateo ajeno al PR.

## Registro

- 2026-10-17: lectura completa de docs. Verificación docs vs código. Fork `Turing0x/terax-ai` creado. PR #1358 abierto. Rama `contrib-notes` creada para estas notas.
- 2026-10-17: feature `tab.newHome` implementada en `feat/new-terminal-home`. Lint/types/tests OK. Issue #1359 abierto.
- 2026-10-17: `tab.newHome` probada a mano, funciona. Marcada lista. Siguiente funcionalidad la define Turing0x.
- 2026-10-17: reordenada auditoría: A seguridad acotada, B funcional por recorridos de usuario. Inicio A1.
- 2026-10-17: A1 completada. Hardening A-1..A-6 en AUDIT.md. Hallazgos explotables en privado.
- 2026-10-17: PR #1360 (A-1) abierto. Informe privado A1 redactado, pendiente de envío por Turing0x.
- 2026-10-17: kit de PoC de S1 borrado. Notas consolidadas (decisiones y lecciones). Pausa antes de A2.
- 2026-10-18: worktree `../terax-ai-contrib` recreado (se había perdido). Sin cambios en #1358, #1360 ni #1359 (solo resumen de CodeRabbit, sin respuesta del mantenedor). Upstream sigue en `1a68067`.
- 2026-10-18: auditoría B6 (explorador y editor) y B7 (git). 14 hallazgos F-1..F-14. Causa raíz del Source Control sin tiempo real: F-1. F-4 reproducido en repo de prueba.
- 2026-10-18: plan de implementación B6/B7 en `PLAN.md` (4 olas, P1-P10 + 4 issues UX).
- 2026-10-18: issue #1366 abierto (diseño P5, Source Control en tiempo real). Ola 1 lanzada en paralelo: 4 worktrees, un implementador por PR.
