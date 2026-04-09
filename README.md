# paper-docker

Docker image build scripts for Minecraft Server software: Paper

# Running

Quick start:

```
docker run -d \
  -e PAPER_EULA=true \
  -p 25565:25565 \
  -v ./data:/paper \
  -v ./plugins:/plugins \
  ghcr.io/florke-smp/paper:latest
```

> Container drops privilages at some point at runtime and becomes `paper` user (UID/GID 1500).

```
version: '3.9'
services:
  paper:
    image: ghcr.io/florke-smp/paper:dev
    ports:
      - 25565:25565
    environment:
      PAPER_EULA: "true"
    volumes:
      - ./data:/paper
      - ./plugins:/plugins
    restart: unless-stopped
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

# License

Third party licenses:

- Amazon's [Corretto 21](https://github.com/corretto/corretto-21), licensed under the [GPL-2.0](https://github.com/corretto/corretto-21?tab=GPL-2.0-1-ov-file#readme)
- PaperMC's [Velocity](https://github.com/PaperMC/Velocity), licensed under the [GPL-3.0](https://github.com/PaperMC/Velocity?tab=GPL-3.0-1-ov-file#readme)

Docker build script is licensed under [MIT](https://github.com/Florke-SMP/velocity-docker?tab=MIT-1-ov-file#readme) license.

# AI Notice

Parts of this project might be *[vibe coded 🤙](https://en.wikipedia.org/wiki/Vibe_coding)*, meaning they were modified or partially generated with sort of [AI ✨](https://en.wikipedia.org/wiki/Large_language_model). That said, as far as I do care for this repo (for my own use too btw) - it probably shouldn't be used in any critical environment, as this is hobby and *vibe* project 🕊️
