import sys
import types
import unittest
from pathlib import Path

# Secret retrieval is not exercised by these pure URL-signing tests.
sys.modules.setdefault("boto3", types.SimpleNamespace())
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "common"))

from canary import DEFAULT_DEVICE_ID, _urlencode_form


class UrlEncodingTests(unittest.TestCase):
    def test_uses_a_generic_default_device_identifier(self):
        self.assertEqual(DEFAULT_DEVICE_ID, "SyntheticsMonitoring")

    def test_uses_lowercase_percent_escapes_for_the_signed_url(self):
        self.assertEqual(
            _urlencode_form("https://service.example/api/cards"),
            "https%3a%2f%2fservice.example%2fapi%2fcards",
        )


if __name__ == "__main__":
    unittest.main()
