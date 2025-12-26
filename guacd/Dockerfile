#------------------------------
# Guacamole server all-in-one image
#------------------------------

FROM debian:bookworm    

LABEL maintainer="Louis.bahiana@hotmail.com" \ 
    version="1.0" \
    description="This is a Dockerfile for my educational projects for learning purposes."

# Install build & runtime dependencies
RUN apt-get update && apt-get install -y \
    libcairo2-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev \
    freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev \
    libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev \
    libjpeg62-turbo-dev libpng-dev libtool-bin uuid-dev apt-utils \
    libossp-uuid-dev build-essential autoconf automake libtool pkg-config wget curl \
    libavcodec59 libavformat59 libavutil57 libswscale6 \
    libfreerdp2-2 libpango-1.0-0 libssh2-1 libtelnet2 \
    libvncserver1 libpulse0 libssl3 libvorbis0a libwebp7 libcairo2 \
    libjpeg62-turbo libpng16-16 uuid-runtime net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -r -s /bin/false guacd

# Download Guacamole server
WORKDIR /tmp/
RUN wget -O guacamole-server-1.6.0.tar.gz \
    "https://apache.org/dyn/closer.lua/guacamole/1.6.0/source/guacamole-server-1.6.0.tar.gz?action=download"
RUN tar -xzf guacamole-server-1.6.0.tar.gz

# Build and install guacamole-server
WORKDIR /tmp/guacamole-server-1.6.0/
RUN ./configure --with-systemd-dir=/usr/local/lib/systemd/system --with-libssh2
RUN make && make install && ldconfig
RUN cd /tmp && rm -rf guacamole-server-1.6.0 guacamole-server-1.6.0.tar.gz

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Register lib path (libguac)
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/guacamole.conf && ldconfig

# Permissions
RUN chown -R guacd:guacd \
    /usr/local/sbin/guacd \
    /usr/local/lib \
    /usr/local/bin/guacenc \
    /usr/local/bin/guaclog

# Expose guacd port
EXPOSE 4822

# User
USER 114

# Entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

#testd