# Sunny Scout deployment workflow

When the user says **deploy**, **deploy Sunny Scout** or **deploy to WP Engine**,
use [docs/DEPLOY_WPENGINE.md](docs/DEPLOY_WPENGINE.md). A request to edit, build,
commit or provide a ZIP alone does not authorize a production upload.

- The production entry is `https://playsunnyscout.com/play/` on WP Engine.
- Use the existing checkout. Complete the requested changes and their relevant
  checks, export/package the full Web build, and publish `main` and the compiled
  `browser-build` branch before deploying that build.
- Prefer the manually dispatched `deploy-wpengine.yml` GitHub Actions workflow.
  It supports `check`, `host-key`, `deploy` and `rollback`; it has no push trigger.
- Use existing GitHub authentication. Secret values belong in GitHub Actions
  secrets or a securely supplied runtime variable, never tracked files, command
  arguments, documentation, logs or workflow YAML. Inspect secret names only.
- SFTP host: `sunnyscout.sftp.wpengine.com`, port `2222`, user `sunnyscout-git`.
  Resolve and verify the WordPress web root; only its `play` child is a deployment
  target. Leave WordPress files alone.
- Pin the SSH host key. Never disable host-key checking to make a connection work.
- After an authorized deployment, wait for the Actions result and check the public
  `/play/` entry and streamed scenery. Report the deployed build/release and URL.
  Distinguish a completed upload from successful public browser verification.
- If direct SFTP or GitHub API access is blocked, diagnose the actual connection
  failure and report it. Do not claim the game is deployed or request a duplicate
  password solely because a proxy-backed credential looks like a placeholder.
