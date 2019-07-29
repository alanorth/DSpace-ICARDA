#
# DSpace image
#

FROM tomcat:8.5
LABEL maintainer "Alan Orth <alan.orth@gmail.com>"

# Allow custom DSpace hostname at build time (default to localhost if undefined)
# To override, pass --build-arg DSPACE_HOSTNAME=repo.example.org to docker build
ARG DSPACE_HOSTNAME=digitalarchive.worldfishcenter.org/
# Cater for environments where Tomcat is being reverse proxied via another HTTP
# server like nginx on port 80, for example. DSpace needs to know its publicly
# accessible URL for various places where it writes its own URL.
ARG DSPACE_PROXY_PORT=

# Environment variables
ENV DSPACE_HOME=/dspace
ENV CATALINA_OPTS="-Xmx512M -Dfile.encoding=UTF-8" \
    MAVEN_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1" \
    PATH=$CATALINA_HOME/bin:$DSPACE_HOME/bin:$PATH

WORKDIR /tmp

# Install runtime and dependencies
RUN apt-get update && apt-get install -y \
    ant \
    maven \
    postgresql-client \
    imagemagick \
    ghostscript \
    openjdk-8-jdk-headless \
    cron \
    less \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Add a non-root user to perform the Maven build. DSpace's Mirage 2 theme does
# quite a bit of bootstrapping with npm and bower, which fails as root. Also
# change ownership of DSpace and Tomcat install directories.
RUN useradd -r -s /bin/bash -m -d "$DSPACE_HOME" dspace \
    && chown -R dspace:dspace "$DSPACE_HOME" "$CATALINA_HOME"

# copy source to $WORKDIR/dspace
COPY . dspace/
RUN chown -R dspace:dspace dspace

# Change to dspace user for build and install
USER dspace

# Copy customized DSpace build properties
COPY config/build.properties dspace

# Set DSpace hostname and port in build.properties
RUN sed -i -e "s/DSPACE_HOSTNAME/$DSPACE_HOSTNAME/" -e "s/DSPACE_PROXY_PORT/$DSPACE_PROXY_PORT/" dspace/build.properties

# Build DSpace with Mirage 2 enabled
RUN cd dspace && mvn -Dmirage2.on=true package

# Install compiled applications to $CATALINA_HOME
RUN cd dspace/dspace/target/dspace-installer \
    && ant init_installation init_configs install_code copy_webapps \
    && rm -rf "$CATALINA_HOME/webapps" && mv -f "$DSPACE_HOME/webapps" "$CATALINA_HOME" \
    && sed -i s/CONFIDENTIAL/NONE/ "$CATALINA_HOME"/webapps/rest/WEB-INF/web.xml

# Rename xmlui app to ROOT so it is available on /
RUN mv "$CATALINA_HOME"/webapps/xmlui "$CATALINA_HOME"/webapps/ROOT

# Change back to root user for cleanup
USER root

# Tweak default Tomcat server configuration
COPY config/server.xml "$CATALINA_HOME"/conf/server.xml

RUN sed -i "s/PROXY_PORT/$DSPACE_PROXY_PORT/" "$CATALINA_HOME"/conf/server.xml

# Install root filesystem
COPY rootfs /

# Docker's COPY instruction always sets ownership to the root user, so we need
# to explicitly change ownership of those files and directories that we copied
# from rootfs.
RUN chown dspace:dspace $DSPACE_HOME $DSPACE_HOME/bin/* $DSPACE_HOME/handle-server/*

# Make sure the crontab uses the correct DSpace directory
RUN sed -i "s#DSPACE=/dspace#DSPACE=$DSPACE_HOME#" /etc/cron.d/dspace-maintenance-tasks

RUN rm -rf "$DSPACE_HOME/.m2" /tmp/*
#RUN apt-get remove -y openjdk-8-jdk-headless
RUN apt-get -y autoremove

WORKDIR $DSPACE_HOME

# Change to dspace user for for adding the job
USER dspace
RUN (crontab -l 2>/dev/null; echo '0 0 * * * /dspace/bin/dspace generate-sitemaps') | crontab -
USER root

# Build info
RUN echo "Debian GNU/Linux `cat /etc/debian_version` image. (`uname -rsv`)" >> /root/.built && \
    echo "- with `java -version 2>&1 | awk 'NR == 2'`" >> /root/.built && \
    echo "- with DSpace $DSPACE_VERSION on Tomcat $TOMCAT_VERSION"  >> /root/.built && \
    echo "\nNote: if you need to run commands interacting with DSpace you should enter the" >> /root/.built && \
    echo "container as the dspace user, ie: docker exec -it -u dspace dspace /bin/bash" >> /root/.built

EXPOSE 2641 8000 8080
# will run `start-dspace` script as root, then drop to dspace user
CMD ["start-dspace"]
