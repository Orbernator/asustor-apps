
# linkwarden-adm

__Linkwarden version__: _`2.15.1`_

linkwarden-adm is an application for ADM, the operating system of [ASUSTOR](https://www.asustor.com/) (ASUS).
This application uses the Linkwarden Docker image available at [linkwarden/linkwarden](https://github.com/linkwarden/linkwarden).

## Requirements

- application docker-ce (>=20.10.17.r1) ;
- server with an x86-64 architecture ;
- ADM (>=3.5.0) ;

__:warning: This application is not an Android application !__

## Configuration folder

This application will create a folder in `/share/Docker/Linkwarden`. This folder will contain all of Linkwarden's files.

## How to update Linkwarden for ADM ?

When an update is available you can do it directly from APP CENTRAL in ADM. If you want to do it manually, uninstall Linkwarden and install the new version — your data under `/share/Docker/Linkwarden` will be kept.

## An issue or a request ?

You can report a problem, ask for help or make changes related to this ADM package on the package repository issues page. Remember that this package wraps Linkwarden; Linkwarden itself is developed upstream at [linkwarden/linkwarden](https://github.com/linkwarden/linkwarden).
