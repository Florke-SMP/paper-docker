# paper-docker

Docker image build scripts for Minecraft Server software: Paper

# Running

```
docker run -d \
  -e PAPER_EULA=true \
  -p 25565:25565 \
  -v ./data:/paper \
  -v ./plugins:/plugins \
  ghcr.io/florke-smp/paper:latest
```

# Environment

| Variable | Usage |
|----------|-------|
| PAPER_EULA | Must be set to "true" to accept the Minecraft EULA |

# Building locally

> Automatic builds are available at project's [Packages](https://github.com/Florke-SMP/paper-docker/pkgs/container/paper) site.

```
# Update .buildargs to the latest version
./paper-latest.sh
source .buildargs

docker build \
--build-arg PAPER_URL="$PAPER_URL" \
--build-arg SHA256="$SHA256" \
--build-arg JVM_FLAGS="$JVM_FLAGS" \
-t paper-docker:latest .
```
