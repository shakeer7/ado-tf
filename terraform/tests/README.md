# Credential-free Terraform tests

The root tests use Terraform mock providers and never contact Azure. Tests in the
shared root check that opt-out creates no Azure objects and enabling deployment
without approval is rejected. Module tests cover key security invariants. Run
`terraform test` in initialized roots and module directories. No apply is run
against a real provider by these tests.
