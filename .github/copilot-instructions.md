# MarkLogic Docker Build System (Copilot + Contributor Guidance)

This file is optimized for day-to-day contributor workflow and for GitHub Copilot context.
If you are using Copilot/AI to modify this repo, follow the **How Copilot Should Work** rules first.

## How Copilot Should Work

- Prefer the `Makefile` targets over ad-hoc commands (build/test/lint/scan).
- Keep changes minimal and aligned with existing patterns; avoid refactors unless requested.
- Treat these as **sources of truth**:
  - Build behavior: `Makefile` and `dockerFiles/*`
  - Runtime behavior: `src/scripts/start-marklogic*.sh`
  - Test expectations: `test/docker-tests.robot`, `test/structure-test.yaml`, `test/keywords.resource`
  - User documentation: `README.md`, `docker-compose/*.yaml`
- When changing behavior (env vars, logs, endpoints, defaults), update the relevant tests and docs in the same PR.
- Do not introduce new build systems, new base images, or extra “nice-to-have” tooling without an explicit request.
- Security rules:
  - Never print secrets/credentials to logs.
  - Prefer Docker secrets (`/run/secrets/*`) over env vars for credentials.
  - Avoid adding packages unless required; vulnerability surface is tightly managed.

## Change Checklist (Common Work)

- **Startup scripts (`src/scripts/*.sh`)**
  - Preserve existing log phrasing unless you also update Robot tests that match logs.
  - Preserve the root vs rootless behavioral differences (sudo usage, config write mode, converter install).
- **Dockerfile templates (`dockerFiles/*`)**
  - Keep the multi-stage + flattened final stage pattern (`COPY --from=builder / /`).
  - Keep ownership/permissions correct for rootless (`marklogic_user:users`, UID 1000).
  - If you add/remove files, update `test/structure-test.yaml` accordingly.
- **Env vars / secrets**
  - Keep naming consistent across `README.md`, `docker-compose/*.yaml`, Dockerfiles, and tests.
  - Canonical secret targets: `mldb_admin_username`, `mldb_admin_password`, `mldb_wallet_password`.
- **Tests**
  - Add/adjust Robot assertions when behavior or logs change.
  - Use the `long_running` tag for slow/integration-heavy tests.

## Local Development Notes

- Use `make lint` to run ShellCheck + Hadolint.
- Use `make test` for `structure-test` + Robot tests.
- This repo builds images for `linux/amd64` by default.
- macOS note: `make structure-test` uses GNU-style `sed -i` (GNU sed syntax); on macOS you may need GNU sed (`gsed`) or run the build/test in a Linux container/VM.

## Project Overview

This repository builds and maintains Docker images for **MarkLogic Server**, a multi-model NoSQL database. The project supports multiple base images (UBI8/UBI9) with both root and rootless variants, includes security hardening via OpenSCAP, and supports FIPS-enabled configurations.

**Key directories:**
- `dockerFiles/` - Dockerfile templates for different image variants
- `src/scripts/` - Container initialization scripts (`start-marklogic.sh`, `start-marklogic-rootless.sh`)
- `test/` - Robot Framework test suite for container validation
- `docker-compose/` - Example cluster configurations

## Build Architecture

### Multi-Stage Build Process

Images are built in two stages to reduce final image size:
1. **Builder stage**: Installs MarkLogic RPM, creates system user, adds TINI init system
2. **Final stage**: Copies from builder, flattens layers, removes unnecessary packages

**Image variants** (controlled by `docker_image_type` parameter):
- `ubi` / `ubi9` - Root images on RedHat Universal Base Image
- `ubi-rootless` / `ubi9-rootless` - Hardened rootless images (user `marklogic_user:1000`)

### Build Commands

Use the `Makefile` for all build operations:

```bash
# Build image (specify RPM package and image type)
make build docker_image_type=ubi9-rootless package=MarkLogic-11.3.nightly-rhel9.x86_64.rpm dockerTag=my-tag

# Run structure tests
make structure-test docker_image_type=ubi9-rootless dockerTag=my-tag

# Run Robot Framework tests
make docker-tests docker_image_type=ubi9-rootless dockerTag=my-tag

# Run specific tests only
make docker-tests DOCKER_TEST_LIST="Smoke Test,Initialized MarkLogic container"

# Security scanning with Grype
make scan docker_image_type=ubi9-rootless dockerTag=my-tag

# SCAP hardening validation
make scap-scan docker_image_type=ubi9-rootless dockerTag=my-tag

# Lint Dockerfiles and shell scripts
make lint
```

**Important:** Rootless images automatically apply OpenSCAP CIS hardening scripts during build. The build downloads `scap-security-guide-${open_scap_version}.zip` and extracts the appropriate remediation script for the OS version.

## Container Initialization Logic

The entrypoint scripts (`start-marklogic.sh` for root, `start-marklogic-rootless.sh` for rootless) handle:

1. **Configuration management**: Writes environment variables to `/etc/marklogic.conf`
2. **Credential extraction**: Reads admin credentials from Docker secrets or env vars
3. **Server initialization**: Calls MarkLogic REST APIs to initialize security database
4. **Cluster joining**: Uses bootstrap host to join existing clusters (HTTP or HTTPS)
5. **Health checks**: Polls `/7997/LATEST/healthcheck` endpoint until ready

### Key Environment Variables

| Variable | Purpose | Notes |
|----------|---------|-------|
| `MARKLOGIC_INIT` | Initialize server with admin credentials | Must be `true` for automated setup |
| `MARKLOGIC_JOIN_CLUSTER` | Join existing cluster via bootstrap host | Requires `MARKLOGIC_BOOTSTRAP_HOST` |
| `MARKLOGIC_BOOTSTRAP_HOST` | Hostname of cluster bootstrap node | Defaults to `bootstrap` |
| `MARKLOGIC_JOIN_TLS_ENABLED` | Use HTTPS for cluster join | Requires `MARKLOGIC_JOIN_CACERT_FILE` secret |
| `OVERWRITE_ML_CONF` | Rewrite `/etc/marklogic.conf` | Always `true` for rootless images |
| `INSTALL_CONVERTERS` | Install MarkLogic Converters package | Uses `/converters.rpm` |

**Secrets precedence**: Docker secrets (files in `/run/secrets/`) are preferred over environment variables for credentials.

## Testing Strategy

### Robot Framework Tests (`test/docker-tests.robot`)

Tests use Robot Framework with Docker and HTTP libraries. Each test case creates containers, validates behavior, and tears down.

**Test execution patterns:**
- Tests tagged `long_running` are excluded by default (use `DOCKER_TEST_LIST` to include)
- All tests create uniquely named containers based on test case name (spaces removed)
- Verification uses Docker logs pattern matching and HTTP endpoint checks

**Common test patterns:**
```robotframework
Create container with    -e    MARKLOGIC_INIT=true    -e    MARKLOGIC_ADMIN_USERNAME=admin
Docker log should contain    *MARKLOGIC_INIT is true, initializing*
Verify response for authenticated request with    8001    *No license key*
[Teardown]    Delete container
```

### Structure Tests

Container Structure Tests validate:
- File existence and permissions
- Metadata labels (version, build branch)
- Command availability
- Environment variables

Template: `test/structure-test.yaml` (placeholders replaced during `make structure-test`)

## Clustering Patterns

**Bootstrap node** initialization:
```yaml
environment:
  - MARKLOGIC_INIT=true
  - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
```

**Additional nodes** joining cluster:
```yaml
environment:
  - MARKLOGIC_INIT=true
  - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
  - MARKLOGIC_JOIN_CLUSTER=true
  - MARKLOGIC_BOOTSTRAP_HOST=bootstrap_3n
  - MARKLOGIC_GROUP=dnode  # Optional: join specific group
```

**TLS-enabled joining** (requires CA certificate as secret):
```yaml
environment:
  - MARKLOGIC_JOIN_TLS_ENABLED=true
  - MARKLOGIC_JOIN_CACERT_FILE=certificate.cer
secrets:
  - source: certificate.cer
    target: certificate.cer
```

## Critical Implementation Details

### Rootless vs Root Differences

| Aspect | Root Image | Rootless Image |
|--------|-----------|----------------|
| User | `marklogic_user` (UID 1000) | Same |
| PID file | `/var/run/MarkLogic.pid` | `/home/marklogic_user/MarkLogic.pid` |
| Config overwrite | Controlled by `OVERWRITE_ML_CONF` | Always appends to config |
| Hardening | None | OpenSCAP CIS remediation applied |
| Privileges | Requires `sudo` for service start | Uses `start-marklogic.sh` directly |

### Startup Script Retry Logic

- `N_RETRY=15` attempts with `RETRY_INTERVAL=10` seconds for critical operations
- `CURL_TIMEOUT=300` seconds for individual HTTP requests
- **Non-idempotent endpoint**: `/admin/v1/instance-admin` called exactly once (no retries)
- `restart_check()` function polls `/admin/v1/timestamp` to detect server restarts

### Dockerfile Conventions

- Base images always use `ARG BASE_IMAGE` with defaults
- Multi-stage builds flatten layers using `COPY --from=builder / /`
- Security hardening: Removes packages with known vulnerabilities in final stage
- TINI init system (`/tini`) serves as PID 1 to handle zombie processes
- Volume mounted at `/var/opt/MarkLogic` for persistent data

## Common Pitfalls

1. **Rejoining clusters**: Nodes that previously left a cluster may fail to rejoin (known limitation)
2. **Leave button**: Admin UI "leave" may not work; use Management API instead
3. **Timezone**: Containers default to UTC unless `TZ` environment variable is set
4. **HugePages**: Container allocates up to 3/8 of memory limit as HugePages by default (override with `ML_HUGEPAGES_TOTAL`)
5. **Upgrade process**: Must update file ownership to `1000:100` (`marklogic_user:users`) when upgrading to rootless images

## CI/CD Pipeline (Jenkinsfile)

The pipeline supports:
- Pull request validation (draft checks, review state validation)
- Scheduled vulnerability scans (emails to security team)
- Multi-architecture builds (currently `linux/amd64` only)
- Jira ticket extraction from branch names (pattern: `MLE-\d{3,6}`)
- Image publishing to Artifactory and Azure Container Registry

**Pipeline stages:** Checkout → Lint → Build → Structure Test → Docker Tests → Scan → Publish

## Contributing Notes

- PRs are used for inspiration but not merged directly (see `CONTRIBUTING.md`)
- Always create an issue before starting significant work
- Tests must be added/updated for new features
- Linting must pass: `hadolint` for Dockerfiles, `shellcheck` for scripts
- Security scan reports reviewed before merging
