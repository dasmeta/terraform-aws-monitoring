import importlib.util
import json
import pathlib
import unittest


SOURCE = (
    pathlib.Path(__file__).parents[2]
    / "modules/lambda-subscription/src/opsgenie-guardduty/lambda.py"
)
SPEC = importlib.util.spec_from_file_location("opsgenie_guardduty", SOURCE)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def guardduty_event():
    return {
        "id": "event-id",
        "source": "aws.guardduty",
        "detail-type": "GuardDuty Finding",
        "account": "123456789012",
        "region": "eu-central-1",
        "detail": {
            "id": "finding/id",
            "type": "UnauthorizedAccess:EC2/Example",
            "title": "Example finding",
            "description": "Example description",
            "severity": 8,
            "accountId": "123456789012",
            "resource": {
                "resourceType": "Instance",
                "instanceDetails": {"instanceId": "i-example"},
            },
            "service": {
                "action": {
                    "networkConnectionAction": {
                        "localIpDetails": {"ipAddressV4": "10.0.0.8"},
                        "remoteIpDetails": {"ipAddressV4": "192.0.2.1"},
                    }
                },
                "eventFirstSeen": "2026-09-14T10:00:00Z",
                "eventLastSeen": "2026-09-15T10:00:00Z",
                "count": 2,
            },
        },
    }


class DescriptionTests(unittest.TestCase):
    def test_description_contains_actionable_guardduty_context(self):
        description = MODULE.build_description(guardduty_event())

        for expected in (
            "UnauthorizedAccess:EC2/Example",
            "Example finding",
            "Severity score: 8",
            "AWS account: 123456789012",
            "Region: eu-central-1",
            "Instance / i-example",
            "Remote IP: 192.0.2.1",
            "First seen: 2026-09-14T10:00:00Z",
            "Last seen: 2026-09-15T10:00:00Z",
            "Event count: 2",
            "finding%2Fid",
            "Example description",
            "Action: Open the finding link",
        ):
            self.assertIn(expected, description)

        self.assertNotIn("Remote IP: 10.0.0.8", description)

    def test_resource_summary_supports_current_guardduty_resource_types(self):
        examples = (
            ({"resourceType": "ECSCluster", "ecsClusterDetails": {"name": "payments"}}, "ECSCluster / payments"),
            ({"resourceType": "EKSCluster", "eksClusterDetails": {"arn": "arn:aws:eks:example"}}, "EKSCluster / arn:aws:eks:example"),
            ({"resourceType": "Lambda", "lambdaDetails": {"functionName": "worker"}}, "Lambda / worker"),
            ({"resourceType": "Container", "containerDetails": {"id": "container-id"}}, "Container / container-id"),
            ({"resourceType": "EBSVolume", "ebsVolumeDetails": {"scannedVolumeDetails": [{"volumeArn": "arn:aws:ec2:eu-central-1:123456789012:volume/vol-1"}], "skippedVolumeDetails": [{"volumeArn": "arn:aws:ec2:eu-central-1:123456789012:volume/vol-2"}]}}, "EBSVolume / arn:aws:ec2:eu-central-1:123456789012:volume/vol-1, arn:aws:ec2:eu-central-1:123456789012:volume/vol-2"),
            ({"resourceType": "RDSDBInstance", "rdsDbInstanceDetails": {"dbInstanceIdentifier": "orders"}, "rdsDbUserDetails": {"database": "ordersdb", "user": "analyst"}}, "RDSDBInstance / orders / database ordersdb / user analyst"),
            ({"resourceType": "RDSDBUser", "rdsDbUserDetails": {"database": "ordersdb", "user": "analyst"}}, "RDSDBUser / database ordersdb / user analyst"),
            ({"resourceType": "KubernetesCluster", "kubernetesDetails": {"kubernetesWorkloadDetails": {"namespace": "prod", "name": "api"}}}, "KubernetesCluster / prod/api"),
            ({"resourceType": "ECS_TASK", "uid": "task-uid"}, "ECS_TASK / task-uid"),
        )

        for resource, expected in examples:
            with self.subTest(resource_type=resource["resourceType"]):
                self.assertEqual(expected, MODULE.resource_summary(resource))

    def test_sns_guardduty_message_retries_then_updates_by_event_alias(self):
        event = {
            "Records": [{"Sns": {"Message": json.dumps(guardduty_event())}}]
        }
        requests = []
        sleeps = []

        def request(method, path, payload=None):
            requests.append((method, path, payload))
            if len(requests) == 1:
                return 404, {}
            if method == "GET":
                return 200, {"data": {}}
            return 202, {"result": "accepted"}

        result = MODULE.handler(
            event,
            None,
            request_func=request,
            sleep_func=sleeps.append,
            max_attempts=3,
        )

        self.assertEqual({"updated": 1, "ignored": 0, "failed": 0}, result)
        self.assertEqual([2.0], sleeps)
        self.assertEqual("GET", requests[0][0])
        self.assertIn("event-id", requests[0][1])
        self.assertEqual("PUT", requests[-1][0])
        self.assertIn("Example finding", requests[-1][2]["description"])

    def test_non_guardduty_message_is_ignored(self):
        result = MODULE.handler(
            {"Records": [{"Sns": {"Message": json.dumps({"source": "aws.cloudwatch"})}}]},
            None,
            request_func=lambda *args, **kwargs: self.fail("request must not run"),
        )

        self.assertEqual({"updated": 0, "ignored": 1, "failed": 0}, result)

    def test_failed_update_raises_for_lambda_retry_and_alarm(self):
        event = {"Records": [{"Sns": {"Message": json.dumps(guardduty_event())}}]}

        with self.assertRaisesRegex(RuntimeError, "Failed to enrich 1"):
            MODULE.handler(
                event,
                None,
                request_func=lambda *args, **kwargs: (503, {"message": "unavailable"}),
                sleep_func=lambda seconds: None,
                max_attempts=1,
            )


if __name__ == "__main__":
    unittest.main()
