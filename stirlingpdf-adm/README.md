
# stirlingpdf-adm

__StirlingPDF version__: _`3.1.0`_

stirlingpdf-adm is an application for ADM, the operating system of [ASUSTOR](https://www.asustor.com/) (ASUS).
This application uses the StirlingPDF Docker image available at [stirling-tools/stirling-pdf](https://github.com/Stirling-Tools/Stirling-PDF).

## Requirements

- application docker-ce (>=20.10.17.r1) ;
- server with an x86-64 architecture ;
- ADM (>=5.0.0) ;

__:warning: This application is not an Android application !__

## Configuration folder

This application will create a folder in `/share/Docker/StirlingPDF`. This folder will contain all of StirlingPDF's files.

## How to update StirlingPDF for ADM ?

When an update is available you can do it directly from APP CENTRAL in ADM. If you want to do it manually, uninstall StirlingPDF and install the new version — your data under `/share/Docker/StirlingPDF` will be kept.

## An issue or a request ?

You can report a problem, ask for help or make changes related to this ADM package on the package repository issues page. Remember that this package wraps StirlingPDF; StirlingPDF itself is developed upstream at [stirling-tools/stirling-pdf](https://github.com/Stirling-Tools/Stirling-PDF).
