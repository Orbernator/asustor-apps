
# music-assistant-adm

__Music Assistant version__: _`2.15.1`_

music-assistant-adm is an application for ADM, the operating system of [ASUSTOR](https://www.asustor.com/) (ASUS).
This application uses the MusicAssistant Docker image available at [music-assistant/server](https://github.com/music-assistant/server).

## Requirements

- application docker-ce (>=20.10.17.r1) ;
- server with an x86-64 architecture ;
- ADM (>=3.5.0) ;

__:warning: This application is not an Android application !__

## Configuration folder

This application will create a folder in `/share/Docker/MusicAssistant`. This folder will contain all of Music Assistant's files.

## How to update Music Assistant for ADM ?

When an update is available you can do it directly from APP CENTRAL in ADM. If you want to do it manually, uninstall Music Assistant and install the new version — your data under `/share/Docker/MusicAssistant` will be kept.

## An issue or a request ?

You can report a problem, ask for help or make changes related to this ADM package on the package repository issues page. Remember that this package wraps Music Assistant; Music Assistant itself is developed upstream at [music-assistant/server](https://github.com/music-assistant/server).
