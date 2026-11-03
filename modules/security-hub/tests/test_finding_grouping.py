"""Regression tests for remediation groups used by urgent finding delivery."""

import importlib.util
import pathlib
import unittest


ROUTER = pathlib.Path(__file__).resolve().parents[1] / "functions" / "finding_router.py"
spec = importlib.util.spec_from_file_location("finding_router", ROUTER)
router = importlib.util.module_from_spec(spec)
spec.loader.exec_module(router)


def finding(identifier, resource, product="Inspector"):
    return {
        "Id": identifier,
        "AwsAccountId": "123456789012",
        "ProductArn": "arn:aws:securityhub:eu-central-1::product/aws/inspector",
        "ProductName": product,
        "Title": identifier,
        "Resources": [resource],
    }


class InspectorGroupingTests(unittest.TestCase):
    def test_ec2_cves_on_same_instance_share_group(self):
        resource = {"Type": "AwsEc2Instance", "Id": "arn:aws:ec2:eu-central-1:123456789012:instance/i-1",
                    "Details": {"AwsEc2Instance": {"ImageId": "ami-1"}}}
        first = router._group_identity(finding("CVE-1", resource))
        second = router._group_identity(finding("CVE-2", resource))
        self.assertEqual(first["key"], second["key"])
        self.assertIn("i-1", first["label"])

    def test_ecr_cves_share_image_digest_but_not_repository(self):
        def image(repo, digest):
            return {"Type": "AwsEcrContainerImage", "Id": f"arn:aws:ecr:eu-central-1:123456789012:repository/{repo}",
                    "Details": {"AwsEcrContainerImage": {"RepositoryName": repo, "ImageDigest": digest}}}
        first = router._group_identity(finding("CVE-1", image("api", "sha256:aaa")))
        self.assertEqual(first["key"], router._group_identity(finding("CVE-2", image("api", "sha256:aaa")))["key"])
        self.assertNotEqual(first["key"], router._group_identity(finding("CVE-3", image("api", "sha256:bbb")))["key"])
        self.assertNotEqual(first["key"], router._group_identity(finding("CVE-4", image("web", "sha256:aaa")))["key"])

    def test_ecr_image_id_without_details_shares_group(self):
        image_id = "arn:aws:ecr:eu-central-1:123456789012:repository/api/sha256:" + "a" * 64
        resource = {"Type": "AwsEcrContainerImage", "Id": image_id}
        self.assertEqual(router._group_identity(finding("CVE-1", resource))["key"],
                         router._group_identity(finding("CVE-2", resource))["key"])

    def test_lambda_cves_share_resource(self):
        resource = {"Type": "AwsLambdaFunction", "Id": "arn:aws:lambda:eu-central-1:123456789012:function:worker:3"}
        self.assertEqual(router._group_identity(finding("CVE-1", resource))["key"],
                         router._group_identity(finding("CVE-2", resource))["key"])

    def test_missing_target_keeps_finding_specific_group(self):
        resource = {"Type": "AwsEcrContainerImage", "Id": "arn:aws:ecr:eu-central-1:123456789012:repository/api"}
        self.assertNotEqual(router._group_identity(finding("CVE-1", resource))["key"],
                            router._group_identity(finding("CVE-2", resource))["key"])

    def test_non_inspector_grouping_is_unchanged(self):
        resource = {"Type": "AwsEc2Instance", "Id": "arn:aws:ec2:eu-central-1:123456789012:instance/i-1"}
        self.assertNotEqual(router._group_identity(finding("control-1", resource, "Security Hub"))["key"],
                            router._group_identity(finding("control-2", resource, "Security Hub"))["key"])


if __name__ == "__main__":
    unittest.main()
