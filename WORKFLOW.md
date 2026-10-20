# Flujo de trabajo local

## Repos y remotes

- Checkout principal: `~/LocalProjects/Terax/terax-ai` (rama `local/mine`: upstream + cambios propios de Turing0x).
  - `origin` -> `https://github.com/crynta/terax-ai.git` (upstream, solo lectura para nosotros).
  - `fork` -> `https://github.com/Turing0x/terax-ai.git` (nuestro fork).
- Cada PR se trabaja en un worktree aparte desde `origin/main`, nunca desde `local/mine`.
- En `terax-ai`, `CLAUDE.md` está con `skip-worktree` y `.claude/` en `.git/info/exclude` (config local del orquestador; no va a ningún PR).

## Worktrees

| Ruta (`~/LocalProjects/Terax/...`) | Rama | Uso |
| --- | --- | --- |
| `terax-ai` | `local/mine` | Uso diario: upstream + todas nuestras ramas. Se compila como Terax Local |
| `terax-ai-contrib` | `contrib-notes` (huérfana) | Estas notas. Push a `fork` |
| `terax-ai-git-log-pagination` | `fix/git-log-merge-pagination` | PR #1367 |
| `terax-ai-write-symlink` | `fix/fs-write-through-symlink` | PR #1368 |
| `terax-ai-rename-dirty` | `fix/editor-rename-keeps-edits` | PR #1369 |
| `terax-ai-commit-timeout` | `fix/git-commit-timeout` | PR #1370 |
| `terax-ai-editor-save` | `fix/editor-save-feedback` | PR #1375 |

#1358 y #1360 ya no tienen worktree (sus ramas siguen en local y en `fork`).
Si se mueve la carpeta `Terax/`: `git -C terax-ai worktree repair ../terax-ai-*` y rehacer los symlinks
`node_modules` de los worktrees (`ln -sfn <ruta-absoluta>/terax-ai/node_modules node_modules`), y `cargo clean`
en `terax-ai/src-tauri` (la caché guarda rutas absolutas).

Fuera de git: `~/LocalProjects/Terax/terax-private/` (hallazgos de seguridad privados y borradores de informe). Nunca copiar su contenido a esta rama ni a PRs.

Un solo agente por worktree a la vez.

## Nuevo PR

```bash
cd ~/LocalProjects/Terax/terax-ai
git fetch origin
git worktree add -b <prefijo>/<nombre> ../terax-ai-<nombre> origin/main
cd ../terax-ai-<nombre>
pnpm install            # si hay que ejecutar checks de frontend
# ...cambios + checks (RULES.md)...
git push -u fork <prefijo>/<nombre>
gh pr create -R crynta/terax-ai --base main --head Turing0x:<prefijo>/<nombre> \
  --title "<type>(<scope>): ..." --body-file <fichero>
```

Tras el merge o cierre: `git worktree remove ../terax-ai-<nombre>` y borrar la rama del fork.

## Actualizar una rama de PR con upstream

```bash
cd ../terax-ai-<nombre>
git fetch origin && git rebase origin/main
git push --force-with-lease fork <rama>
```

## Notas (esta rama)

```bash
cd ~/LocalProjects/Terax/terax-ai-contrib
# editar STATUS.md y demás
git add -A && git commit -m "notes: ..." && git push fork contrib-notes
```

## Seguimiento de PRs

```bash
gh pr view <n> -R crynta/terax-ai --comments
gh pr checks <n> -R crynta/terax-ai
```
