FROM debian/eol:etch

RUN echo 'deb [trusted=yes] http://archive.debian.org/debian/ etch main' > /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --force-yes gcc make libc6-dev ruby1.8 ruby1.8-dev libgtk1.2-dev libgdk-pixbuf-dev libxmu-dev rxvt xfonts-base xfonts-75dpi xfonts-100dpi xfonts-scalable && \
    rm -rf /var/lib/apt/lists/*

COPY ruby-gnome-all-0.34.tar.gz /tmp/

RUN cd /tmp && \
    tar -xzf ruby-gnome-all-0.34.tar.gz && \
    cd ruby-gnome-all-0.34/gtk && \
    ruby1.8 extconf.rb && make && make install && \
    cd /tmp/ruby-gnome-all-0.34/gdkpixbuf && \
    ruby1.8 extconf.rb && make && make install && \
    rm -rf /tmp/ruby-gnome-all-0.34*

# Setup /usr/local/share/bsd-explorer directory structure as expected by Explorer.rb
RUN mkdir -p /usr/local/share/bsd-explorer

WORKDIR /usr/local/share/bsd-explorer
COPY ruby-BSD-Explorer /usr/local/share/bsd-explorer

# Compile ruby-gtk-fix
RUN cd /usr/local/share/bsd-explorer/ruby-gtk-fix && \
    ruby1.8 extconf.rb && make

# Symlink ruby to ruby1.8
RUN ln -sf /usr/bin/ruby1.8 /usr/bin/ruby

ENV HOME=/root
ENV DISPLAY=:0
WORKDIR /root

CMD ["ruby", "/usr/local/share/bsd-explorer/explorer_alone"]
