#!/usr/bin/env python3
"""Export the R04 review scene without changing the game's project settings."""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def run_godot(*arguments: str) -> None:
    result = subprocess.run(["godot", *arguments], check=True, capture_output=True, text=True)
    output = result.stdout + result.stderr
    print(output, end="", flush=True)
    # Godot can return zero after a script/resource loading error. Never
    # package a review build that could not load its actual entry scene.
    if "ERROR:" in output:
        raise SystemExit("Godot reported an error; the preview export was stopped.")


def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    output = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else repo / "build/rowan-dialogue-review/index.html"
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="sunny-rowan-preview-") as directory:
        stage = Path(directory)
        # A release Web engine cannot override its main scene on the command
        # line. Stage a separate project so normal startup remains unchanged.
        for folder in ("assets", "environment", "ui", "previews", "addons", "web", "shaders"):
            shutil.copytree(repo / folder, stage / folder)
        for source in repo.iterdir():
            if source.is_file() and source.suffix in (".gd", ".uid", ".tscn", ".tres", ".cfg"):
                shutil.copy2(source, stage / source.name)
        settings = (repo / "project.godot").read_text()
        original = 'run/main_scene="res://startup.tscn"'
        if settings.count(original) != 1:
            raise SystemExit("The normal startup setting changed; check the preview exporter before continuing.")
        (stage / "project.godot").write_text(settings.replace(original, 'run/main_scene="res://previews/rowan_dialogue.tscn"'))
        cache = repo / ".godot"
        if cache.exists():
            shutil.copytree(cache, stage / ".godot", ignore=shutil.ignore_patterns("editor", "exported"))
        run_godot("--headless", "--path", str(stage), "--editor", "--import", "--quit")
        run_godot("--headless", "--path", str(stage), "res://previews/rowan_dialogue.tscn", "--quit-after", "3")
        run_godot("--headless", "--path", str(stage), "--export-release", "Web", str(output))
    print(f"Rowan speech bubble review build: {output}")


if __name__ == "__main__":
    main()
