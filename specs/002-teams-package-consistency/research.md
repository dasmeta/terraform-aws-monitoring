# Research

- Decision: retain Lambda 6.8 and gate local_existing_package on computed archive output_size. A clean Terraform 1.14.5 reproduction passes only after deferring the filename; output_path or depends_on alone leaves the filename known and still fails.
- Alternatives: Lambda 8.x contains related fixes but widens AWS provider requirements; downgrading Terraform hides the consistency check; disabling Teams contradicts the requested behavior.
- Primary reference: https://developer.hashicorp.com/terraform/language/functions/fileexists
- No unresolved design clarification remains.
