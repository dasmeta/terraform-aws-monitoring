import sys
import types
import unittest
from pathlib import Path

# Envelope construction is pure and does not call AWS.
sys.modules.setdefault("boto3", types.SimpleNamespace())
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "common"))

from canary import DEFAULT_DEVICE_ID, DEFAULT_OPERATOR_ID, REQUEST_ID_PREFIX, _build_envelope


class SoapNamespaceTests(unittest.TestCase):
    def test_uses_generic_default_identifiers(self):
        self.assertEqual(DEFAULT_DEVICE_ID, "SyntheticsMonitoring")
        self.assertEqual(DEFAULT_OPERATOR_ID, "SyntheticsMonitoring")
        self.assertEqual(REQUEST_ID_PREFIX, "SyntheticsMonitoring")

    def test_uses_the_consumer_supplied_namespace(self):
        namespace, envelope = _build_envelope(
            {
                "environment": {
                    "SOAP_VERSION": "v3",
                    "SOAP_NAMESPACE": "https://service.example/soap/v3",
                    "MONITORING_MERCHANT_ID": "example-merchant",
                    "MONITORING_CARD_NUMBER": "0000000000000000000",
                }
            }
        )

        self.assertEqual(namespace, "https://service.example/soap/v3")
        self.assertIn('xmlns:gif="https://service.example/soap/v3"', envelope)


if __name__ == "__main__":
    unittest.main()
