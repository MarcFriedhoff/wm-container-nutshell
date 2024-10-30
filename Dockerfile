FROM sagcr.azurecr.io/webmethods-microservicesruntime:10.15.0.8-ubi as wpm

# add the WPM package to the image
ADD --chown=sagadmin:sagadmin wpm /opt/softwareag/wpm

ENV PATH=/opt/softwareag/wpm/bin:$PATH

FROM wpm as dev

# use the WPM access token to install the WmSAP package
ARG WPM_ACCESS_TOKEN

# add the WmSAP package to the image
RUN wpm install -ws https://packages.webmethods.io -wr licensed -j $WPM_ACCESS_TOKEN WmSAP:v10.1.0.13 -d /opt/softwareag/IntegrationServer

# copy all libs to the softwareag directory
ADD --chown=sagadmin:sagadmin libs /opt/softwareag

WORKDIR /

FROM dev as solution

# copy all packages under the server/packages directory to the image
ADD --chown=sagadmin:sagadmin server/dev/packages /opt/softwareag/IntegrationServer/packages