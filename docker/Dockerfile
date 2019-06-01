FROM fedora

RUN echo "fastestmirror=true" >> /etc/dnf/dnf.conf
RUN dnf update -y && dnf clean all
RUN dnf install -y \
        git \
        pungi \
        jigdo \
        @development-tools \
        intltool \
        livecd-tools \
        && dnf clean all

WORKDIR /mangos

CMD ["/bin/bash"]
