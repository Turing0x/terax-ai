# Editor: ficheros que no se guardan (2026-10-20)

## Síntoma

Reportado por Turing0x en Terax Local: un fichero abierto (`.env` de un backend) se edita, se pulsa guardar y
el cambio no llega a disco, sin aviso claro. Intermitente.

## Lo descartado

- Backend: `fs_write_file` registra `log::warn!` en cada fallo de escritura. `Terax Local.log` no tiene
  ninguno, así que la escritura no falló en Rust: o no llegó a invocarse o se descartó en el frontend.
- No hay tratamiento especial de `.env` en editor ni en `fs` (la deny-list de secretos es solo del agente IA).

## Hipótesis (por probabilidad)

| # | Causa | Ubicación | Efecto |
| --- | --- | --- | --- |
| H1 | Conflicto de mtime espurio: si el mtime en disco no coincide con el conocido, `saveNow` muestra el toast "File changed on disk" y **no escribe**. Se repite en cada Cmd+S hasta pulsar Overwrite. El toast se cierra solo y es fácil perderlo. Causas espurias: herramientas que tocan el mtime sin cambiar contenido (watchers de dev, git, `touch`), o un cambio con buffer limpio que el watcher no entregó | `useDocument.ts` `saveNow` | "no se guarda de ninguna manera" |
| H2 | Errores silenciados: un `fs_write_file` rechazado se pierde (`void ...save()` en `App.tsx`, `:w` de vim; el autosave solo hace `console.error`) | `App.tsx`, `EditorPane.tsx`, `useDocument.ts` | no guarda y no avisa |
| H3 | `dirtyRef` se actualiza en un `useEffect` (tras el render). Un `reload` del watcher que resuelve en ese hueco ve el buffer limpio y adopta el contenido de disco encima de lo recién tecleado | `useDocument.ts` | edición perdida |
| H4 | Fichero symlink: la escritura sustituye el enlace por un fichero normal y el destino real no cambia (F-8) | `fs/file.rs` | ya corregido en PR #1368 |

## Arreglo (rama `fix/editor-save-feedback`, worktree `../terax-ai-editor-save`)

1. H1: ante un mtime distinto, leer disco; si el contenido (normalizado LF) es igual al último guardado,
   no hay conflicto real: escribir. Solo un contenido distinto es conflicto. El toast de conflicto pasa a
   persistente (no se cierra solo).
2. H2: `performSave` captura cualquier error y muestra `toast.error("Could not save <fichero>")` con el
   mensaje. El autosave también avisa (una vez por fichero hasta que vuelva a guardar bien).
3. H3: `dirtyRef` se actualiza de forma síncrona en cada `setDirty`.
4. Test de la lógica pura de decisión (conflicto real vs. espurio).

Si con esto vuelve a pasar, el toast dirá ahora el motivo exacto.

## Estado (2026-10-20)

- Rama `fix/editor-save-feedback`: `7303f0d` (fix) + `79eb0a3` (cerrar toasts obsoletos, hallazgo del verificador).
  PR [#1375](https://github.com/crynta/terax-ai/pull/1375). Falta la prueba manual: marcar la casilla en el PR tras probar.
- Verificador independiente: APROBADO. Hallazgos bajos corregidos. Uno aceptado: si en disco solo cambió el fin de
  línea, se escribe con el EOL detectado al abrir.
- Integrado en `local/mine` (`9da9b18`) junto a #1358, #1360, #1367, #1368, #1369, #1370 y `feat/new-terminal-home`.
  Conflicto trivial en `useDocument.ts` con #1369: import y dependencias del efecto de carga. El autosave re-armado tras un
  rename también avisa con toast.
- Checks en `local/mine`: biome 0 errores (89 warnings previos), tsc OK, vitest 220 ficheros / 2041 tests, clippy
  `-D warnings` OK, `cargo test --locked` 670 OK (1 ignorado).
- `Terax Local.app` compilado el 2026-10-20 12:34 en `terax-ai/src-tauri/target/release/bundle/macos/`. **No instalado.**

## Prueba manual (tras instalar)

1. Abrir un fichero y editarlo. Desde una terminal, `touch <fichero>`. Cmd+S: guarda sin aviso de conflicto.
2. Editar en Terax y, desde fuera, cambiar el contenido (`echo x >> <fichero>`). Cmd+S: aparece "File changed on disk" y
   no se cierra solo. Overwrite guarda la versión del editor.
3. `chmod 444` sobre el directorio del fichero (o un fichero en un sitio sin permisos). Cmd+S: "Could not save <fichero>"
   con el motivo. Restaurar permisos y guardar: el aviso desaparece.
4. Con el aviso de conflicto abierto, cerrar la pestaña: el aviso desaparece.

## Instalar Terax Local desde `local/mine` (manual)

Requisitos: Terax Local cerrado, Rust (`~/.cargo/env`) y pnpm.

Opción A, script (fusiona de nuevo las ramas de `FEATURES`, que ya están dentro, así que no cambia nada; luego instala
deps con el lockfile, compila y reemplaza la app):

```bash
~/LocalProjects/Terax/terax-ai-contrib/scripts/local-install.sh            # sin traer upstream
~/LocalProjects/Terax/terax-ai-contrib/scripts/local-install.sh --update   # antes fusiona origin/main
```

Opción B, a mano:

```bash
cd ~/LocalProjects/Terax/terax-ai
git switch local/mine && git pull --ff-only fork local/mine
. ~/.cargo/env
pnpm install --frozen-lockfile
pnpm tauri build --bundles app --config '{"productName":"Terax Local","identifier":"app.crynta.terax.local","bundle":{"createUpdaterArtifacts":false},"plugins":{"updater":{"endpoints":["https://127.0.0.1:9/latest.json"]}}}'
rm -rf "/Applications/Terax Local.app"
cp -R "src-tauri/target/release/bundle/macos/Terax Local.app" /Applications/
xattr -dr com.apple.quarantine "/Applications/Terax Local.app"
```

El build del 2026-10-20 ya está hecho. Para instalar solo ese build, basta con los tres últimos comandos.

Problemas conocidos:
- Si `pnpm <script>` falla en la comprobación de dependencias (traza `runDepsStatusCheck`), ejecutar `pnpm install
  --frozen-lockfile`, o lanzar con `npm_config_verify_deps_before_run=false`.
- Si la compilación de Rust busca rutas viejas (`failed to read plugin permissions ... LocalProjects/terax-ai/...`),
  ejecutar `cd src-tauri && cargo clean`.
- Para volver a la versión anterior de `local/mine`: `git switch local/mine && git reset --hard backup/local-mine-pre-merge`
  (destructivo, descarta la integración).
