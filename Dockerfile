FROM lambci/lambda-base-2:build

ENV WORK_DIR /usr/local/work
ENV TARGET_DIR /opt

RUN mkdir -p $WORK_DIR

WORKDIR $WORK_DIR

# CMake
ENV CMAKE_SOURCE cmake-3.18.2.tar.gz
ENV CMAKE_MD5 7a882b3764f42981705286ac9daa29c2

RUN yum install -y openssl-devel libcurl-devel && \
  curl -LO https://cmake.org/files/v3.18/${CMAKE_SOURCE} && \
  (test "$(md5sum ${CMAKE_SOURCE})" = "${CMAKE_MD5}  ${CMAKE_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${CMAKE_SOURCE} && \
  cd cmake* && \
  sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake && \
  ./bootstrap --prefix=/usr && \
  make && \
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
    --disable-static \
    --disable-docs \
    --prefix=${TARGET_DIR} && \
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
    --prefix=${TARGET_DIR} && \
  make && \
  make install && \
  cd .. && \
  rm -rf fontconfig*

# Poppler
ENV POPPLER_VERSION 20.10.0
ENV POPPLER_SOURCE poppler-${POPPLER_VERSION}.tar.xz
ENV POPPLER_MD5 1103acc31277936a138613c97b38b82c

RUN curl -LO https://poppler.freedesktop.org/${POPPLER_SOURCE} && \
  (test "$(md5sum ${POPPLER_SOURCE})" = "${POPPLER_MD5}  ${POPPLER_SOURCE}" || { echo 'Checksum Failed'; exit 1; }) && \
  tar xf ${POPPLER_SOURCE} && \
  cd poppler* && \
  mkdir build && \
  cd build && \
  PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig:$PKG_CONFIG_PATH cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${TARGET_DIR}  \
    -DENABLE_UNSTABLE_API_ABI_HEADERS:bool=on \
    -DENABLE_LIBCURL:bool=off \
    -DENABLE_QT5:bool=off \
    -DENABLE_QT6:bool=off \
    -DENABLE_LIBOPENJPEG=none \
    -DENABLE_CMS=none \
    -DENABLE_DCTDECODER=none && \
  make && \
  make install && \
  cd ../.. && \
  rm -rf poppler*

# Copy required shared objects which do not exist on AWS Lambda
RUN cp /lib64/libexpat.so* /opt/lib

CMD ["/opt/poppler/bin/pdfinfo"]
