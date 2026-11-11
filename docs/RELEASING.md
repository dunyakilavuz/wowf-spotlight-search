# Releasing Searchlight

Releases are built and published by [BigWigsMods/packager](https://github.com/BigWigsMods/packager)
(`.github/workflows/release.yml`) whenever a tag matching `v*` is pushed. Pushes to `main`
do **not** publish anything.

## What the packager produces

- One zip, `Searchlight-<tag>-forever.zip`, whose root contains only `Searchlight/`
  (`.pkgmeta`: `package-as: Searchlight` plus `move-folders: Searchlight/Searchlight: Searchlight`).
  `tools/`, `tests/`, `vendor/`, `docs/`, `.github/`, `.build/`, and the repository-level README, CHANGELOG
  and LICENSE stay out of it; the addon folder ships its own `LICENSE`, `THIRD_PARTY_NOTICES.md` and `README.md`.
- `@project-version@` in `Searchlight.toc` and `Init.lua` is replaced with the tag (for example `v0.1.2`).
  Unpackaged git checkouts show `dev` in `/searchlight` diagnostics.
- Game detection: `## Interface: 16001` maps to the packager's `forever` game type; the workflow also
  passes `-g forever`. This uploads to CurseForge game version **1.60.1** (version type 88568).
- Uploads: CurseForge (when a project ID and `CF_API_KEY` are present), Wago (when a Wago ID and
  `WAGO_API_TOKEN` are present) and a GitHub release with the zip (always, using `GITHUB_TOKEN`).
  `CHANGELOG.md` is used as the changelog text.

## One-time setup

1. Create the CurseForge project for WoW: Forever and note its numeric **Project ID**
   (project page sidebar, "About Project").
2. In GitHub → repository **Settings → Secrets and variables → Actions**:
   - Secret `CF_API_KEY`: a token from <https://legacy.curseforge.com/account/api-tokens>.
   - Variable `CF_PROJECT_ID`: the numeric project ID. (Alternative: add
     `## X-Curse-Project-ID: <id>` to the TOC lines in `tools/build_db.py`, then run
     `python3 tools/build_db.py`; see the TODO comment in `Searchlight/Searchlight.toc`.)
   - Optional Wago: secret `WAGO_API_TOKEN` (from <https://addons.wago.io/account/apikeys>) and variable
     `WAGO_PROJECT_ID` (or a TOC `## X-Wago-ID:` line). Without them, Wago is skipped.
3. Settings → Actions → General → Workflow permissions must allow "Read and write" (or keep the
   workflow's `permissions: contents: write`) so the GitHub release can be created.

## Cutting a release

```sh
python3 tools/check.py                # all validation must pass
# move the "unreleased" heading in CHANGELOG.md to the new version and commit it
git tag -a v0.1.2 -m "Searchlight v0.1.2"
git push origin v0.1.2
```

Watch the **Release** workflow in the Actions tab. Tags containing `alpha`/`beta` (for example
`v0.2.0-beta1`) are uploaded with that release type; untagged commits are never uploaded.

## Local dry run

```sh
curl -fsSLo /tmp/release.sh https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh
bash /tmp/release.sh -d -g forever -t "$PWD" -r "$PWD/.build/release"   # -d: never upload
unzip -l .build/release/*.zip
```

Requires `git`, `jq`, `curl` and `zip`.
