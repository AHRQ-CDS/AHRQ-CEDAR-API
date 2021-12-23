This swagger UI setup was created by following the Plain old
HTML/CSS/JS (Standalone) instructions in the Swagger UI documentation
found here:

  https://swagger.io/docs/open-source-tools/swagger-ui/usage/installation/

The Swagger UI specific files were taken from the dist directory of
this Swagger UI release:

  swagger-ui-3.51.0

During deployment this directory is copied into the nginx container
and served statically.

You can also explore it standalone via docker:
```
docker run -p 80:8080 -e SWAGGER_JSON=/tmp/swagger.json -v `pwd`:/tmp swaggerapi/swagger-ui
```
where `pwd` is this directory. Then view by navigating to localhost in browser.