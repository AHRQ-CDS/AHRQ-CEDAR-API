This swagger UI setup was created by following the Plain old
HTML/CSS/JS (Standalone) instructions in the Swagger UI documentation
found here:

  https://swagger.io/docs/open-source-tools/swagger-ui/usage/installation/

The Swagger UI specific files were taken from the dist directory of
this Swagger UI release:

  swagger-ui-4.10.3

During deployment this directory is copied into the nginx container
and served statically.

You can also explore it standalone via docker:
```
docker run -p 80:8080 -e SWAGGER_JSON=/tmp/swagger.json -v `pwd`:/tmp swaggerapi/swagger-ui
```
where `pwd` is this directory. Then view by navigating to localhost in browser.

Similarly you can also edit the swagger description using the swagger editor via docker:
```
docker run -p 80:8080 -e SWAGGER_JSON=/tmp/swagger.json -v `pwd`:/tmp swaggerapi/swagger-editor
```

Steps to generate FHIR Swagger Models
1. Clone https://github.com/microsoft/fhir-codegen
2. Run `dotnet build` to build fhir-codegen-cli
3. Run `dotnet run -p src/fhir-codegen-cli --load-r5 latest --language openapi`
4. Open generated file at generated/OpenApi-R5.json
5. Copy necessary data type, classes to "definitions" section in swagger.json.
6. Convert swagger.json to swagger.yaml (the swagger editor has a convenient function to do this)
