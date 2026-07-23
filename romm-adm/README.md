# romm-adm

__RomM version__: _`5.0.0`_

romm-adm is an application for ADM, the operating system of [ASUSTOR](https://www.asustor.com/) (ASUS).
This application uses the RomM Docker image available at [rommapp/romm](https://github.com/rommapp/romm).

## Requirements

- application docker-ce (>=20.10.17.r1) ;
- server with an x86-64 architecture ;
- ADM (>=3.5.0) ;

__:warning: This application is not an Android application !__

## Configuration folder

This application will create a folder in `/share/Docker/Romm`. This folder will contain all of RomM's config files

## Adding Games

To add Rom's to RomM add them to the folder `/share/Media/Romm` Make sure that you follow RomM's folder configuration viewable [here](https://docs.romm.app/latest/getting-started/folder-structure/).

## How to update RomM for ADM ?

When an update is available you can do it directly from APP CENTRAL in ADM. If you want to do it manually, uninstall RomM and install the new version — your data under `/share/Docker/Romm` will be kept.

## An issue or a request ?

You can report a problem, ask for help or make changes related to this ADM package on the package repository issues page. Remember that this package wraps RomM; RomM itself is developed upstream at [rommapp/romm](https://github.com/rommapp/romm).
