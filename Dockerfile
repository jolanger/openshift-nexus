FROM       library/centos:7
MAINTAINER Deutsche Telekom


#Set basic properties
ENV SONATYPE_WORK='/sonatype-work' NEXUS_VERSION='2.11.4-01'
ENV http_proxy='http://172.22.236.11:3128' https_proxy='http://172.22.236.11:3128'
ENV CONTEXT_PATH='/' MAX_HEAP='768m' MIN_HEAP='256m' JAVA_OPTS='-server -XX:MaxPermSize=192m -Djava.net.preferIPv4Stack=true' LAUNCHER_CONF='./conf/jetty.xml ./conf/jetty-requestlog.xml'

RUN  echo -e "[main]\nproxy=http://172.22.236.11:3128" >> /etc/yum/yum.conf


RUN yum install -y \
  curl tar createrepo java-1.8.0-openjdk \
  && yum clean all

RUN mkdir -p /opt/sonatype/nexus \
  && curl --fail --silent --location --retry 3 \
    https://download.sonatype.com/nexus/oss/nexus-${NEXUS_VERSION}-bundle.tar.gz \
  | gunzip \
  | tar x -C /tmp nexus-${NEXUS_VERSION} \
  && mv /tmp/nexus-${NEXUS_VERSION}/* /opt/sonatype/nexus/ \
  && rm -rf /tmp/nexus-${NEXUS_VERSION}

RUN useradd -r -u 200 -m -c "nexus role account" -d ${SONATYPE_WORK} -s /bin/false nexus

#VOLUME ${SONATYPE_WORK}
RUN ls -ltra ${SONATYPE_WORK} 

EXPOSE 8081
WORKDIR /opt/sonatype/nexus
USER nexus
CMD ls -ltra ${SONATYPE_WORK} && ls -ltra / && whoami && java \
  -Dnexus-work=${SONATYPE_WORK} -Dnexus-webapp-context-path=${CONTEXT_PATH} \
  -Xms${MIN_HEAP} -Xmx${MAX_HEAP} \
  -cp 'conf/:lib/*' \
  ${JAVA_OPTS} \
  org.sonatype.nexus.bootstrap.Launcher ${LAUNCHER_CONF}

