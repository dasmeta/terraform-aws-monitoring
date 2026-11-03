# Plan

1. Add a small shared formatter in the Security Hub Lambda source directory. Both immediate and digest functions import it, so one remediation group has one stable action and title.
2. Use concise initial context when the first urgent finding arrives, then use aggregate counts in the digest. Keep the same alias and priority. Bump the stored format version so open alerts are enriched once.
3. Test representative group identities and both delivery paths. Pin the existing consumer to the reviewed immutable module commit and inspect its plan before applying.

## Risks and rollback

- Existing open alerts receive one silent title/description update. ChatOps messages already posted by Opsgenie retain their original snapshot.
- Roll back by pinning the prior module commit; no state schema or resource addresses change.
