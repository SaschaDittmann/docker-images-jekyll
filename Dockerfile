FROM ruby:3.3-slim

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# This Dockerfile adds a non-root user with sudo access. 
ARG USERNAME=jekyll
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# EnvVars Ruby
ENV BUNDLE_HOME=/usr/local/bundle
ENV BUNDLE_DISABLE_PLATFORM_WARNINGS=true
ENV BUNDLE_BIN=/usr/local/bundle/bin
ENV RUBYOPT=-W0

# EnvVars Image
ENV JEKYLL_VERSION="~> 4.3.3"
ENV JEKYLL_VAR_DIR=/var/jekyll
ENV JEKYLL_DATA_DIR=/srv/jekyll
ENV JEKYLL_BIN=/usr/local/bundle/bin/jekyll
ENV JEKYLL_ENV=development

# EnvVars System
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV TZ=America/Chicago
ENV PATH="$JEKYLL_BIN:$PATH"
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US

# EnvVars Main
ENV VERBOSE=false
ENV FORCE_POLLING=false
ENV DRAFTS=false

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog locales 2>&1 \
    # Verify git, process tools installed
    && apt-get -y install git openssh-client iproute2 procps lsb-release build-essential zlib1g-dev \
    #
    # Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Set the locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN gem update --system \
    && gem install bundler \
    && gem install jekyll -v "$JEKYLL_VERSION" \
    && rm -rf /home/jekyll/.gem \
    && rm -rf $BUNDLE_HOME/cache \
    && rm -rf $GEM_HOME/cache \
    && rm -rf /root/.gem

RUN mkdir -p $JEKYLL_VAR_DIR \
    && mkdir -p $JEKYLL_DATA_DIR \
    && chown -R jekyll:jekyll $JEKYLL_DATA_DIR \
    && chown -R jekyll:jekyll $JEKYLL_VAR_DIR \
    && chown -R jekyll:jekyll $BUNDLE_HOME

CMD ["jekyll", "--help"]
WORKDIR /srv/jekyll
VOLUME  /srv/jekyll
EXPOSE 35729
EXPOSE 4000
