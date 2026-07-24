
# youtarr-adm

__Youtarr version__: _`1.76.1`_

youtarr-adm is an application for ADM, the operating system of [ASUSTOR](https://www.asustor.com/) (ASUS).
This application uses the Youtarr Docker image available at [dialmaster/youtarr](https://github.com/dialmasterorg/youtarr).

## Requirements

- application docker-ce (>=20.10.17.r1) ;
- server with an x86-64 architecture ;
- ADM (>=5.0.0) ;

__:warning: This application is not an Android application !__

## Configuration folder

This application will create a folder in `/share/Docker/Youtarr`. This folder will contain all of Youtarr's files.
Videos will be automatically downloaded to `/share/Download/Youtarr`.

## How to update Youtarr for ADM ?

When an update is available you can do it directly from APP CENTRAL in ADM. If you want to do it manually, uninstall Youtarr and install the new version — your data under `/share/Docker/Youtarr` and `/share/Download/Youtarr` will be kept.

## An issue or a request ?

You can report a problem, ask for help or make changes related to this ADM package on the package repository issues page. Remember that this package wraps Youtarr; Youtarr itself is developed upstream at [dialmaster/youtarr](https://github.com/dialmasterorg/youtarr).
