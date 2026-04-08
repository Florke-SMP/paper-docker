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

## License

Third party licenses:

- Amazon's [Corretto 21](https://github.com/corretto/corretto-21), licensed under the [GPL-2.0](https://github.com/corretto/corretto-21?tab=GPL-2.0-1-ov-file#readme)
- PaperMC's [Velocity](https://github.com/PaperMC/Velocity), licensed under the [GPL-3.0](https://github.com/PaperMC/Velocity?tab=GPL-3.0-1-ov-file#readme)

Docker build script is licensed under [MIT](https://github.com/Florke-SMP/velocity-docker?tab=MIT-1-ov-file#readme) license.
