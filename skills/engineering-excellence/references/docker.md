# Docker

Prefer Docker when it improves reproducibility; avoid unnecessary complexity.
Containers package an application with its exact runtime dependencies to guarantee identical behavior across developer machines, CI runners, and production hosts.
For deploying and scaling multi-container workloads, see [references/container-orchestration-choice.md](references/container-orchestration-choice.md). For image registry publishing and automated release pipelines, see [references/ci-cd-and-publishing.md](references/ci-cd-and-publishing.md).

## When to containerize

Containerization adds build overhead, image storage costs, and a layer of virtualization. Apply it intentionally:

| Adopt Docker when | Skip Docker when |
| --- | --- |
| Polyglot stacks or complex system dependencies (C libraries, FFmpeg, Python wheels) | Static single-binary tools (Go, Rust) deployed to bare metal or standard VMs |
| Teams with heterogeneous local OS environments (macOS, Linux, Windows) | Simple developer CLI tools that distribute cleanly via standard package managers |
| Multi-service architectures requiring local integration testing with isolated dependencies | Serverless functions (AWS Lambda, Cloudflare Workers) managed natively by platform runtimes |
| Strict parity required between CI build environments and production runtimes | Scripts where standard language virtual environments (`venv`, `rbenv`) suffice |

## Multi-stage builds

Always use multi-stage builds to decouple the build toolchain from the runtime image. Compilers, build SDKs, package managers, and development headers have no place in production containers:

- **Build stage**: Contains compilers, build tools, package managers, and source code. Builds the final executable or compiled assets.
- **Runtime stage**: Starts from a minimal base image (such as distroless, Alpine, or a minimal Debian slim). Copies *only* the compiled binary or production distribution from the build stage.
- **Attack surface reduction**: Excluding build tools removes package managers (`npm`, `pip`, `apt`) and compilers (`gcc`, `go`) that an attacker could leverage during a container breakout.

## BuildKit caching and layer optimization

Order Dockerfile instructions from least frequently changed to most frequently changed to maximize layer cache reuse:

1. **Declare BuildKit syntax**: Start with `# syntax=docker/dockerfile:1` to enable modern BuildKit features ([Docker BuildKit frontend](https://docs.docker.com/build/buildkit/frontend/)).
2. **Install system dependencies**: Install base packages early. Clean up package manager caches in the same `RUN` command (`apt-get clean && rm -rf /var/lib/apt/lists/*`) unless using cache mounts.
3. **Copy dependency manifests first**: Copy only dependency declarations (`package.json`, `go.mod`, `pom.xml`, `requirements.txt`) before application source code.
4. **Leverage cache mounts**: Use `RUN --mount=type=cache` to persist package manager caches across builds without bloating intermediate image layers ([Docker Cache Mounts](https://docs.docker.com/build/cache/optimize/#use-cache-mounts)).
5. **Copy source and compile**: Copy application source code only after dependencies are resolved.

## Security and least privilege

Container boundaries do not substitute for user permissions. Enforce secure container defaults:

- **Never run as root**: Create and switch to an explicit unprivileged user (`USER 10001:10001` or `USER nonroot:nonroot`). Root in a container increases container escape severity.
- **Never bake secrets into layers**: Do not pass passwords, private tokens, or SSH keys via `ENV` or `ARG`. Use BuildKit secret mounts (`RUN --mount=type=secret,id=mysecret`) so secrets never persist in image metadata or layer history.
- **Enforce immutable base tags**: Pin base images to specific tags or SHA256 digests (`alpine:3.21@sha256:...`). Floating tags like `latest` cause unannounced drift.
- **Maintain a strict `.dockerignore`**: Exclude `.git`, local `.env` files, `node_modules`, test reports, IDE files, and temporary artifacts from the build context.

## Process execution and signal handling

- **Use exec form for CMD and ENTRYPOINT**: Always use JSON array format (`CMD ["node", "dist/index.js"]`). The string format (`CMD node dist/index.js`) spawns `/bin/sh` as PID 1, which swallows `SIGTERM` signals and forces orchestrators to kill containers with `SIGKILL` after timeouts.
- **Handle PID 1 responsibilities**: Containers run applications as PID 1. If the runtime cannot handle orphan reaping or signal forwarding, run under a minimal init system like `tini` (`ENTRYPOINT ["/sbin/tini", "--"]`).

## Checklist

- [ ] Docker adoption justified by portability or dependency isolation requirements
- [ ] Multi-stage build separates build SDKs and compilers from the production runtime image
- [ ] Base images pinned to immutable versions or SHA256 digests; floating `latest` prohibited
- [ ] Build instructions ordered to maximize cache reuse: dependency manifests copied before application code
- [ ] BuildKit cache mounts configured for package managers where supported
- [ ] Dedicated non-root user defined and activated (`USER nonroot` or explicit UID/GID)
- [ ] No secrets or private tokens baked into image layers or build arguments
- [ ] `.dockerignore` excludes `.git`, credentials, local dependencies, and test artifacts
- [ ] `CMD` and `ENTRYPOINT` declared using JSON exec syntax (`["executable", "param"]`)
- [ ] Container handles `SIGTERM` cleanly, enabling graceful shutdown without timeouts
