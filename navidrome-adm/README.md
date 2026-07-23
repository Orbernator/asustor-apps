# navidrome-adm

__Navidrome version__: _`1.3.8`_


navidrome-adm is an application for ADM, the operating system of [ASUSTOR](https://www.asustor.com/) (ASUS).
This application uses the Tunarr Docker image available at [navidrome/navidrome](https://github.com/navidrome/navidrome).

## Requirements

- application docker-ce (>=20.10.17.r1) ;
- server with an x86-64 architecture ;
- ADM (>=3.5.0) ;

__:warning: This application is not an Android application !__

## Configuration folder

This application will create a folder in `/share/Docker/`. This folder will contain all of Navidrome's config files.

## Media

To add music to Navidrome add the files in`/share/Media/Navidrome`

## How to update Navidrome for ADM ?

When an update is available you can do it directly from APP CENTRAL in ADM. If you want to do it manually, uninstall Navidrome and install the new version — your data under `/share/Docker/Navidrome` will be kept.

## An issue or a request ?

You can report a problem, ask for help or make changes related to this ADM package on the package repository issues page. Remember that this package wraps Navidrome; Navidrome itself is developed upstream at [navidrome/navidrome](https://github.com/navidrome/navidrome).
