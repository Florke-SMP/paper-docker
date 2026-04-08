FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://www.github.com/Florke-SMP/paper-docker"
LABEL org.opencontainers.image.description="Docker image for Paper, a Minecraft server software."
LABEL org.opencontainers.image.licenses="GPL-3.0"

LABEL maintainer="Florke64"

WORKDIR /paper
VOLUME /paper

RUN mkdir /plugins
VOLUME /plugins

### Install APT packages ###
# Adds AWS repo's GPG keys and installs Amazon's Corretto 25.
# This follows instructions from https://docs.papermc.io/.

ARG JDK_APT_SOURCE="deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main"

RUN apt-get update && apt-get upgrade -y \
&& apt-get install --no-install-recommends -y \
	ca-certificates \
	apt-transport-https \
	gnupg \
	wget \
\
&& wget -O - https://apt.corretto.aws/corretto.key \
	| gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg \
\	
&& echo "${JDK_APT_SOURCE}" | tee /etc/apt/sources.list.d/corretto.list \
\
&& apt-get update && apt-get install \
	--no-install-recommends -y \
	java-25-amazon-corretto-jdk \
	libxi6 \
	libxtst6 \
	libxrender1 \
&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Get the Velocity JAR file
# PAPER_URL is provided by .buildargs
ARG PAPER_URL
ARG SHA256
ARG JVM_FLAGS

# Download and verify
RUN wget -O /paper.jar "${PAPER_URL}" && \
    echo "${SHA256} /paper.jar" | sha256sum -c -

# Write JVM flags to file
RUN echo "${JVM_FLAGS}" > /paper-jvm-flags.txt

# Entrypoint script
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

# Expose default proxy's port
EXPOSE 25565
