
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build

WORKDIR /src
COPY src/WiredBrain.Web/WiredBrain.Web.csproj .
RUN dotnet restore

ARG RELEASE_VERSION=0.1
ARG BUILD_NUMBER=999

COPY src/WiredBrain.Web/ .
RUN dotnet publish -c Release -o /out \
      -p:Version=${RELEASE_VERSION}.${BUILD_NUMBER} \
      WiredBrain.Web.csproj

# app image
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine

ARG RELEASE_VERSION=0.1
ARG BUILD_NUMBER=999
ARG COMMIT_SHA=dockerfile

ENV ProductsApi__Url="http://products-api/products" \
    StockApi__Url="http://stock-api:8080/stock" 

WORKDIR /app
COPY --from=build /out/ .

LABEL org.opencontainers.image.version=${RELEASE_VERSION}.${BUILD_NUMBER}
LABEL org.opencontainers.image.revision=${COMMIT_SHA}

ENTRYPOINT ["dotnet", "/app/WiredBrain.Web.dll"]