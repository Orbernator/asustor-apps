# tunarr-adm

__Tunarr version__: _`1.3.8`_

![GitHub license](https://img.shields.io/badge/license-GPL--3.0-%23fe7d37)

[![Donate][link-icon-coffee]][link-paypal-me] [![Website][link-icon-website]][link-website]

[link-icon-coffee]: https://img.shields.io/badge/%E2%98%95-Buy%20me%20a%20cup%20of%20coffee-991481.svg
[link-paypal-me]: https://www.paypal.me/EndMove/2.5eur
[link-icon-website]: https://img.shields.io/badge/%F0%9F%92%BB-My%20Web%20Site-0078D4.svg
[link-website]: https://www.endmove.eu/

tunarr-adm is an application for ADM, the operating system of [ASUSTOR](https://www.asustor.com/) (ASUS).
This application uses the Tunarr Docker image available at [chrisbenincasa/tunarr](https://github.com/chrisbenincasa/tunarr).

## Requirements

- application docker-ce (>=20.10.17.r1) ;
- server with an x86-64 architecture ;
- ADM (>=3.5.0) ;

## Installation

Download the `.apk` file available in the release versions
of this repository.

Go to `APP Central >> Manage >> Manual Installation`.

Select the application `.apk` and follow the installation process.

__:warning: This application is not an Android application !__

## Configuration folder

This application will create a folder in `/share/Docker/Tunarr`. This folder will contain all Tunarr settings, channels, and database data.

## Configuration

All information related to the configuration of the application on an ASUSTOR environment is available in the application description. Either in `/CONTROL/description.txt`.

## How to update Tunarr for ADM ?

When an update is available you can do it directly from APP CENTRAL in ADM. If you want to do it manually, uninstall Tunarr and install the new version — your data under `/share/Docker/Tunarr` will be kept.

## An issue or a request ?

You can report a problem, ask for help or make changes related to this ADM package on the package repository issues page. Remember that this package wraps Tunarr; Tunarr itself is developed upstream at [chrisbenincasa/tunarr](https://github.com/chrisbenincasa/tunarr).
