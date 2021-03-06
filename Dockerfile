#
# DSpace image
#

FROM maven:3-openjdk-8 as build
LABEL maintainer="Alan Orth <alan.orth@gmail.com>"

# Allow custom DSpace hostname at build time (default to localhost if undefined)
ARG CONFIG_DSPACE_PROTOCOL="http"
# To override, pass --build-arg CONFIG_DSPACE_HOSTNAME=repo.example.org to docker build
ARG CONFIG_DSPACE_HOSTNAME="localhost"
# Cater for environments where Tomcat is being reverse proxied via another HTTP
# server like nginx on port 80, for example. DSpace needs to know its publicly
# accessible URL for various places where it writes its own URL.
ARG CONFIG_DSPACE_PROXY_PORT="8080"
ENV CONFIG_DSPACE_PROXY_PORT_STRING=${CONFIG_DSPACE_PROXY_PORT:+":"}$CONFIG_DSPACE_PROXY_PORT
ARG CONFIG_DSPACE_INTERNAL_PROXY_PORT="8080"
ENV CONFIG_DSPACE_INTERNAL_PROXY_PORT_STRING=${CONFIG_DSPACE_INTERNAL_PROXY_PORT:+":"}$CONFIG_DSPACE_INTERNAL_PROXY_PORT
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
ARG CONFIG_HANDLE_CANONICAL_PREFIX="http:\/\/hdl.handle.net\/"
ARG CONFIG_HANDLE_PREFIX="123456789"

# Active DSpace theme
ARG CONFIG_DSPACE_ACTIVE_THEME="Mirage2"

ARG CONFIG_GOOGLE_ANALYTICS_KEY=""
ARG REQUEST_ITEM_HELPDESK_OVERRIDE=false

# Environment variables
ENV DSPACE_HOME=/dspace
ENV MAVEN_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
ENV SOLR_SERVER=http://localhost:"$CONFIG_DSPACE_INTERNAL_PROXY_PORT"/solr

# Use ant from a tarball so we don't have to install it from apt with Java 11
ENV ANT_VERSION 1.10.8
ENV ANT_HOME /tmp/ant-$ANT_VERSION
ENV PATH $ANT_HOME/bin:$PATH

RUN mkdir $ANT_HOME && \
     wget -qO- "https://archive.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C $ANT_HOME

WORKDIR /tmp

# Install build dependencies (use upstream Node.js PPA so we can get v10.x)
RUN curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && echo 'deb [arch=amd64] https://deb.nodesource.com/node_10.x bionic main' > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y \
    nodejs \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Add a non-root user to perform the Maven build
RUN useradd -r -s /bin/bash -m -d "$DSPACE_HOME" dspace

# copy source to $WORKDIR/dspace
COPY --chown=dspace:dspace . dspace/

# Change to dspace user for build and install
USER dspace

# Copy customized DSpace local.cfg
COPY --chown=dspace:dspace config/local.cfg dspace

# Copy Active theme
RUN if [ -d dspace/custom_configuration/themes/$CONFIG_DSPACE_ACTIVE_THEME/theme ]; \
        then cp -r dspace/custom_configuration/themes/$CONFIG_DSPACE_ACTIVE_THEME/theme dspace/dspace/modules/xmlui-mirage2/src/main/webapp/themes/$CONFIG_DSPACE_ACTIVE_THEME; \
        else echo "No theme is defined"; \
    fi

ENV CONFIG_DSPACE_BASE_URL="$CONFIG_DSPACE_PROTOCOL:\/\/$CONFIG_DSPACE_HOSTNAME$CONFIG_DSPACE_PROXY_PORT_STRING"
# Set DSpace confirgation variables
RUN sed -i -e "s/#CONFIG_DSPACE_BASE_URL#/$CONFIG_DSPACE_BASE_URL/g" \
    -e "s/#CONFIG_DSPACE_HOSTNAME#/$CONFIG_DSPACE_HOSTNAME/g" \
    -e "s/#CONFIG_DSPACE_INTERNAL_PROXY_PORT_STRING#/$CONFIG_DSPACE_INTERNAL_PROXY_PORT_STRING/g" \
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
    dspace/local.cfg \
    &&  sed -i -e "s/#CONFIG_MAIL_FEEDBACK_RECIPIENT#/$CONFIG_MAIL_FEEDBACK_RECIPIENT/g" \
    -e "s/#CONFIG_DSPACE_NAME#/$CONFIG_DSPACE_NAME/g" \
    dspace/dspace/config/emails/* \
    && sed -i -e "s/#CONFIG_DSPACE_ACTIVE_THEME#/$CONFIG_DSPACE_ACTIVE_THEME/g" dspace/dspace/config/xmlui.xconf \
    && sed -i -e "s/#CONFIG_DSPACE_NAME#/$CONFIG_DSPACE_NAME/g" dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml \
    && if [ ! -z $CONFIG_GOOGLE_ANALYTICS_KEY ]; \
        then echo "xmlui.google.analytics.key=$CONFIG_GOOGLE_ANALYTICS_KEY" >> dspace/dspace/config/dspace.cfg; \
        else echo "xmlui.google.analytics.key IS NOT DEFINED"; \
    fi \
    && if [ ! -z $REQUEST_ITEM_HELPDESK_OVERRIDE ]; \
        then echo "request.item.helpdesk.override=$REQUEST_ITEM_HELPDESK_OVERRIDE" >> dspace/dspace/config/dspace.cfg; \
        else echo "request.item.helpdesk.override=false" >> dspace/dspace/config/dspace.cfg; \
    fi

WORKDIR /tmp/dspace/custom_configuration/themes/$CONFIG_DSPACE_ACTIVE_THEME/custom
# Add additional org.dspace.app.xmlui.artifactbrowser.AbstractSearch
RUN if [ -f org.dspace.app.xmlui.artifactbrowser.AbstractSearch.xml ]; \
    then sed -i -e '/#CONFIG_XMLUI_ARTIFACT_BROWSER_SEARCH_ADDITIONAL#/{r org.dspace.app.xmlui.artifactbrowser.AbstractSearch.xml' -e 'd}' /tmp/dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml; \
    else sed -i -e 's/#CONFIG_XMLUI_ARTIFACT_BROWSER_SEARCH_ADDITIONAL#//g' /tmp/dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml \
        && echo "CONFIG_XMLUI_ARTIFACT_BROWSER_SEARCH_ADDITIONAL IS NOT EXISTS"; \
    fi \
# Add additional org.dspace.app.xmlui.artifactbrowser.AdvancedSearch
    && if [ -f org.dspace.app.xmlui.artifactbrowser.AdvancedSearch.xml ]; \
    then sed -i -e '/#CONFIG_XMLUI_ARTIFACT_BROWSER_ADVANCED_SEARCH_ADDITIONAL#/{r org.dspace.app.xmlui.artifactbrowser.AdvancedSearch.xml' -e 'd}' /tmp/dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml; \
    else sed -i -e 's/#CONFIG_XMLUI_ARTIFACT_BROWSER_ADVANCED_SEARCH_ADDITIONAL#//g' /tmp/dspace/dspace-xmlui/src/main/webapp/i18n/messages.xml \
        && echo "CONFIG_XMLUI_ARTIFACT_BROWSER_ADVANCED_SEARCH_ADDITIONAL IS NOT EXISTS"; \
    fi \
# Add additional org.dspace.discovery.configuration.DiscoveryConfiguration
    && if [ -f org.dspace.discovery.configuration.DiscoveryConfiguration.xml ]; \
    then sed -i -e '/#CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_ADDITIONAL#/{r org.dspace.discovery.configuration.DiscoveryConfiguration.xml' -e 'd}' /tmp/dspace/dspace/config/spring/api/discovery.xml; \
    else sed -i -e 's/#CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_ADDITIONAL#//g' /tmp/dspace/dspace/config/spring/api/discovery.xml \
        && echo "CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_ADDITIONAL IS NOT EXISTS"; \
    fi \
# Add additional org.dspace.discovery.configuration.DiscoveryConfiguration.details details
    && if [ -f org.dspace.discovery.configuration.DiscoveryConfiguration.details.xml ]; \
    then sed -i -e '/#CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_DETAILS_ADDITIONAL#/{r org.dspace.discovery.configuration.DiscoveryConfiguration.details.xml' -e 'd}' /tmp/dspace/dspace/config/spring/api/discovery.xml; \
    else sed -i -e 's/#CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_DETAILS_ADDITIONAL#//g' /tmp/dspace/dspace/config/spring/api/discovery.xml \
        && echo "CONFIG_SPRING_API_DISCOVERY_SIDEBAR_SEARCH_DETAILS_ADDITIONAL IS NOT EXISTS"; \
    fi \
# Add additional org.dspace.discovery.configuration.DiscoveryMoreLikeThisConfiguration
    && if [ -f org.dspace.discovery.configuration.DiscoveryMoreLikeThisConfiguration.xml ]; \
    then sed -i -e '/#CONFIG_SPRING_API_DISCOVERY_SIMILARITY_METADATA_ADDITIONAL#/{r org.dspace.discovery.configuration.DiscoveryMoreLikeThisConfiguration.xml' -e 'd}' /tmp/dspace/dspace/config/spring/api/discovery.xml; \
    else sed -i -e 's/#CONFIG_SPRING_API_DISCOVERY_SIMILARITY_METADATA_ADDITIONAL#//g' /tmp/dspace/dspace/config/spring/api/discovery.xml \
        && echo "CONFIG_SPRING_API_DISCOVERY_SIMILARITY_METADATA_ADDITIONAL IS NOT EXISTS"; \
    fi \
# Custom page header
    && if [ -f costum.main.page.header.html ]; \
    then sed -i -e '/#CONFIG_MAIN_PAGE_HEADER#/{r costum.main.page.header.html' -e 'd}' /tmp/dspace/dspace/config/news-xmlui.xml; \
    else sed -i -e 's/#CONFIG_MAIN_PAGE_HEADER#//g' /tmp/dspace/dspace/config/news-xmlui.xml \
        && echo "CONFIG_MAIN_PAGE_HEADER IS NOT EXISTS"; \
    fi
WORKDIR /tmp

# Change back to dspace user to build the code
USER dspace

# Configure Node.js to use ~/.node_modules as the global prefix
RUN echo "prefix=$DSPACE_HOME/.node_modules" > "$DSPACE_HOME/.npmrc"
ENV PATH="$DSPACE_HOME/.node_modules/bin":$PATH
RUN npm install -g grunt-cli yarn

# Build DSpace with Mirage 2 enabled
RUN cd dspace && mvn package -Dmirage2.on=true -Dmirage2.deps.included=false

# Install compiled applications to $DSPACE_HOME
RUN cd dspace/dspace/target/dspace-installer \
    && ant init_installation init_configs install_code copy_webapps

# Change back to root user for cleanup
USER root

# Cleanup build deps
RUN apt-get -y remove \
    nodejs \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -y autoremove \
    && rm -rf "$DSPACE_HOME/.m2" /tmp/*


FROM tomcat:8.5
# Set some variables for the Tomcat container. Some were already set above in
# the build container, but they don't get propagated in multi-stage builds.
ENV DSPACE_HOME=/dspace \
    CATALINA_OPTS="-Xmx512M -Xms512M -Dfile.encoding=UTF-8" \
    VIRTUAL_ENV="$DSPACE_HOME"/dspace-statistics-api/venv
# Make sure to set PATH *after* setting $VIRTUAL_ENV or else it won't exist yet!
ENV PATH="$VIRTUAL_ENV"/bin:"$CATALINA_HOME/bin":"$DSPACE_HOME"/bin:$PATH

# Add DSpace user to this container *without* creating the home directory
# because we will copy it from the build container
RUN useradd -r -s /bin/bash -M -d "$DSPACE_HOME" dspace

# Remove default Tomcat webapps
RUN rm -rf "$CATALINA_HOME/webapps"

# Copy the $DSPACE_HOME (/dspace) directory from the build container to
# the Tomcat runtime container.
COPY --chown=dspace:dspace --from=build "$DSPACE_HOME" "$DSPACE_HOME"

RUN mv -f "$DSPACE_HOME/webapps" "$CATALINA_HOME" \
    && sed -i s/CONFIDENTIAL/NONE/ "$CATALINA_HOME"/webapps/rest/WEB-INF/web.xml \
    # Rename xmlui app to ROOT so it is available on /
    && mv "$CATALINA_HOME"/webapps/xmlui "$CATALINA_HOME"/webapps/ROOT

# Tweak default Tomcat server configuration
COPY config/server.xml "$CATALINA_HOME"/conf/server.xml

# Install root filesystem
COPY rootfs /

RUN sed -i "s/#CONFIG_DSPACE_PROXY_PORT#/$CONFIG_DSPACE_PROXY_PORT/g" "$CATALINA_HOME"/conf/server.xml \
    # Copy Handle server
    && if [ -d /tmp/dspace/custom_configuration/themes/$CONFIG_DSPACE_ACTIVE_THEME/handle-server ]; \
        then cp -r /tmp/dspace/custom_configuration/themes/$CONFIG_DSPACE_ACTIVE_THEME/handle-server $DSPACE_HOME/; \
        else echo "No Handle server files found"; \
    fi \
    # Make sure the crontab uses the correct DSpace directory
    && sed -i "s#DSPACE=/dspace#DSPACE=$DSPACE_HOME#g" /etc/cron.d/dspace-maintenance-tasks \
    && rm -rf /tmp/*

# Install runtime dependencies
RUN apt-get update \
    && apt-get install -y \
    postgresql-client \
    imagemagick \
    ghostscript \
    cron \
    less \
    vim \
    python3 \
    python3-venv \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -y autoremove

WORKDIR "$DSPACE_HOME"

# Clone DSpace statistics API, set up virtual environment, and install deps
RUN git clone --branch v1.2.1 https://github.com/ilri/dspace-statistics-api.git \
    && python3 -m venv "$VIRTUAL_ENV" \
    && . "$VIRTUAL_ENV/bin/activate" \
    && pip install -r "$DSPACE_HOME"/dspace-statistics-api/requirements.txt

# We don't need git anymore
RUN apt-get -y remove git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -y autoremove

COPY GeoLite2-City/GeoLite2-City.mmdb "$DSPACE_HOME"/config/

# Change to dspace user for for adding cron jobs
USER dspace
RUN (crontab -l 2>/dev/null; echo '# Compress DSpace logs (checker.log, cocoon.log, handle-plugin.log and solr.log) older than yesterday') | crontab - \
    && (crontab -l 2>/dev/null; echo '20 0 * * * find /dspace/log -regextype posix-extended -iregex ".*\.log.*" ! -iregex ".*dspace\.log.*" ! -iregex ".*\.xz" ! -newermt "Yesterday" -exec chrt -b 0 -e ionice -c2 -n7 xz {} \; >> '$DSPACE_HOME'/log/cron_tab_logs.log 2>&1') | crontab - \
    && (crontab -l 2>/dev/null; echo '# Compress DSpace logs (dspace.log) older than 1 week') | crontab - \
    && (crontab -l 2>/dev/null; echo '25 0 * * * find /dspace/log -regextype posix-extended -iregex ".*dspace\.log.*" ! -iregex ".*\.xz" ! -newermt "1 week ago" -exec chrt -b 0 -e ionice -c2 -n7 xz {} \; >> '$DSPACE_HOME'/log/cron_tab_logs.log 2>&1') | crontab - \
    && (crontab -l 2>/dev/null; echo '# Compress Tomcat logs (catalina, host-manager, localhost and manager) older older than yesterday') | crontab - \
    && (crontab -l 2>/dev/null; echo '30 0 * * * find /usr/local/tomcat/logs -regextype posix-extended -iregex ".*\.log.*" ! -iregex ".*\.xz" ! -newermt "Yesterday" -exec chrt -b 0 -e ionice -c2 -n7 xz {} \; >> '$DSPACE_HOME'/log/cron_tab_logs.log 2>&1') | crontab - \
    && (crontab -l 2>/dev/null; echo '# Compress Tomcat logs (localhost_access_log) older than 1 week') | crontab - \
    && (crontab -l 2>/dev/null; echo '35 0 * * * find /usr/local/tomcat/logs -regextype posix-extended -iregex ".*\.txt" ! -iregex ".*\.xz" ! -newermt "1 week ago" -exec chrt -b 0 -e ionice -c2 -n7 xz {} \; >> '$DSPACE_HOME'/log/cron_tab_logs.log 2>&1') | crontab -
USER root

RUN chown -R dspace:dspace "$DSPACE_HOME" /usr/local/tomcat/logs "$CATALINA_HOME"/conf

# Build info
RUN echo "Debian GNU/Linux `cat /etc/debian_version` image. (`uname -rsv`)" >> /root/.built \
    && echo "- with `java -version 2>&1 | awk 'NR == 2'`" >> /root/.built \
    && echo "- with DSpace $DSPACE_VERSION on Tomcat $TOMCAT_VERSION"  >> /root/.built \
    && echo "\nNote: if you need to run commands interacting with DSpace you should enter the" >> /root/.built \
    && echo "container as the dspace user, ie: docker exec -it -u dspace dspace /bin/bash" >> /root/.built

EXPOSE 2641 8000 8080 5000
# will run `start-dspace` script as root, then drop to dspace user
CMD ["sh","-c","gunicorn --bind 0.0.0.0:5000 --chdir $DSPACE_HOME/dspace-statistics-api dspace_statistics_api.app --log-file=$DSPACE_HOME/log/statistics.log --daemon && start-dspace"]

