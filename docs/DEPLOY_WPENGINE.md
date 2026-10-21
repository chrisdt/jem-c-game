# Deploy Sunny Scout to WP Engine

Say **“deploy Sunny Scout”** when a checked browser build is ready to go live.
This authorizes the manual deployment workflow; normal commits and build ZIPs
do not upload anything. The permanent game entry will be
**https://playsunnyscout.com/play/**.

## Manual GitHub Actions command

The workflow is **Deploy Sunny Scout to WP Engine** in the repository's Actions
tab. It runs only on request. The equivalent agent command is:

```sh
gh workflow run deploy-wpengine.yml --ref main -f operation=deploy -f build_ref=browser-build
```

Use `operation=check` for a read-only SFTP/WordPress-root check, `host-key` to
retrieve the public SSH host key without sending a password, and `rollback` to
restore the previous game entry. Watch the selected run until completion with
`gh run watch RUN_ID --exit-status`; inspect its result before reporting success.
For a reproducible deployment, `build_ref` can be the full browser-build commit
SHA instead of the moving branch name.

## One-time connection setup

The target account is `sunnyscout-git@sunnyscout.sftp.wpengine.com:2222`.
The password supplied for setup must be stored as the repository Actions secret
**`WPE_SFTP_PASSWORD`**. It is not recorded in this document or source control.
The public server key is pinned in `tools/wpengine_known_hosts`, retrieved by
the read-only [host-key check](https://github.com/chrisdt/jem-c-game/actions/runs/39369381897)
on 20 October 2026. Its fingerprint is
`SHA256:kp6D7jBrR02Z/SuQtH89kLGnkm2sODLmQX87GjVm1cM`.
No Actions variable is needed for the current server key. If WP Engine rotates
it, verify the replacement before updating the file or setting the optional
Actions variable **`WPE_SFTP_KNOWN_HOSTS`** to the replacement OpenSSH line:

```text
[sunnyscout.sftp.wpengine.com]:2222 KEY_TYPE PUBLIC_HOST_KEY
```

The `host-key` operation retrieves this public information and its fingerprint
without authentication. Password authentication uses the pinned key; an
unexpected key stops the connection.

The tool detects the web root by finding `wp-admin`, `wp-content` and
`wp-includes` together. It checks the SFTP login directory, `/sites/sunnyscout`,
`/public_html` and `/htdocs`. If WP Engine uses another path, set the non-secret
Actions variable **`WPE_WEB_ROOT`** after the read-only check. The destination is
always that root's **`play`** subdirectory, never the WordPress root itself.

On 20 October 2026 the GitHub-hosted runner reached the SFTP server, while
direct SFTP from the cloud runtime was refused. The connection check stopped
because `WPE_SFTP_PASSWORD` was empty. The GitHub integration can dispatch
workflows but returns HTTP 403 for secret management, so the repository owner
must add the password under Settings → Secrets and variables → Actions.
After that, rerun `check` and then the authorized deployment. Authentication and
the actual server web root have not yet been verified.

## Local command

From the existing project checkout:

```sh
python3 -m venv .venv-deploy
.venv-deploy/bin/python -m pip install -r tools/deploy-requirements.txt
.venv-deploy/bin/python tools/deploy_wpengine.py plan
.venv-deploy/bin/python tools/deploy_wpengine.py check
.venv-deploy/bin/python tools/deploy_wpengine.py deploy
```

`plan` validates the complete build without a connection or upload. `check`
authenticates and checks the destination without changing server files. `deploy`
is the write operation. Use `--build-dir PATH` for an unzipped browser-build
folder. The default is this checkout's `build/web`.

Local commands use the same bundled public server key. A verified replacement
can be supplied in `.deploy/known_hosts` (ignored by Git) or
`WPE_SFTP_KNOWN_HOSTS`. Supply `WPE_SFTP_PASSWORD` securely as an
environment variable, or let the command prompt without echoing it. Never put a
literal password in a shell command. Cloud proxy secret placeholders are not raw
SFTP passwords; use a supported runner with a real runtime secret.

## What gets uploaded

The command validates all 31 browser files, including the 18 streamed scenery
images, matching runtime/PCK sizes, loading art and font license. Symlinked or
unexpected files are rejected. Local Godot `.import` metadata is omitted. The PHP
scoreboard endpoint is installed at stable `/play/api/leaderboard.php`. Its runtime
`/play/api/data/` folder is preserved across releases and rollback. See
[scoreboard setup](SPEEDRUN_LEADERBOARD.md) for PHP write permissions and caching.

Each complete build goes into `/play/releases/CONTENT_HASH/`. Uploads first use
a separate staging directory and every file is read back and SHA-256 checked.
Only then does the command atomically replace `/play/index.html`. Its HTML base
URL directs the engine, loading art and scenery requests to the same immutable
release, so players already using the old release retain its files. Existing
WordPress files are never overwritten or removed. Unrecognized content at
`/play/index.html` stops the deployment.

The previous game entry is kept for `rollback`. Old release folders remain;
automatic deletion is deliberately absent so open sessions and rollback keep
working. A failed upload may leave an unpublished `.upload-*` directory, but it
does not change the active game. Do not run the local uploader concurrently with
Actions; Actions queues its own deployments.

After deployment the workflow checks the public entry's release marker and all
30 static asset URLs plus the stable PHP scoreboard endpoint. The initial browser
review should cover the welcome screen,
starting camp and a trail/mine transition. If WP Engine serves an older entry,
exclude `/play/` from its HTML page cache or clear that entry's cache; release
assets already have unique URLs. The workflow does not alter WordPress caching,
PHP, plugins, DNS or HTTPS settings.
