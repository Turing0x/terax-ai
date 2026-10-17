# Terax en una página

Terminal open source "AI-native" (se define como ADE). macOS, Linux, Windows y WSL. ~7-8 MB,
sin telemetría, IA con claves propias (BYOK). Un solo mantenedor: @crynta. Licencia Apache-2.0.

## Stack

- **Backend**: Tauri 2 + Rust (~29k líneas). `portable-pty`, `keyring`, `reqwest`, crates `ignore`/`grep-*`.
- **Frontend**: React 19, TypeScript, Vite 8, Tailwind v4, shadcn/ui (hugeicons), Zustand, React Compiler (~119k líneas).
- **Terminal**: libghostty-vt compilado a WASM, una instancia por panel. Render WebGPU (un canvas compartido por ventana) con WebGL como respaldo. xterm.js ya no existe.
- **Editor**: CodeMirror 6, vim mode, LSP opcional y perezoso, autocompletado IA, format-on-save.
- **IA**: Vercel AI SDK v6. Cloud (OpenAI, Anthropic, Google, xAI, Cerebras, Groq, DeepSeek, Mistral, OpenRouter, openai-compatible) y locales (LM Studio, MLX, Ollama).

## Arquitectura

- **Dos procesos**: Rust tiene todo el acceso al SO. La webview solo usa `invoke()` sobre comandos de `src-tauri/src/lib.rs` (`generate_handler!`).
- **PTY**: un stream multiplexado por ventana (esquema `terax-pty`, `poll`/`ack`), hilo hub único, control por créditos (1 MiB en vuelo, 2 MiB por terminal), cadencia según presentación (focused 4 ms, visible 16 ms, hidden 100 ms, ocluida 250 ms).
- **Shell integration**: scripts en `src-tauri/src/modules/pty/scripts/` emiten OSC 7 (cwd) y OSC 133 (bloques). Windows: ConPTY + `CONPTY_LIFECYCLE_LOCK` + Job Object (`proc/job.rs`).
- **Seguridad**: deny-list de rutas secretas (`src/modules/ai/lib/security.ts`, lectura y escritura), `WorkspaceRegistry` para cwd autorizados, proxy HTTP de IA con anti-SSRF y DNS pinning (`net.rs`), claves en keychain.
- **CLI**: `terax open <file>` vía endpoint local autenticado (`control.rs`, crates `terax-cli` y `terax-control-protocol`).
- **Frontend modular**: `src/modules/<área>/` con barrel `index.ts`; `App.tsx` solo coordina. Tabs nunca se desmontan (se ocultan).

## Mapa rápido

| Área | Rust | Frontend |
| --- | --- | --- |
| Terminal / PTY | `modules/pty/` | `modules/terminal/` (`ghostty/gpu`, `ghostty/webgl`) |
| Ficheros | `modules/fs/` | `modules/explorer/`, `modules/editor/` |
| Git | `modules/git/` | `modules/source-control/`, `modules/git-history/` |
| IA | `net.rs`, `ai_sessions.rs`, `shell/` | `modules/ai/` (`tools/`, `lib/agent.ts`, `agents/`) |
| Agentes externos | `agent.rs`, `pty/agent_detect.rs` | `modules/agents/` |
| LSP | `modules/lsp/` | `modules/lsp/` |
| Workspace / WSL | `workspace.rs` | `modules/workspace/`, `modules/spaces/` |
| CLI | `control.rs`, `crates/` | `modules/control/` |

## Herramientas de IA (verificado 2026-10-17)

- Auto: `read_file`, `list_directory`, `grep`, `glob`, `bash_logs`, `bash_list`, `bash_kill`, `get_terminal_output`, `suggest_command`, `open_preview`, `todo_write`, `read_agent_output`, `run_subagent`.
- Con aprobación: `write_file`, `edit`, `multi_edit`, `create_directory`, `bash_run`, `bash_background`, `spawn_coding_agent`, `send_to_agent`.

## Docs upstream útiles

`TERAX.md` (fuente de verdad), `CONTRIBUTING.md`, `ROADMAP.md`, `docs/architecture/*`
(two-process-model, pty-transport-v2, pty-shell-integration, security-model, ai-subsystem,
terminal-renderer-v2, cli-control), `docs/contributing/testing.md`.
