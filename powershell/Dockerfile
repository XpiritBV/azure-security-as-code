FROM microsoft/powershell

RUN AZ_REPO=$(lsb_release -cs)
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \ sudo tee /etc/apt/sources.list.d/azure-cli.list

RUN apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
RUN apt-get install apt-transport-https
RUN apt-get update && sudo apt-get install azure-cli