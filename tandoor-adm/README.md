# Tandoor ADM

__Tandoor Version__: _`2.6.13`_


Tandoor-adm is an application for ADM, the operating system of [ASUSTOR](https://www.asustor.com/) (ASUS).
This application uses the Tunarr Docker image available at [vabene1111/tandoor](https://github.com/vabene1111/tandoor).

## Requirements

- application docker-ce (>=20.10.17.r1) ;
- server with an x86-64 architecture ;
- ADM (>=3.5.0) ;


Select the application `.apk` and follow the installation process.

__:warning: This application is not an Android application !__

## Configuration folder

This application will create a folder in `/share/Docker/Tandoor`. This folder will contain all Tunarr settings, channels, and database data.

## How to update Tandoor for ADM ?

When an update is available you can do it directly from APP CENTRAL in ADM. If you want to do it manually, uninstall Tunarr and install the new version — your data under `/share/Docker/Tandoor` will be kept.

## An issue or a request ?

You can report a problem, ask for help or make changes related to this ADM package on the package repository issues page. Remember that this package wraps Tandoor; Tandoor itself is developed upstream at [vabene1111/tandoor](https://github.com/vabene1111/tandoor).