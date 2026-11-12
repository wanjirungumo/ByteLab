# Checkov Report — ByteLab (Group 1)

**Scope:** `terraform/` (network module + Terraform state backend)
**Tool:** Checkov (Prisma Cloud) v3.3.8
**Author:** Esther Ngumo Wanjiru (Cloud/DevOps)
**Task:** T16 — fix Checkov findings and document the results

## Summary

| Result | Count |
| --- | --- |
| Passed | 99 |
| Failed | 3 |
| Skipped (documented) | 8 |

The 3 remaining failures are all the same check (CKV2_AWS_5) and are expected at this stage; see "Known remaining findings".

## What was fixed

VPC flow logs (CKV2_AWS_11) — real fix. The VPC had no flow logging. We enabled flow logs for the whole VPC, delivered to a dedicated S3 bucket. Flow logs give network-level visibility (which hosts talked to which, on which ports) that complements the host-level logs Wazuh collects.

We deliver to S3 rather than CloudWatch on purpose: CloudWatch delivery needs a new IAM role, which the AWS Academy lab account does not allow us to create. S3 delivery needs only a bucket policy, so it works within the lab's permissions.

The logs bucket was hardened: public access blocked, encryption at rest (SSE-S3/AES256), versioning on, and a lifecycle rule that expires logs after 30 days and aborts incomplete uploads after 7 days.
