FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04
MAINTAINER Nimbix, Inc. <support@nimbix.net>

# Nimbix base OS
ENV DEBIAN_FRONTEND noninteractive
ADD https://github.com/nimbix/image-common/archive/master.zip /tmp/nimbix.zip
WORKDIR /tmp
RUN apt-get update && apt-get -y install sudo zip unzip && unzip nimbix.zip && rm -f nimbix.zip
RUN /tmp/image-common-master/setup-nimbix.sh
RUN touch /etc/init.d/systemd-logind
RUN apt-get -y install \
  locales \
  module-init-tools \
  xz-utils \
  vim \
  openssh-server \
  libpam-systemd \
  libmlx4-1 \
  libmlx5-1 \
  iptables \
  infiniband-diags \
  build-essential \
  curl \
  libibverbs-dev \
  libibverbs1 \
  librdmacm1 \
  librdmacm-dev \
  rdmacm-utils \
  libibmad-dev \
  libibmad5 \
  byacc \
  flex \
  git \
  cmake \
  screen \
  software-properties-common \
  python-software-properties \
  grep

# Clean and generate locales
RUN \
  apt-get clean && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG=en_US.UTF-8

# Setup Repos
RUN \
  echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | sudo tee -a /etc/apt/sources.list && \
  gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
  gpg -a --export E084DAB9 | apt-key add -&& \
  curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
  add-apt-repository -y ppa:webupd8team/java && apt-get update -q && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  apt-get update -yqq
# Install H2o dependancies

RUN \
  apt-get install -y \
  wget \
  python-pip \
  python-sklearn \
  python-pandas \
  python-numpy \
  python-matplotlib \
  r-base \
  r-base-dev \
  libssl-dev \
  libcurl4-openssl-dev

# Install R dependancies
RUN \
  /usr/bin/R -e 'chooseCRANmirror(graphics=FALSE, ind=47);install.packages(c("R.utils", "AUC", "mlbench", "Hmisc", "flexclust", "randomForest", "bit64", "HDtweedie", "RCurl", "jsonlite", "statmod", "devtools", "roxygen2", "testthat", "Rcpp", "fpc", "RUnit", "ade4", "glmnet", "gbm", "ROCR", "e1071", "ggplot2", "LiblineaR"))'

# Install Oracle Java 8
RUN \
apt-get install -y oracle-java8-installer && \
apt-get clean && \
rm -rf /var/cache/apt/*

WORKDIR /opt
# Install H2o
ADD h2o-3.11.0.99999 /opt/h2o3-xgboost

RUN \
  pip install --upgrade pip && \
  pip install /opt/h2o3-xgboost/python/h2o-*-py2.py3-none-any.whl
#  R CMD INSTALL /opt/h2o3-xgboost/R/h2o-*.tar.gz

EXPOSE 54321

COPY ./scripts/start-xgboost.sh /opt/start-xgboost.sh
RUN chmod +x /opt/start-xgboost.sh

# Nimbix Integrations
ADD ./NAE/AppDef.json /etc/NAE/AppDef.json
ADD ./NAE/AppDef.png /etc//NAE/default.png
ADD ./NAE/screenshot.png /etc/NAE/screenshot.png
ADD ./NAE/url.txt /etc/NAE/url.txt

# Nimbix JARVICE emulation
EXPOSE 22
RUN mkdir -p /usr/lib/JARVICE && cp -a /tmp/image-common-master/tools /usr/lib/JARVICE
RUN cp -a /tmp/image-common-master/etc /etc/JARVICE && chmod 755 /etc/JARVICE && rm -rf /tmp/image-common-master
RUN mkdir -m 0755 /data && chown nimbix:nimbix /data
RUN sed -ie 's/start on.*/start on filesystem/' /etc/init/ssh.conf
