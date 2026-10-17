# Estado

Última actualización: 2026-10-17. Upstream en `1a68067` (v0.9.0, publicada 2026-10-16).

## Plan

| Fase | Estado |
| --- | --- |
| 1. Conocer el proyecto (docs, stack, arquitectura) | Hecho |
| 2. PR de sincronización de documentación | Abierto (#1358) |
| 3a. Auditoría de seguridad (A1-A7), `AUDIT.md` | En curso: A1 herramientas IA |
| 3b. Auditoría funcional (8 áreas de uso diario) | Pendiente |
| 4. PRs pequeños a partir de la auditoría | Pendiente |
| 5. Funcionalidad: atajo terminal en home (#1359) | Lista, probada. Falta OK del mantenedor para abrir PR |

## PRs

| PR | Título | Rama | Estado | Notas |
| --- | --- | --- | --- | --- |
| [#1358](https://github.com/crynta/terax-ai/pull/1358) | docs: sync architecture docs with the current code | `docs/sync-architecture-docs` | Abierto, CodeRabbit pendiente | 9 ficheros, +57/-27. Excluye README (lo cubre #1307 de otro contribuidor) y traducciones |

## PRs ajenos relevantes

- [#1307](https://github.com/crynta/terax-ai/pull/1307): README xterm.js -> libghostty. Por eso no tocamos README.
- [#1255](https://github.com/crynta/terax-ai/pull/1255): deny de aprobaciones pendientes en IA. Revisar antes de auditar el flujo de aprobación.
- [#1306](https://github.com/crynta/terax-ai/pull/1306): inyección de `cd` en procesos en primer plano. Revisar antes de auditar terminal.

Antes de trabajar en un área, buscar PRs abiertos que la toquen:
`gh pr list -R crynta/terax-ai --state open --search "<área>"`.

## Próximos pasos

1. Atender comentarios de CodeRabbit / mantenedor en #1358.
2. Auditoría: fase A seguridad (A1 en curso), luego fase B funcional. Hallazgos explotables solo en `../terax-private/` (fuera de git).
3. Feature elegida: atajo Cmd/Ctrl+Alt+T, terminal en `~`. Issue crynta/terax-ai#1359 abierto, esperando respuesta del mantenedor. Implementación LISTA y verificada manualmente por Turing0x (funciona perfecto). Rama `feat/new-terminal-home` (commit 729f826) ya en `fork`. Al recibir OK: worktree desde `origin/main`, cherry-pick, push a `fork`, PR.

## Registro

- 2026-10-17: lectura completa de docs. Verificación docs vs código. Fork `Turing0x/terax-ai` creado. PR #1358 abierto. Rama `contrib-notes` creada para estas notas.
- 2026-10-17: feature `tab.newHome` implementada en `feat/new-terminal-home`. Lint/types/tests OK. Issue #1359 abierto.
- 2026-10-17: `tab.newHome` probada a mano, funciona. Marcada lista. Siguiente funcionalidad la define Turing0x.
- 2026-10-17: reordenada auditoría: A seguridad acotada, B funcional por recorridos de usuario. Inicio A1.
