FROM python:3.11.4-alpine3.18 AS dependencies
WORKDIR /srv
RUN apk update && apk add --update --no-cache build-base libpq-dev
RUN pip install --upgrade pip pipenv flake8
COPY Pipfile* .
RUN pipenv check --use-lock && \
  pipenv requirements > requirements.txt && \
  pip wheel --no-cache-dir --no-deps --wheel-dir /srv/wheels -r requirements.txt

FROM dependencies AS develop
RUN addgroup -g 1000 alpine && \
  adduser -u 1000 -G alpine -h /home/alpine -D alpine
WORKDIR /srv
RUN apk update && apk add --update --no-cache libpq
COPY --from=dependencies /srv/wheels wheels
COPY --from=dependencies /srv/requirements.txt requirements.txt
RUN chown -R alpine:alpine /srv
USER alpine
RUN pip install --no-cache /srv/wheels/*
ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
#RUN flake8 --ignore=E501,F401 .

FROM python:3.11.4-alpine3.18
ARG BUILD_DATE
ARG BUILD_VERSION
LABEL maintaner="Jay Amorin <jay.amorin@gmail.com>"
LABEL org.label-schema.name="skyway-posts-api"
LABEL org.label-schema.vcs-url="https://github.com/jayamorin/skyway-posts-api"
LABEL org.label-schema.vcs-ref=${BUILD_VERSION}
LABEL org.label-schema.build-date=${BUILD_DATE}
RUN addgroup -g 1000 alpine && \
  adduser -u 1000 -G alpine -h /home/alpine -D alpine
RUN apk update && apk add --update --no-cache libpq
WORKDIR /srv
COPY --from=dependencies /srv/wheels wheels
COPY --from=dependencies /srv/requirements.txt requirements.txt
COPY src app
RUN chown -R alpine:alpine /srv
USER alpine
RUN pip install --no-cache /srv/wheels/*
ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
