#
# DSpace image
#

FROM tomcat:8.5
LABEL maintainer "Alan Orth <alan.orth@gmail.com>"

# Allow custom DSpace hostname at build time (default to localhost if undefined)
ARG CONFIG_DSPACE_PROTOCOL="http"
# To override, pass --build-arg CONFIG_DSPACE_HOSTNAME=repo.example.org to docker build
ARG CONFIG_DSPACE_HOSTNAME="repo.mel.cgiar.org"
# Cater for environments where Tomcat is being reverse proxied via another HTTP
# server like nginx on port 80, for example. DSpace needs to know its publicly
# accessible URL for various places where it writes its own URL.
ARG CONFIG_DSPACE_PROXY_PORT=""
ARG CONFIG_DSPACE_INTERNAL_PROXY_PORT=":8080"
# Build configuration variables
ARG CONFIG_DSPACE_NAME="MELSpace"
ARG CONFIG_MAIL_SERVER="smtp.example.com"
ARG CONFIG_MAIL_SERVER_PORT="25"
ARG CONFIG_MAIL_SERVER_USERNAME=""
ARG CONFIG_MAIL_SERVER_PASSWORD=""
ARG CONFIG_MAIL_FROM_ADDRESS="dspace-noreply@myu.edu"
ARG CONFIG_MAIL_FEEDBACK_RECIPIENT="dspace-noreply@myu.edu"
ARG CONFIG_MAIL_ADMIN="dspace-noreply@myu.edu"
ARG CONFIG_MAIL_ALERT_RECIPIENT="dspace-noreply@myu.edu"
ARG CONFIG_MAIL_REGISTRATION_NOTIFY="dspace-noreply@myu.edu"
ARG CONFIG_HANDLE_CANONICAL_PREFIX="https://hdl.handle.net/"
ARG CONFIG_HANDLE_PREFIX="20.500.11766"

# Active DSpace theme
ARG CONFIG_DSPACE_ACTIVE_THEME="MELSpace"
#
ARG CONFIG_GOOGLE_ANALYTICS_KEY="UA-65705913-2"

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

# Copy Handle server
RUN if [ -f dspace/costum_configuration/handle-server ]; \
    then cp -r dspace/costum_configuration/handle-server dspace/rootfs/dspace/; \
    fi
# Copy Active theme
RUN if [ -f dspace/costum_configuration/themes/$CONFIG_DSPACE_ACTIVE_THEME ]; \
    then cp -r dspace/costum_configuration/themes/$CONFIG_DSPACE_ACTIVE_THEME dspace/dspace/modules/xmlui-mirage2/src/main/webapp/themes/; \
    fi

# Set DSpace confirgation variables
RUN sed -i -e "s/CONFIG_DSPACE_PROTOCOL/$CONFIG_DSPACE_PROTOCOL/" \
    -e "s/CONFIG_DSPACE_HOSTNAME/$CONFIG_DSPACE_HOSTNAME/" \
    -e "s/CONFIG_DSPACE_PROXY_PORT/$CONFIG_DSPACE_PROXY_PORT/" \
    -e "s/CONFIG_DSPACE_INTERNAL_PROXY_PORT/$CONFIG_DSPACE_INTERNAL_PROXY_PORT/" \
    -e "s/CONFIG_DSPACE_NAME/$CONFIG_DSPACE_NAME/" \
    -e "s/CONFIG_MAIL_SERVER/$CONFIG_MAIL_SERVER/" \
    -e "s/CONFIG_MAIL_SERVER_PORT/$CONFIG_MAIL_SERVER_PORT/" \
    -e "s/CONFIG_MAIL_SERVER_USERNAME/$CONFIG_MAIL_SERVER_USERNAME/" \
    -e "s/CONFIG_MAIL_SERVER_PASSWORD/$CONFIG_MAIL_SERVER_PASSWORD/" \
    -e "s/CONFIG_MAIL_FROM_ADDRESS/$CONFIG_MAIL_FROM_ADDRESS/" \
    -e "s/CONFIG_MAIL_FEEDBACK_RECIPIENT/$CONFIG_MAIL_FEEDBACK_RECIPIENT/" \
    -e "s/CONFIG_MAIL_ADMIN/$CONFIG_MAIL_ADMIN/" \
    -e "s/CONFIG_MAIL_ALERT_RECIPIENT/$CONFIG_MAIL_ALERT_RECIPIENT/" \
    -e "s/CONFIG_MAIL_REGISTRATION_NOTIFY/$CONFIG_MAIL_REGISTRATION_NOTIFY/" \
    -e "s/CONFIG_HANDLE_CANONICAL_PREFIX/$CONFIG_HANDLE_CANONICAL_PREFIX/" \
    -e "s/CONFIG_HANDLE_PREFIX/$CONFIG_HANDLE_PREFIX/" \
    dspace/build.properties && \
    sed -i -e "s/CONFIG_DSPACE_ACTIVE_THEME/$CONFIG_DSPACE_ACTIVE_THEME/" dspace/dspace/config/xmlui.xconf && \
    sed -i -e "s/CONFIG_DSPACE_NAME/$CONFIG_DSPACE_NAME/" dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml

#Set google analytics code
RUN if [ ! -z "$CONFIG_GOOGLE_ANALYTICS_KEY"]; \
    then echo "xmlui.google.analytics.key=$CONFIG_GOOGLE_ANALYTICS_KEY" >> dspace/dspace/config/dspace.cfg; \
    fi

# Add additional org.dspace.app.xmlui.artifactbrowser.AbstractSearch
ENV current_path_to_check=dspace/costum_configuration/org.dspace.app.xmlui.artifactbrowser.AbstractSearch.xml
RUN if [ -f $current_path_to_check ]; \
    then sed -i -e '/CONFIG_XMLUI_ARTIFACT_BROWSER_SEARCH_ADDITIONAL/{r $current_path_to_check' -e 'd}' dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml; \
    fi
# Add additional org.dspace.app.xmlui.artifactbrowser.AdvancedSearch
ENV current_path_to_check=dspace/costum_configuration/org.dspace.app.xmlui.artifactbrowser.AdvancedSearch.xml
RUN if [ ! -z "$current_path_to_check"]; \
    then sed -i -e '/CONFIG_XMLUI_ARTIFACT_BROWSER_ADVANCED_SEARCH_ADDITIONAL/{r $current_path_to_check' -e 'd}' dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml; \
    fi
# Add additional org.dspace.discovery.configuration.DiscoveryConfiguration
ENV current_path_to_check=dspace/costum_configuration/org.dspace.discovery.configuration.DiscoveryConfiguration.xml
RUN if [ -f "$current_path_to_check"]; \
    then sed -i -e '/CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_ADDITIONAL/{r $current_path_to_check' -e 'd}' dspace/dspace/config/spring/api/discovery.xml; \
    fi
# Add additional org.dspace.discovery.configuration.DiscoveryConfiguration.details details
ENV current_path_to_check=dspace/costum_configuration/org.dspace.discovery.configuration.DiscoveryConfiguration.details.xml
RUN if [ -f "$current_path_to_check"]; \
    then sed -i -e '/CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_DETAILS_ADDITIONAL/{r $current_path_to_check' -e 'd}' dspace/dspace/config/spring/api/discovery.xml; \
    fi
# Add additional org.dspace.discovery.configuration.DiscoveryMoreLikeThisConfiguration
ENV current_path_to_check=dspace/costum_configuration/org.dspace.discovery.configuration.DiscoveryMoreLikeThisConfiguration.xml
RUN if [ -f "$current_path_to_check"]; \
    then sed -i -e '/CONFIG_SPRING_API_DISCOVERY_SIMILARITY_METADATA_ADDITIONAL/{r $current_path_to_check' -e 'd}' dspace/dspace/config/spring/api/discovery.xml; \
    fi
# Custom page header
ENV current_path_to_check=dspace/costum_configuration/costum.main.page.header.html
RUN if [ -f "$current_path_to_check"]; \
    then sed -i -e '/CONFIG_MAIN_PAGE_HEADER/{r $current_path_to_check' -e 'd}' dspace/dspace/config/news-xmlui.xml; \
    fi
ENV current_path_to_check=""


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

RUN chown -R dspace:dspace $DSPACE_HOME /usr/local/tomcat/logs

# Build info
RUN echo "Debian GNU/Linux `cat /etc/debian_version` image. (`uname -rsv`)" >> /root/.built && \
    echo "- with `java -version 2>&1 | awk 'NR == 2'`" >> /root/.built && \
    echo "- with DSpace $DSPACE_VERSION on Tomcat $TOMCAT_VERSION"  >> /root/.built && \
    echo "\nNote: if you need to run commands interacting with DSpace you should enter the" >> /root/.built && \
    echo "container as the dspace user, ie: docker exec -it -u dspace dspace /bin/bash" >> /root/.built

EXPOSE 2641 8000 8080
# will run `start-dspace` script as root, then drop to dspace user
CMD ["start-dspace"]