#
# DSpace image
#

FROM tomcat:8.5
LABEL maintainer="Alan Orth <alan.orth@gmail.com>"

# Allow custom DSpace hostname at build time (default to localhost if undefined)
ARG CONFIG_DSPACE_PROTOCOL="http"
# To override, pass --build-arg CONFIG_DSPACE_HOSTNAME=repo.example.org to docker build
ARG CONFIG_DSPACE_HOSTNAME="localhost"
# Cater for environments where Tomcat is being reverse proxied via another HTTP
# server like nginx on port 80, for example. DSpace needs to know its publicly
# accessible URL for various places where it writes its own URL.
ARG CONFIG_DSPACE_PROXY_PORT=":8080"
ARG CONFIG_DSPACE_INTERNAL_PROXY_PORT=":8080"
# Build configuration variables
ARG CONFIG_DSPACE_NAME="DSpace at My University"
ARG CONFIG_MAIL_SERVER="smtp.example.com"
ARG CONFIG_MAIL_SERVER_PORT="25"
ARG CONFIG_MAIL_SERVER_USERNAME=""
ARG CONFIG_MAIL_SERVER_PASSWORD=""
ARG CONFIG_MAIL_FROM_ADDRESS="dspace-noreply@myu.edu"
ARG CONFIG_MAIL_FEEDBACK_RECIPIENT="dspace-noreply@myu.edu"
ARG CONFIG_MAIL_ADMIN="dspace-noreply@myu.edu"
ARG CONFIG_MAIL_ALERT_RECIPIENT="dspace-noreply@myu.edu"
ARG CONFIG_MAIL_REGISTRATION_NOTIFY="dspace-noreply@myu.edu"
ARG CONFIG_HANDLE_CANONICAL_PREFIX="http://hdl.handle.net/"
ARG CONFIG_HANDLE_PREFIX="123456789"

# Active DSpace theme
ARG CONFIG_DSPACE_ACTIVE_THEME="Mirage2"
#
ARG CONFIG_GOOGLE_ANALYTICS_KEY=""

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

# Copy Active theme
RUN if [ -d dspace/custom_configuration/themes/$CONFIG_DSPACE_ACTIVE_THEME/theme ]; \
        then cp -r dspace/custom_configuration/themes/$CONFIG_DSPACE_ACTIVE_THEME/theme dspace/dspace/modules/xmlui-mirage2/src/main/webapp/themes/$CONFIG_DSPACE_ACTIVE_THEME; \
        else echo "No theme is defined"; \
    fi

# Set DSpace confirgation variables
RUN sed -i -e "s/#CONFIG_DSPACE_PROTOCOL#/$CONFIG_DSPACE_PROTOCOL/g" \
    -e "s/#CONFIG_DSPACE_HOSTNAME#/$CONFIG_DSPACE_HOSTNAME/g" \
    -e "s/#CONFIG_DSPACE_PROXY_PORT#/$CONFIG_DSPACE_PROXY_PORT/g" \
    -e "s/#CONFIG_DSPACE_INTERNAL_PROXY_PORT#/$CONFIG_DSPACE_INTERNAL_PROXY_PORT/g" \
    -e "s/#CONFIG_DSPACE_NAME#/$CONFIG_DSPACE_NAME/g" \
    -e "s/#CONFIG_MAIL_SERVER#/$CONFIG_MAIL_SERVER/g" \
    -e "s/#CONFIG_MAIL_SERVER_PORT#/$CONFIG_MAIL_SERVER_PORT/g" \
    -e "s/#CONFIG_MAIL_SERVER_USERNAME#/$CONFIG_MAIL_SERVER_USERNAME/g" \
    -e "s/#CONFIG_MAIL_SERVER_PASSWORD#/$CONFIG_MAIL_SERVER_PASSWORD/g" \
    -e "s/#CONFIG_MAIL_FROM_ADDRESS#/$CONFIG_MAIL_FROM_ADDRESS/g" \
    -e "s/#CONFIG_MAIL_FEEDBACK_RECIPIENT#/$CONFIG_MAIL_FEEDBACK_RECIPIENT/g" \
    -e "s/#CONFIG_MAIL_ADMIN#/$CONFIG_MAIL_ADMIN/g" \
    -e "s/#CONFIG_MAIL_ALERT_RECIPIENT#/$CONFIG_MAIL_ALERT_RECIPIENT/g" \
    -e "s/#CONFIG_MAIL_REGISTRATION_NOTIFY#/$CONFIG_MAIL_REGISTRATION_NOTIFY/g" \
    -e "s/#CONFIG_HANDLE_CANONICAL_PREFIX#/$CONFIG_HANDLE_CANONICAL_PREFIX/g" \
    -e "s/#CONFIG_HANDLE_PREFIX#/$CONFIG_HANDLE_PREFIX/g" \
    dspace/build.properties && \
    sed -i -e "s/#CONFIG_DSPACE_ACTIVE_THEME#/$CONFIG_DSPACE_ACTIVE_THEME/g" dspace/dspace/config/xmlui.xconf && \
    sed -i -e "s/#CONFIG_DSPACE_NAME#/$CONFIG_DSPACE_NAME/g" dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml && \
    if [ ! -z "$CONFIG_GOOGLE_ANALYTICS_KEY"]; \
        then echo "xmlui.google.analytics.key=$CONFIG_GOOGLE_ANALYTICS_KEY" >> dspace/dspace/config/dspace.cfg; \
        else echo "xmlui.google.analytics.key IS NOT DEFINED"; \
    fi

WORKDIR /tmp/dspace/custom_configuration/$CONFIG_DSPACE_ACTIVE_THEME/custom
# Add additional org.dspace.app.xmlui.artifactbrowser.AbstractSearch
RUN if [ -f org.dspace.app.xmlui.artifactbrowser.AbstractSearch.xml ]; \
    then sed -i -e '/#CONFIG_XMLUI_ARTIFACT_BROWSER_SEARCH_ADDITIONAL#/{r org.dspace.app.xmlui.artifactbrowser.AbstractSearch.xml' -e 'd}' dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml; \
    else sed -i -e '/#CONFIG_XMLUI_ARTIFACT_BROWSER_SEARCH_ADDITIONAL#//g' dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml && echo "CONFIG_XMLUI_ARTIFACT_BROWSER_SEARCH_ADDITIONAL IS NOT EXISTS"; \
    fi
# Add additional org.dspace.app.xmlui.artifactbrowser.AdvancedSearch
RUN if [ -f org.dspace.app.xmlui.artifactbrowser.AdvancedSearch.xml ]; \
    then sed -i -e '/#CONFIG_XMLUI_ARTIFACT_BROWSER_ADVANCED_SEARCH_ADDITIONAL#/{r org.dspace.app.xmlui.artifactbrowser.AdvancedSearch.xml' -e 'd}' dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml; \
    else sed -i -e 's/#CONFIG_XMLUI_ARTIFACT_BROWSER_ADVANCED_SEARCH_ADDITIONAL#//g' dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml && echo "CONFIG_XMLUI_ARTIFACT_BROWSER_ADVANCED_SEARCH_ADDITIONAL IS NOT EXISTS"; \
    fi
# Add additional org.dspace.discovery.configuration.DiscoveryConfiguration
RUN if [ -f org.dspace.discovery.configuration.DiscoveryConfiguration.xml ]; \
    then sed -i -e '/#CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_ADDITIONAL#/{r org.dspace.discovery.configuration.DiscoveryConfiguration.xml' -e 'd}' dspace/dspace/config/spring/api/discovery.xml; \
    else sed -i -e 's/#CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_ADDITIONAL#//g' dspace/dspace/config/spring/api/discovery.xml && echo "CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_ADDITIONAL IS NOT EXISTS"; \
    fi
# Add additional org.dspace.discovery.configuration.DiscoveryConfiguration.details details
RUN if [ -f org.dspace.discovery.configuration.DiscoveryConfiguration.details.xml ]; \
    then sed -i -e '/#CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_DETAILS_ADDITIONAL#/{r org.dspace.discovery.configuration.DiscoveryConfiguration.details.xml' -e 'd}' dspace/dspace/config/spring/api/discovery.xml; \
    else sed -i -e 's/#CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_DETAILS_ADDITIONAL#//g' dspace/dspace/config/spring/api/discovery.xml && echo "CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_DETAILS_ADDITIONAL IS NOT EXISTS"; \
    fi
# Add additional org.dspace.discovery.configuration.DiscoveryMoreLikeThisConfiguration
RUN if [ -f org.dspace.discovery.configuration.DiscoveryMoreLikeThisConfiguration.xml ]; \
    then sed -i -e '/#CONFIG_SPRING_API_DISCOVERY_SIMILARITY_METADATA_ADDITIONAL#/{r org.dspace.discovery.configuration.DiscoveryMoreLikeThisConfiguration.xml' -e 'd}' dspace/dspace/config/spring/api/discovery.xml; \
    else sed -i -e 's/#CONFIG_SPRING_API_DISCOVERY_SIMILARITY_METADATA_ADDITIONAL#//g' dspace/dspace/config/spring/api/discovery.xml && echo "CONFIG_SPRING_API_DISCOVERY_SIMILARITY_METADATA_ADDITIONAL IS NOT EXISTS"; \
    fi
# Custom page header
RUN if [ -f costum.main.page.header.html ]; \
    then sed -i -e '/#CONFIG_MAIN_PAGE_HEADER#/{r costum.main.page.header.html' -e 'd}' dspace/dspace/config/news-xmlui.xml; \
    else sed -i -e 's/#CONFIG_MAIN_PAGE_HEADER#//g' dspace/dspace/config/news-xmlui.xml && echo "CONFIG_MAIN_PAGE_HEADER IS NOT EXISTS"; \
    fi
WORKDIR /tmp


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

RUN sed -i "s/PROXY_PORT/$DSPACE_PROXY_PORT/g" "$CATALINA_HOME"/conf/server.xml && \
    # Install root filesystem
    cp -r /tmp/dspace/rootfs/* / && \
    # Copy Handle server
    if [ -d /tmp/dspace/custom_configuration/$CONFIG_DSPACE_ACTIVE_THEME/handle-server ]; \
        then cp -r /tmp/dspace/custom_configuration/$CONFIG_DSPACE_ACTIVE_THEME/handle-server $DSPACE_HOME/; \
        else echo "No Handle server files found"; \
    fi && \
    # Docker's COPY instruction always sets ownership to the root user, so we need
    # to explicitly change ownership of those files and directories that we copied
    # from rootfs.
    chown -R dspace:dspace $DSPACE_HOME && \
    # Make sure the crontab uses the correct DSpace directory
    sed -i "s#DSPACE=/dspace#DSPACE=$DSPACE_HOME#g" /etc/cron.d/dspace-maintenance-tasks && \
    rm -rf "$DSPACE_HOME/.m2" /tmp/* && apt-get -y autoremove

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