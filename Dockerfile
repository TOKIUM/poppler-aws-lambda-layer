FROM lambci/lambda-base-2:build

ENV WORK_DIR /usr/local/work
ENV TARGET_DIR /opt
ENV LOCAL_DIR /usr/local

RUN mkdir -p $WORK_DIR

WORKDIR $WORK_DIR

# Curl
ENV CURL_VERSION 7.77.0
ENV CURL_SOURCE curl-${CURL_VERSION}.tar.xz
ENV CURL_MD5 3cf78c539cae019cf96ba38571706e06

RUN yum install -y openssl-devel && \
  curl -LO https://curl.haxx.se/download/${CURL_SOURCE} && \
  (test "$(md5sum ${CURL_SOURCE})" = "${CURL_MD5}  ${CURL_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${CURL_SOURCE} && \
  cd curl* && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig ./configure \
    CPPFLAGS=-I${TARGET_DIR}/include \
    LDFLAGS=-L$(TARGET_DIR)/lib \
    --enable-threaded-resolver \
    --with-openssl \
    --disable-static \
    --disable-docs \
    --prefix=${TARGET_DIR} \
    --exec-prefix=${LOCAL_DIR} \
    --libdir=${TARGET_DIR}/lib \
    --mandir=${LOCAL_DIR}/share/man && \
  make && \
  make install && \
  cd .. && \
  rm -rf curl*

# CMake
ENV CMAKE_VERSION 3.20.1
ENV CMAKE_SOURCE cmake-${CMAKE_VERSION}.tar.gz
ENV CMAKE_MD5 b47fa0be657ae8715c695fd9ea979ce9

RUN curl -LO https://cmake.org/files/v3.20/${CMAKE_SOURCE} && \
  (test "$(md5sum ${CMAKE_SOURCE})" = "${CMAKE_MD5}  ${CMAKE_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${CMAKE_SOURCE} && \
  cd cmake* && \
  sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig ./bootstrap --prefix=${LOCAL_DIR} && \
  make -j `nproc` && \
  make install && \
  cd .. && \
  rm -rf cmake*

# FreeType 2
ENV FREETYPE2_VERSION 2.10.4
ENV FREETYPE2_SOURCE freetype-${FREETYPE2_VERSION}.tar.xz
ENV FREETYPE2_MD5 0e6c0e9b218be3ba3e26e1d23b1c80dd

RUN curl -LO  https://downloads.sourceforge.net/freetype/${FREETYPE2_SOURCE} && \
  (test "$(md5sum ${FREETYPE2_SOURCE})" = "${FREETYPE2_MD5}  ${FREETYPE2_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${FREETYPE2_SOURCE} && \
  cd freetype* && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig ./configure \
    CPPFLAGS=-I${TARGET_DIR}/include \
    LDFLAGS=-L$(TARGET_DIR)/lib \
    --enable-freetype-config \
    --with-sysroot=${TARGET_DIR} \
    --disable-static \
    --disable-docs \
    --prefix=${TARGET_DIR} \
    --exec-prefix=${LOCAL_DIR} \
    --libdir=${TARGET_DIR}/lib \
    --mandir=${LOCAL_DIR}/share/man && \
  make && \
  make install && \
  cd .. && \
  rm -rf freetype*

# Fontconfig
ENV FONTCONFIG_DIR $TARGET_DIR/fontconfig
ENV FONTCONFIG_VERSION 2.13.91
ENV FONTCONFIG_SOURCE fontconfig-${FONTCONFIG_VERSION}.tar.xz
ENV FONTCONFIG_MD5 f235f55d31d3b5daff69ee090f01b5d4

RUN mkdir -p $FONTCONFIG_DIR && \
  yum install -y gperf libuuid-devel expat-devel && \
  curl -LO https://www.freedesktop.org/software/fontconfig/release/${FONTCONFIG_SOURCE} && \
  (test "$(md5sum ${FONTCONFIG_SOURCE})" = "${FONTCONFIG_MD5}  ${FONTCONFIG_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${FONTCONFIG_SOURCE} && \
  cd fontconfig* && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig ./configure \
    CPPFLAGS=-I${TARGET_DIR}/include \
    LDFLAGS=-L$(TARGET_DIR)/lib \
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


# LCMS2
ENV LCMS2_VERSION 2.12
ENV LCMS2_SOURCE lcms2-${LCMS2_VERSION}.tar.gz
ENV LCMS2_MD5 8cb583c8447461896320b43ea9a688e0

RUN curl -LO https://downloads.sourceforge.net/lcms/${LCMS2_SOURCE} && \
  (test "$(md5sum ${LCMS2_SOURCE})" = "${LCMS2_MD5}  ${LCMS2_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${LCMS2_SOURCE} && \
  cd lcms2* && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig ./configure \
    CPPFLAGS=-I${TARGET_DIR}/include \
    LDFLAGS=-L$(TARGET_DIR)/lib \
    --disable-static \
    --prefix=${TARGET_DIR} \
    --exec-prefix=${LOCAL_DIR} \
    --libdir=${TARGET_DIR}/lib \
    --mandir=${LOCAL_DIR}/share/man && \
  make && \
  make install && \
  cd .. && \
  rm -rf lcms2*

# NASM (for libjpeg-turbo)
ENV NASM_VERSION 2.15.05
ENV NASM_SOURCE nasm-${NASM_VERSION}.tar.gz

RUN curl -LO https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/${NASM_SOURCE} && \
  tar xf ${NASM_SOURCE} && \
  cd nasm* && \
  ./autogen.sh && \
  ./configure --prefix=${LOCAL_DIR} && \
  make && \
  make install && \
  cd .. && \
  rm -rf nasm*

# libjpeg-turbo
ENV LIBJPEG_TURBO_VERSION 2.1.0
ENV LIBJPEG_TURBO_SOURCE libjpeg-turbo-${LIBJPEG_TURBO_VERSION}.tar.gz
ENV LIBJPEG_TURBO_MD5 be306afc2d2ebd6931b634df0e8cbaf5

RUN curl -LO https://downloads.sourceforge.net/libjpeg-turbo/${LIBJPEG_TURBO_SOURCE} && \
  (test "$(md5sum ${LIBJPEG_TURBO_SOURCE})" = "${LIBJPEG_TURBO_MD5}  ${LIBJPEG_TURBO_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${LIBJPEG_TURBO_SOURCE} && \
  cd libjpeg* && \
  mkdir -p build && \
  cd build && \
  cmake .. \
    -DCMAKE_INSTALL_PREFIX=${TARGET_DIR} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR:PATH=lib \
    -DCMAKE_INSTALL_BINDIR:PATH=${LOCAL_DIR}/bin \
    -DCMAKE_INSTALL_DOCDIR:PATH=${LOCAL_DIR}/share/doc/libjpeg-turbo \
    -DENABLE_STATIC=false && \
  make && \
  make install && \
  cd ../.. && \
  rm -rf libjpeg*

# OpenJPEG
ENV OPENJP2_VERSION 2.4.0
ENV OPENJP2_SOURCE openjp2-${OPENJP2_VERSION}.tar.gz
ENV OPENJP2_MD5 4d388298335947367e91f1d100468af1

RUN curl -L https://github.com/uclouvain/openjpeg/archive/v${OPENJP2_VERSION}/openjpeg-${OPENJP2_VERSION}.tar.gz -o ${OPENJP2_SOURCE} && \
  (test "$(md5sum ${OPENJP2_SOURCE})" = "${OPENJP2_MD5}  ${OPENJP2_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${OPENJP2_SOURCE} && \
  cd openjpeg* && \
  mkdir -p build && \
  cd build && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${TARGET_DIR} \
    -DCMAKE_INSTALL_BINDIR:PATH=${LOCALDIR}/bin \
    -DCMAKE_INSTALL_DOCDIR:PATH=${LOCALDIR}/share/doc/openjpeg2 \
    -DBUILD_STATIC_LIBS:bool=off && \
  make clean && \
  make install && \
  cd ../.. && \
  rm -rf openjpeg*

# libpng
ENV LIBPNG_VERSION 1.6.37
ENV LIBPNG_SOURCE libpng-${LIBPNG_VERSION}.tar.xz
ENV LIBPNG_MD5 015e8e15db1eecde5f2eb9eb5b6e59e9

RUN curl -LO http://prdownloads.sourceforge.net/libpng/${LIBPNG_SOURCE} && \
  (test "$(md5sum ${LIBPNG_SOURCE})" = "${LIBPNG_MD5}  ${LIBPNG_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${LIBPNG_SOURCE} && \
  cd libpng* && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig ./configure \
    CPPFLAGS=-I${TARGET_DIR}/include \
    LDFLAGS=-L$(TARGET_DIR)/lib \
    --disable-dependency-tracking \
    --disable-static \
    --prefix=${TARGET_DIR} \
    --exec-prefix=${LOCAL_DIR} \
    --libdir=${TARGET_DIR}/lib \
    --mandir=${LOCAL_DIR}/share/man && \
  make && \
  make install && \
  cd .. && \
  rm -rf libpng*

# libtiff
ENV LIBTIFF_VERSION 4.3.0
ENV LIBTIFF_SOURCE tiff-${LIBTIFF_VERSION}.tar.gz
ENV LIBTIFF_MD5 0a2e4744d1426a8fc8211c0cdbc3a1b3

RUN curl -LO http://download.osgeo.org/libtiff/${LIBTIFF_SOURCE} && \
  (test "$(md5sum ${LIBTIFF_SOURCE})" = "${LIBTIFF_MD5}  ${LIBTIFF_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${LIBTIFF_SOURCE} && \
  cd tiff* && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig ./configure \
    CPPFLAGS=-I${TARGET_DIR}/include \
    LDFLAGS=-L$(TARGET_DIR)/lib \
    --with-docdir=/usr/local/share/doc/tiff \
    --disable-dependency-tracking \
    --disable-static \
    --prefix=${TARGET_DIR} \
    --exec-prefix=${LOCAL_DIR} \
    --libdir=${TARGET_DIR}/lib \
    --mandir=${LOCAL_DIR}/share/man && \
  make && \
  make install && \
  cd .. && \
  rm -rf tiff*

# Pixman
ENV PIXMAN_VERSION 0.40.0
ENV PIXMAN_SOURCE pixman-0.40.0.tar.gz
ENV PIXMAN_MD5 73858c0862dd9896fb5f62ae267084a4

RUN curl -LO https://www.cairographics.org/releases/${PIXMAN_SOURCE} && \
  (test "$(md5sum ${PIXMAN_SOURCE})" = "${PIXMAN_MD5}  ${PIXMAN_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${PIXMAN_SOURCE} && \
  cd pixman* && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig ./configure \
    CPPFLAGS=-I${TARGET_DIR}/include \
    LDFLAGS=-L$(TARGET_DIR)/lib \
    --disable-static \
    --prefix=${TARGET_DIR} \
    --exec-prefix=${LOCAL_DIR} \
    --libdir=${TARGET_DIR}/lib \
    --mandir=${LOCAL_DIR}/share/man && \
  make && \
  make install && \
  cd .. && \
  rm -rf pixman*

# Automake (for Cairo)
ENV AUTOMAKE_VERSION 1.16.1
ENV AUTOMAKE_SOURCE automake-${AUTOMAKE_VERSION}.tar.gz
ENV AUTOMAKE_MD5 83cc2463a4080efd46a72ba2c9f6b8f5

RUN curl -LO https://ftp.gnu.org/gnu/automake/${AUTOMAKE_SOURCE} && \
  md5sum ${AUTOMAKE_SOURCE} && \
  (test "$(md5sum ${AUTOMAKE_SOURCE})" = "${AUTOMAKE_MD5}  ${AUTOMAKE_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${AUTOMAKE_SOURCE} && \
  cd automake* && \
  ./configure --prefix=${LOCAL_DIR} && \
  make && \
  make install && \
  cd .. && \
  rm -rf automake*

# Cairo
ENV CAIRO_VERSION 1.17.4
ENV CAIRO_SOURCE cairo-${CAIRO_VERSION}.tar.xz
ENV CAIRO_MD5 bf9d0d324ecbd350d0e9308125fa4ce0

RUN curl -LO https://www.cairographics.org/snapshots/${CAIRO_SOURCE} && \
  (test "$(md5sum ${CAIRO_SOURCE})" = "${CAIRO_MD5}  ${CAIRO_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${CAIRO_SOURCE} && \
  cd cairo* && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig ./configure \
    CPPFLAGS=-I${TARGET_DIR}/include \
    LDFLAGS=-L$(TARGET_DIR)/lib \
    --disable-static \
    --enable-tee \
    --prefix=${TARGET_DIR} \
    --exec-prefix=${LOCAL_DIR} \
    --libdir=${TARGET_DIR}/lib \
    --mandir=${LOCAL_DIR}/share/man && \
  make && \
  make install && \
  cd .. && \
  rm -rf cairo*

# Poppler
ENV POPPLER_VERSION 21.06.1
ENV POPPLER_SOURCE poppler-${POPPLER_VERSION}.tar.xz
ENV POPPLER_MD5 dbad7032b680720ea6d570fd608b849e

RUN curl -LO https://poppler.freedesktop.org/${POPPLER_SOURCE} && \
  (test "$(md5sum ${POPPLER_SOURCE})" = "${POPPLER_MD5}  ${POPPLER_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${POPPLER_SOURCE} && \
  cd poppler* && \
  git clone git://git.freedesktop.org/git/poppler/test testdata && \
  mkdir build && \
  cd build && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig:$PKG_CONFIG_PATH cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${TARGET_DIR} \
    -DCMAKE_INSTALL_DOCDIR=${LOCAL_DIR}/doc/poppler \
    -DTESTDATADIR=testdata \
    -DENABLE_UNSTABLE_API_ABI_HEADERS:bool=on \
    -DENABLE_BOOST=off \
    -DENABLE_QT5:bool=off \
    -DENABLE_QT6:bool=off && \
  make -j `nproc` && \
  make install && \
  cd ../.. && \
  rm -rf poppler*

# Copy required shared objects which do not exist on AWS Lambda
RUN cp /lib64/libexpat.so* /opt/lib

CMD ["/opt/poppler/bin/pdfinfo"]
