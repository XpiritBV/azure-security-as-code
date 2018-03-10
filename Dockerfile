FROM microsoft/powershell

COPY *.yaml /yaml/

RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ trusty main" | \
    tee /etc/apt/sources.list.d/azure-cli.list

RUN sh

RUN apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
RUN apt-get install apt-transport-https
RUN apt-get update
RUN apt-get install azure-cli

#Install Yaml parsing module
RUN pwsh -c Install-Module PSYaml -f

#Login the Azure SPN
RUN pwsh -c az login --service-principal --username USER --password PW --tenant roadtoalm.com

RUN pwsh


