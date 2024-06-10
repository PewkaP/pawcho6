# ======== etap1 ==== nazwa: dev_stage =================
# === cel: budowa aplikacji w kontenerze roboczym ======

FROM alpine:3.19.1 as dev_stage

# zmienna VERSION przekazywana do procesu budowy obrazu 
ARG VERSION

# uaktualnienie systemu w warstwie bazowej oraz instalacja
# niezbędnych komponentów środowiska roboczego
RUN apk update && \
    apk upgrade && \
    apk add --no-cache nodejs npm git openssh openssh-client git

# Dodanie klucza SSH do kontenera i konfiguracja
# Upewnij się, że masz skonfigurowane klucze SSH do GitHub
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# Klonowanie repozytorium
RUN --mount=type=ssh git clone git@github.com:PewkaP/LAB5.git LAB5
# Ustawienie katalogu roboczego
WORKDIR /app

# Inicjalizacja aplikacji React
RUN npx create-react-app rlab5

# Kopiowanie przygotowanej aplikacji
COPY App.js ./rlab5/src

# Powiązanie zmiennej VERSION z procesem budowania
ENV REACT_APP_VERSION=${VERSION}

# Instalacja zależności i budowa aplikacji
RUN cd rlab5 && npm install && npm run build

# ========= etap2 ==== tzw. produkcyjny =================
# == cel: budowa produkcyjnego kontenera zawierajacego == 
# == wylacznie serwer HTTP oraz zbudowaną aplikacje =====

FROM nginx:mainline-alpine3.19-slim

# Dodanie narzędzia do realizacji testu HEALTHCHECK 
RUN apk add --update --no-cache curl

# Powtórzenie deklaracji zmiennej ze względu na chęć 
# wpisania wersji aplikacji do metadanych
ARG VERSION

# Deklaracja metadanych zgodna z OCI
LABEL org.opencontainers.image.authors="Piotr Plewka"
LABEL org.opencontainers.image.version="$VERSION"

# Kopiowanie aplikacji jako domyślnej dla serwera HTTP
COPY --from=dev_stage /app/rlab5/build/. /var/www/html

# Kopiowanie konfiguracji serwera HTTP dla środowiska produkcyjnego
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Deklaracja portu aplikacji w kontenerze 
EXPOSE 80

# Monitorowanie dostępności serwera 
HEALTHCHECK --interval=10s --timeout=1s \
 CMD curl -f http://localhost:80/ || exit 1

# Deklaracja sposobu uruchomienia serwera
CMD ["nginx", "-g", "daemon off;"]
