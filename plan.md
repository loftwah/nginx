# NGINX Version Check Workflow Planning Document

## Purpose

This document outlines the requirements and workflow for a GitHub Action that automates checking for the latest stable NGINX version, comparing it with the version in the Dockerfile, analyzing configuration changes using the Google Gemini API, performing inline testing, and creating a pull request (PR). The workflow uses explicit permissions for the default GITHUB_TOKEN, the stable peter-evans/create-pull-request\@v7.0.5 action, and includes comprehensive context (changelogs, Dockerfile, nginx.template, version details) for Gemini analysis.

## Functional Requirements

1. **NGINX Version Check**:

   - Extract the current NGINX version from the Dockerfile (e.g., FROM public.ecr.aws/nginx/nginx:1.28.0).

   - Fetch the latest stable NGINX version from the NGINX GitHub releases API (https\://api.github.com/repos/nginx/nginx/releases).

   - Compare versions to determine if an update is needed.

2. **Changelog Retrieval**:

   - If a newer stable version is available, retrieve changelogs for all versions between the current version (exclusive) and the target version (inclusive) from NGINX GitHub release notes.

   - Combine changelogs into a single formatted text block for Gemini analysis and PR inclusion.

3. **Configuration Analysis**:

   - Use the Google Gemini API to analyze:

     - Combined changelogs for all versions between current and target.

     - Current nginx.template configuration.

     - Current Dockerfile content.

     - Current NGINX version and target NGINX version.

   - Generate recommendations for:

     - Configuration changes in nginx.template or Dockerfile.

     - Compatibility issues or deprecated features.

     - Adjustments needed for the version upgrade (e.g., new dependencies, updated commands).

   - Require a Gemini API key stored as a GitHub Secret (GEMINI_API_KEY).

4. **Inline Testing**:

   - Build a Docker image using the updated Dockerfile with the new NGINX version.

   - Validate NGINX configuration using nginx -t in the container.

   - Run the test.sh script in a containerized environment (using docker-compose to match docker-compose.yml) to verify functionality (health checks, proxy, JSON logging, gzip compression, headers).

   - Fail the workflow if configuration validation or tests fail, preventing PR creation.

5. **Pull Request Creation**:

   - If tests pass and an update is needed, update the Dockerfile with the new NGINX version.

   - Create a PR using peter-evans/create-pull-request\@v7.0.5 with:

     - Title: "Update NGINX to version X.Y.Z".

     - Body: Combined changelogs, Gemini analysis, test results, and changes made.

     - Branch: update-nginx-X.Y.Z.

     - Labels: nginx-update, automated-pr.

   - Delete the branch after PR merge or closure.

   - Use the default GITHUB_TOKEN with explicitly defined permissions.

6. **Scheduling and Triggering**:

   - Run weekly on Mondays at midnight UTC.

   - Support manual triggering via workflow dispatch.

## Non-Functional Requirements

1. **Security**:

   - Define workflow permissions explicitly using the permissions key:

     - contents: write (read/write repository files, commit changes).

     - pull-requests: write (create/manage PRs).

   - Store the Gemini API key securely in GitHub Secrets.

   - Prevent sensitive data exposure in logs or PR descriptions.

   - Follow least privilege by limiting permissions to only what’s required.

2. **Reliability**:

   - Handle API failures (GitHub, Gemini) with clear error messages and graceful exits.

   - Validate JSON responses from APIs to avoid parsing errors.

   - Ensure tests comprehensively validate critical functionality.

3. **Performance**:

   - Minimize API calls (e.g., fetch all relevant NGINX release data in one call).

   - Cache Docker layers to optimize build and test execution.

   - Optimize changelog retrieval by filtering relevant versions efficiently.

4. **Maintainability**:

   - Use clear step names and comments in the workflow for readability.

   - Design a modular workflow for easy updates or extensions.

   - Log detailed outputs for debugging (e.g., versions, test results, changelog summary).

5. **Permissions**:

   - Use the permissions key at the workflow level to scope the default GITHUB_TOKEN:

     - contents: write: Read Dockerfile, nginx.template, test.sh, and commit changes.

     - pull-requests: write: Create and manage PRs.

   - Avoid additional permissions (e.g., issues, checks) to minimize scope.

   - Do not rely on repository-wide permissions in Settings > Actions > General.

   - No custom GITHUB_TOKEN secret or personal access token required.

## Technical Requirements

1. **Environment**:

   - Runner: ubuntu-latest for compatibility with Docker and tools.

   - Dependencies: jq (JSON parsing), curl (API calls), docker (building/testing).

2. **Inputs**:

   - Dockerfile path (default: Dockerfile).

   - nginx.template path for Gemini analysis.

   - test.sh path for testing.

3. **Outputs**:

   - Current NGINX version.

   - Target stable NGINX version.

   - Combined changelogs for intermediate and target versions.

   - Gemini analysis results.

   - Test results (pass/fail).

   - PR URL (if created).

## Workflow Outline

1. **Workflow Configuration**:

   - **Name**: Check NGINX Version and Create PR

   - **Triggers**:

     - Schedule: cron: '0 0 \* \* 1' (Monday midnight UTC).

     - Manual: Workflow dispatch.

   - **Permissions**:

     - contents: write (read/write repository files).

     - pull-requests: write (create/manage PRs).

2. **Job: Check NGINX Version and Create PR**:

   - **Environment**: ubuntu-latest.

   - **Steps**:

     1. **Checkout Repository**:

        - Use actions/checkout\@v4.2.2 to clone the repository.

        - Requires contents: read (included in contents: write).

     2. **Install Dependencies**:

        - Install jq, curl, and Docker using apt-get.

     3. **Extract Current NGINX Version**:

        - Parse Dockerfile to extract NGINX version (e.g., using regex or grep).

        - Output: Current version.

     4. **Fetch Latest Stable NGINX Version**:

        - Query NGINX GitHub releases API.

        - Filter for latest stable release and extract version.

        - Output: Target version.

     5. **Compare Versions**:

        - Compare current and target versions.

        - Output: needs_update (true/false).

     6. **Get Changelogs**:

        - If needs_update is true, fetch release notes for all versions between current (exclusive) and target (inclusive).

        - Sort versions numerically to ensure correct order.

        - Combine changelogs into a single text block, preserving version headers.

        - Output: Combined changelog text.

     7. **Analyze with Gemini**:

        - If needs_update is true, send to Gemini API:

          - Combined changelogs.

          - nginx.template content.

          - Dockerfile content.

          - Current and target NGINX versions.

        - Prompt Gemini to:

          - Identify configuration changes needed in nginx.template or Dockerfile.

          - Highlight compatibility issues or deprecated features.

          - Suggest adjustments for the version upgrade (e.g., new dependencies).

        - Use GEMINI_API_KEY from secrets.

        - Output: Analysis text.

     8. **Update Dockerfile**:

        - If needs_update is true, update Dockerfile with target NGINX version.

     9. **Build and Test Docker Image**:

        - Build Docker image with updated Dockerfile.

        - Run nginx -t in the container to validate configuration.

        - Execute test.sh in a containerized environment using docker-compose (matching docker-compose.yml setup).

        - Verify test success (e.g., "All tests passed").

        - Output: Test results.

        - Fail workflow if nginx -t or tests fail, logging details.

     10. **Create Pull Request**:

         - If needs_update is true and tests pass, create PR using peter-evans/create-pull-request\@v7.0.5.

         - PR details:

           - Branch: update-nginx-\<version>.

           - Commit message: "Update NGINX to version X.Y.Z".

           - Title: "Update NGINX to version X.Y.Z".

           - Body: Combined changelogs, Gemini analysis, test results, changes.

           - Labels: nginx-update, automated-pr.

           - Delete branch after merge/closure.

         - Use default GITHUB_TOKEN with pull-requests: write.

         - Requires contents: write and pull-requests: write.

3. **Error Handling**:

   - Log and exit on GitHub or Gemini API failures.

   - If Gemini API fails, include a note in PR body (if created) but proceed if tests pass.

   - If tests or nginx -t fail, skip PR creation and log detailed output.

4. **Outputs**:

   - Log update status (needed/not needed).

   - Log test results.

   - Provide PR URL if created.

## Additional Considerations

- **Action Version**:

  - Use peter-evans/create-pull-request\@v7.0.5 for stability, as recommended by the GitHub Marketplace (https\://github.com/marketplace/actions/create-pull-request). Avoid @main or @v7 for production.

- **Permissions**:

  - Explicit permissions key ensures the default GITHUB_TOKEN has only necessary access.

  - No custom GITHUB_TOKEN secret or personal access token is needed.

- **Changelog Handling**:

  - Retrieve changelogs for all intermediate versions to capture cumulative changes (e.g., if upgrading from 1.26.0 to 1.28.0, include 1.26.1, 1.26.2, 1.27.x, 1.28.0).

  - Sort versions numerically to ensure correct changelog order.

  - Format changelogs clearly with version headers for readability in PR and Gemini analysis.

- **Gemini Analysis**:

  - Craft a precise prompt including:

    - Combined changelogs with version numbers.

    - Full nginx.template and Dockerfile contents.

    - Explicit mention of current and target versions.

  - Request Gemini to analyze for:

    - Configuration syntax changes.

    - Deprecated directives or modules.

    - New features requiring configuration updates.

    - Dockerfile dependency changes (e.g., apt-get packages).

  - Handle API rate limits or errors with fallback messages in the PR.

- **Testing**:

  - Use docker-compose to replicate the production setup in docker-compose.yml.

  - Run nginx -t before test.sh to catch configuration errors early.

  - Ensure test.sh validates all critical features (health checks, proxy, logging, compression, headers).

- **Optimization**:

  - Cache Docker layers for faster builds.

  - Fetch release data once and filter for both version and changelogs to minimize API calls.

- **Repository Setup**:

  - Ensure Actions are enabled in repository settings.

  - Verify test.sh is executable and compatible with the runner.

  - Store GEMINI_API_KEY in GitHub Secrets.

  - Configure repository permissions to allow GitHub Actions to create PRs (Settings > Actions > General > Allow GitHub Actions to create and approve pull requests).

## Notes

- The workflow respects .gitignore (e.g., ignores build_and_push.sh) and processes only relevant files (Dockerfile, nginx.template, test.sh).

- The peter-evans/create-pull-request\@v7.0.5 action handles uncommitted changes and respects .gitignore.

- Inline testing with nginx -t and test.sh ensures configuration and functionality are validated before PR creation.

- Comprehensive Gemini analysis with changelogs, Dockerfile, nginx.template, and version details provides actionable recommendations.
