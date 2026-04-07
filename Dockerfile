FROM arranhs/chromium-headful:local

ENV RUN_AS_ROOT=false

ENV GLOBAL_EXTENSIONS_DIR=/home/kernel/.config/BraveSoftware/Brave-Browser/extensions
ENV USER_EXTENSIONS_DIR=/home/kernel/user-data/extensions

# Add scripts
COPY scripts/ /tmp/scripts/

# Install and setup brave browser
RUN apt-get update && \
    apt-get install -y jq && \
    /tmp/scripts/uninstall-chromium.sh && \
    /tmp/scripts/install-brave.sh && \
    /tmp/scripts/patch-wrapper.sh && \
    rm -rf /tmp/scripts && \
    rm -rf /var/lib/apt/lists/*

# Add brave browser policies
COPY brave/policies.json /etc/brave/policies/managed/policies.json
