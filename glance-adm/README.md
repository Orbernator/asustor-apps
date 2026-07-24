# glance-adm

__Glance version__: _`0.8.5`_

glance-adm is an application for ADM, the operating system of [ASUSTOR](https://www.asustor.com/) (ASUS).
This application uses the Glance Docker image available at [glanceapp/glance](https://github.com/glanceapp/glance).

## Requirements

- application docker-ce (>=20.10.17.r1) ;
- server with an x86-64 architecture ;
- ADM (>=3.5.0) ;

__:warning: This application is not an Android application !__

## Configuration folder

This application will create a folder in `/share/Docker/Glance`. This folder will contain all of Glance's config files

## How to update Glance for ADM ?

When an update is available you can do it directly from APP CENTRAL in ADM. If you want to do it manually, uninstall Glance and install the new version — your data under `/share/Docker/Glance` will be kept.

## An issue or a request ?

You can report a problem, ask for help or make changes related to this ADM package on the package repository issues page. Remember that this package wraps Glance; Glance itself is developed upstream at [glanceapp/glance](https://github.com/glanceapp/glance).
