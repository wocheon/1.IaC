#!/bin/bash

CUSTOM_ROLE_MOUDLE="module.iam_custom_role.google_project_iam_custom_role.iam_custom_role"
CUSTOM_ROLE_ID="projects/gcp-in-ca/roles/terraform_test_customrole_lmsss"


terraform import ${CUSTOM_ROLE_MOUDLE} ${CUSTOM_ROLE_ID}
