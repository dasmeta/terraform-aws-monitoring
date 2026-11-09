"""Exercise the production package argument with real Terraform evaluation.

AWS mocks do not consume Lambda ZIPs, so the native subscription test cannot
detect filesystem-function consistency failures. This fixture uses a local
terraform_data consumer with the Lambda 6.8 package-existence expression.
Only the archive provider and Terraform's built-in provider are used.
"""

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "modules/lambda-subscription/main.tf"


class PackageConsistencyTest(unittest.TestCase):
    def test_clean_and_existing_generated_package(self):
        terraform = shutil.which("terraform")
        self.assertIsNotNone(terraform, "Terraform 1.13+ is required")
        source = MODULE.read_text()
        argument = re.search(r"^\s*local_existing_package\s*=\s*(.+)$", source, re.M)
        self.assertIsNotNone(argument, "The subscription must pass a local package")

        with tempfile.TemporaryDirectory(prefix="notification-package-") as temp:
            directory = Path(temp)
            (directory / "consumer").mkdir()
            (directory / "consumer/main.tf").write_text('''
variable "local_existing_package" { type = string }
locals {
  was_missing = var.local_existing_package != null ? !fileexists(var.local_existing_package) : false
}
resource "terraform_data" "consumer" { input = local.was_missing }
''')
            # Keep the producer deferred to apply, as happens behind a new SNS
            # topic. The argument is read from production rather than copied.
            (directory / "main.tf").write_text('''
terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8"
    }
  }
}
locals { lambda_function_output_path = "${path.module}/package.zip" }
resource "terraform_data" "gate" { input = "defer package creation" }
data "archive_file" "lambda_code_zip" {
  type        = "zip"
  output_path = local.lambda_function_output_path
  source {
    content  = "def handler(event, context): return {}"
    filename = "lambda.py"
  }
  depends_on = [terraform_data.gate]
}
module "consumer" {
  source = "./consumer"
  local_existing_package = ''' + argument.group(1) + '''
  depends_on = [data.archive_file.lambda_code_zip]
}
''')
            init = ["init", "-backend=false", "-input=false", "-no-color"]
            if os.environ.get("TERRAFORM_PLUGIN_DIR"):
                init.append("-plugin-dir=" + os.environ["TERRAFORM_PLUGIN_DIR"])

            def run(*arguments):
                result = subprocess.run(
                    [terraform, *arguments], cwd=directory,
                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    timeout=180,
                )
                self.assertEqual(result.returncode, 0, result.stdout)

            run(*init)
            self.assertFalse((directory / "package.zip").exists())
            run("apply", "-auto-approve", "-input=false", "-no-color")
            self.assertGreater((directory / "package.zip").stat().st_size, 0)
            run("apply", "-auto-approve", "-input=false", "-no-color")


if __name__ == "__main__":
    unittest.main()
