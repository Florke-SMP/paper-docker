# paper-docker

Docker image build scripts for Paper, a Minecraft Server software.
Automated container image builds are available at project's [packages](https://github.com/Florke-SMP/paper-docker/pkgs/container/paper) page.

## Available images

Get the latest available image
```
docker pull ghcr.io/florke-smp/paper:latest
```


Or pinpoint specific version
```
docker pull ghcr.io/florke-smp/paper:26.1.1

# Each build is tagged unique number
# https://fill-ui.papermc.io/projects/paper/version/26.1.1?build=29
docker pull ghcr.io/florke-smp/paper:26.1.1-29
```

# Running

Quick start:

> By appending EULA=true, you agree to https://www.minecraft.net/en-us/eula

```
docker run -d \
  -e PAPER_EULA=true \
  -p 25565:25565 \
  -v ./data:/paper \
  -v ./plugins:/plugins \
  ghcr.io/florke-smp/paper:latest
```

> Container drops privilages at some point at runtime and becomes `paper` user (UID/GID 1500).

Or with docker compose:

```
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
| PAPER_RCON_PASSWORD | Enables RCON when set, writing a strong secret to `server.properties`. Expose host port `25575` to reach the console. |
| PAPER_RCON_BROADCAST | Mirrors `broadcast-rcon-to-ops` (defaults to `true`); set to `false` if RCON output should stay private. |

[Learn more](https://github.com/Florke-SMP/paper-docker/wiki/Environment-Variables)

# Building locally

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

- Amazon's [Corretto 25](https://github.com/corretto/corretto-25), licensed under the [GPL-2.0](https://github.com/corretto/corretto-25?tab=GPL-2.0-1-ov-file#readme)
- PaperMC's [Velocity](https://github.com/PaperMC/Velocity), licensed under the [GPL-3.0](https://github.com/PaperMC/Velocity?tab=GPL-3.0-1-ov-file#readme)

Docker build script is licensed under [MIT](https://github.com/Florke-SMP/paper-docker?tab=MIT-1-ov-file#readme) license.

Parts of this project might have been *[vibe coded](https://en.wikipedia.org/wiki/Vibe_coding)*.
