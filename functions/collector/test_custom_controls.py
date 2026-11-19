"""Positive, negative and missing-property fixtures for the original CHK-STG-03.

Run from repository root:
    python -m unittest discover -s functions/collector -p 'test_*.py'
"""
import unittest

import checks


class PublicAccessPreventionTests(unittest.TestCase):
    def test_explicit_enforced_passes(self):
        buckets = {"evidence-reports": {
            "iamConfiguration": {"publicAccessPrevention": "enforced"}
        }}
        result, = checks.chk_stg_03(buckets)
        self.assertEqual(result["check_id"], "CHK-STG-03")
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["resource"], "evidence-reports")
        self.assertEqual(result["evidence"]["expected"], "enforced")

    def test_inherited_fails(self):
        buckets = {"legacy-source": {
            "iamConfiguration": {"publicAccessPrevention": "inherited"}
        }}
        result, = checks.chk_stg_03(buckets)
        self.assertEqual(result["status"], "fail")
        self.assertEqual(result["evidence"]["publicAccessPrevention"], "inherited")

    def test_missing_setting_fails_closed(self):
        result, = checks.chk_stg_03({"unknown": {}})
        self.assertEqual(result["status"], "fail")
        self.assertIsNone(result["evidence"]["publicAccessPrevention"])

    def test_each_bucket_gets_independent_deterministic_result(self):
        buckets = {
            "safe": {"iamConfiguration": {"publicAccessPrevention": "enforced"}},
            "unsafe": {"iamConfiguration": {"publicAccessPrevention": "inherited"}},
        }
        results = checks.chk_stg_03(buckets)
        self.assertEqual({r["resource"]: r["status"] for r in results},
                         {"safe": "pass", "unsafe": "fail"})

    def test_public_iam_check_does_not_substitute_for_guardrail(self):
        buckets = {"without-explicit-guardrail": {
            "iamConfiguration": {
                "uniformBucketLevelAccess": {"enabled": True},
                "publicAccessPrevention": "inherited",
            }
        }}
        self.assertEqual(checks.chk_stg_01(buckets, {})[0]["status"], "pass")
        self.assertEqual(checks.chk_stg_02(buckets)[0]["status"], "pass")
        self.assertEqual(checks.chk_stg_03(buckets)[0]["status"], "fail")


if __name__ == "__main__":
    unittest.main()
