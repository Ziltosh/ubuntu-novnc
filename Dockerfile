FROM ubuntu:22.04
EXPOSE 8080 5901
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

RUN apt-get update
RUN apt-get install -y xfce4 xfce4-terminal xubuntu-default-settings xubuntu-icon-theme
RUN apt-get install -y novnc
RUN apt-get install -y tightvncserver websockify
RUN apt-get install -y wget net-tools wget curl openssh-client git
RUN apt-get install -y software-properties-common
RUN apt-get install -y sudo
ENV USER root

# 2. Ajouter le PPA officiel de l'équipe Mozilla (pour avoir la version non-Snap)
RUN add-apt-repository -y ppa:mozillateam/ppa

# 3. Prioriser ce dépôt pour éviter qu'Ubuntu ne réessaie d'installer Snap
RUN echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox

# 4. Installer Firefox "proprement"
RUN apt-get update && apt-get install -y firefox

COPY start.sh /start.sh
RUN chmod a+x /start.sh

RUN useradd -ms /bin/bash user
RUN mkdir /.novnc
RUN chown user:user /.novnc

# 2. Ajouter l'utilisateur au groupe sudo
RUN usermod -aG sudo user

# 3. Configurer sudo pour ne PAS demander de mot de passe
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY config /home/user
RUN chown -R user:user /home/user

ENV TITLE=Metatrader5
ENV WINEPREFIX="/config/.wine"
ENV WINEDEBUG=-all

RUN \
  apt-get install --no-install-recommends -y \
    ca-certificates \
  && mkdir -pm755 /etc/apt/keyrings \
  && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
  && wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources \
  && dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install --install-recommends -y winehq-stable \
  && echo "**** cleanup ****" \
  && apt-get autoclean

RUN \
  apt-get -y install gedit vim \
  && apt-get autoclean \
  && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
  
USER user

COPY ./mt5.sh mt5.sh
RUN chmod +x mt5.sh
RUN mt5.sh

WORKDIR /.novnc
RUN wget -qO- https://github.com/novnc/noVNC/archive/v1.6.0.tar.gz | tar xz --strip 1 -C $PWD
RUN ln -s vnc.html index.html

WORKDIR /home/user

CMD ["sh","/start.sh"]
