FROM --platform=linux/amd64 amazonlinux:2023

ENV WORK_DIR=/usr/local/work
ENV TARGET_DIR=/opt
ENV LOCAL_DIR=/usr/local

# Poppler requires C++23, which the default GCC 11 does not support
ENV CC=gcc14-gcc
ENV CXX=gcc14-g++

# The amazonlinux:2023 image locks dnf to the release it was built from (2023.12.20261021),
# which has the vulnerable libbrotli 1.1.0-1.amzn2023.0.1 (CVE-2026-111497).
# Use the release with the fix (ALAS2023-2026-3334). The libraries below are copied into the layer.
# The build stops if the fixed libbrotli is not installed.
ENV AL2023_RELEASEVER=2023.12.20261026

RUN dnf install -y --releasever ${AL2023_RELEASEVER} \
    gcc14 \
    gcc14-c++ \
    make \
    tar \
    xz \
    gzip \
    findutils \
    pkgconf-pkg-config \
    gperf \
    expat-devel \
    libjpeg-turbo-devel \
    libpng-devel \
    openjpeg2-devel \
    lcms2-devel \
    zlib-devel \
    brotli-devel && \
  dnf clean all && \
  test "$(rpm -q --qf '%{VERSION}-%{RELEASE}' libbrotli)" = "1.1.0-1.amzn2023.0.2"

RUN mkdir -p $WORK_DIR

WORKDIR $WORK_DIR

# CMake (Poppler requires 3.28 or later, but Amazon Linux 2023 provides 3.22)
ENV CMAKE_VERSION=3.31.12
ENV CMAKE_SOURCE=cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz
ENV CMAKE_SHA256=0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c

RUN curl -fLO https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_SOURCE} && \
  echo "${CMAKE_SHA256}  ${CMAKE_SOURCE}" | sha256sum -c - && \
  tar xf ${CMAKE_SOURCE} -C ${LOCAL_DIR} --strip-components=1 && \
  rm -f ${CMAKE_SOURCE}

# FreeType 2
# Built without HarfBuzz, because the one of Amazon Linux 2023 pulls HarfBuzz, GLib and Graphite2 into the layer.
ENV FREETYPE2_VERSION=2.15.0
ENV FREETYPE2_SOURCE=freetype-${FREETYPE2_VERSION}.tar.xz
ENV FREETYPE2_SHA256=93cd47eb719c325107f2d3cf087d06299e944c3b48a40b55537302304dea1dd5

RUN curl -fLO https://download.savannah.gnu.org/releases/freetype/${FREETYPE2_SOURCE} && \
  echo "${FREETYPE2_SHA256}  ${FREETYPE2_SOURCE}" | sha256sum -c - && \
  tar xf ${FREETYPE2_SOURCE} && \
  cd freetype-${FREETYPE2_VERSION} && \
  ./configure \
    --with-zlib \
    --with-png \
    --without-bzip2 \
    --without-brotli \
    --without-harfbuzz \
    --disable-static \
    --prefix=${TARGET_DIR} \
    --exec-prefix=${LOCAL_DIR} \
    --libdir=${TARGET_DIR}/lib \
    --mandir=${LOCAL_DIR}/share/man && \
  make && \
  make install && \
  cd .. && \
  rm -rf freetype*

# Fontconfig (Poppler requires 2.15 or later, but Amazon Linux 2023 provides 2.13)
ENV FONTCONFIG_DIR=$TARGET_DIR/fontconfig
ENV FONTCONFIG_VERSION=2.18.3
ENV FONTCONFIG_SOURCE=fontconfig-${FONTCONFIG_VERSION}.tar.xz
ENV FONTCONFIG_SHA256=4f7b554a38cdf78c033f666c8871f3749e14a094f65a07f630c91ed0b43d35e3

RUN mkdir -p $FONTCONFIG_DIR && \
  curl -fLO https://gitlab.freedesktop.org/api/v4/projects/890/packages/generic/fontconfig/${FONTCONFIG_VERSION}/${FONTCONFIG_SOURCE} && \
  echo "${FONTCONFIG_SHA256}  ${FONTCONFIG_SOURCE}" | sha256sum -c - && \
  tar xf ${FONTCONFIG_SOURCE} && \
  cd fontconfig-${FONTCONFIG_VERSION} && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig ./configure \
    --sysconfdir=${FONTCONFIG_DIR}/etc \
    --localstatedir=${FONTCONFIG_DIR}/var \
    --disable-static \
    --disable-docs \
    --prefix=${TARGET_DIR} \
    --exec-prefix=${LOCAL_DIR} \
    --libdir=${TARGET_DIR}/lib \
    --mandir=${LOCAL_DIR}/share/man && \
  make && \
  make install && \
  cd .. && \
  rm -rf fontconfig*

# Poppler
# libcurl, NSS and GPGME are disabled so that the layer does not depend on OpenSSL.
ENV POPPLER_VERSION=26.10.0
ENV POPPLER_SOURCE=poppler-${POPPLER_VERSION}.tar.xz
ENV POPPLER_SHA256=6792cb7c69205007ad87d2e936cecc5b3a31fac29ab54ffc3175fdb6b2a6ce35

RUN curl -fLO https://poppler.freedesktop.org/${POPPLER_SOURCE} && \
  echo "${POPPLER_SHA256}  ${POPPLER_SOURCE}" | sha256sum -c - && \
  tar xf ${POPPLER_SOURCE} && \
  cd poppler-${POPPLER_VERSION} && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${TARGET_DIR} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_MANDIR=${LOCAL_DIR}/share/man \
    -DCMAKE_DISABLE_FIND_PACKAGE_Cairo=ON \
    -DENABLE_LIBCURL=OFF \
    -DENABLE_NSS3=OFF \
    -DENABLE_GPGME=OFF \
    -DENABLE_LIBTIFF=OFF \
    -DENABLE_BOOST=OFF \
    -DENABLE_HARFBUZZ=OFF \
    -DENABLE_GLIB=OFF \
    -DENABLE_GOBJECT_INTROSPECTION=OFF \
    -DENABLE_QT5=OFF \
    -DENABLE_QT6=OFF \
    -DBUILD_CPP_TESTS=OFF \
    -DBUILD_MANUAL_TESTS=OFF && \
  cmake --build build -j `nproc` && \
  cmake --install build && \
  cd .. && \
  rm -rf poppler*

# Copy required shared objects which do not exist on AWS Lambda (nodejs24.x)
RUN for lib in \
    libbrotlicommon.so.1 \
    libbrotlidec.so.1 \
    libexpat.so.1 \
    libjpeg.so.62 \
    liblcms2.so.2 \
    libopenjp2.so.7 \
    libpng16.so.16; do \
    cp -P /usr/lib64/${lib} $(readlink -f /usr/lib64/${lib}) ${TARGET_DIR}/lib; \
  done

CMD ["/opt/bin/pdfinfo"]
