"""Offline regression tests for the GitHub Pages font retry gate."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "Scripts" / "build-web-pages.sh"


class PagesBuildRetryTests(unittest.TestCase):
    def exercise(self, mode):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)
            bin_dir = path / "bin"
            bin_dir.mkdir()
            npm = bin_dir / "npm"
            npm.write_text(
                "#!/bin/sh\n"
                'n="$(cat "$MOCK_COUNT" 2>/dev/null || echo 0)"\n'
                'n=$((n + 1))\n'
                'echo "$n" > "$MOCK_COUNT"\n'
                'if [ "$MOCK_MODE" = "syntax" ]; then echo "TypeScript error: broken source"; exit 2; fi\n'
                'if [ "$MOCK_MODE" = "font-twice" ] && [ "$n" -le 2 ]; then echo "An error occurred in next/font"; exit 1; fi\n'
                'if [ "$MOCK_MODE" = "always-font" ]; then echo "nextFontGoogleFontLoader error"; exit 1; fi\n'
                'echo "Build succeeded"\n'
            )
            npm.chmod(0o755)
            counter = path / "calls"
            env = {
                **os.environ,
                "PATH": f"{bin_dir}:{os.environ.get('PATH', '')}",
                "MOCK_COUNT": str(counter),
                "MOCK_MODE": mode,
                "FOLDREADY_FONT_RETRY_SLEEP_SECONDS": "0",
            }
            result = subprocess.run(
                ["bash", str(SCRIPT)], cwd=path, env=env, text=True, capture_output=True
            )
            return result, int(counter.read_text())

    def test_build_succeeds_without_retry(self):
        result, count = self.exercise("success")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(count, 1)

    def test_transient_font_failure_retries_and_succeeds(self):
        result, count = self.exercise("font-twice")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(count, 3)

    def test_non_font_failure_does_not_retry(self):
        result, count = self.exercise("syntax")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(count, 1)

    def test_font_retry_is_bounded(self):
        result, count = self.exercise("always-font")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(count, 3)


if __name__ == "__main__":
    unittest.main()
