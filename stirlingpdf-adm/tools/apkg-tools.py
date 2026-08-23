#!/usr/bin/env python3
# Copyright (c) 2011-2013 Asustor Systems, Inc. All Rights Reserved.
# Adapted for Python 3.12 (print functions, octal literals, tarfile filter).

# -*- coding: utf-8 -*-

import os
import sys
import argparse
import zipfile
import tarfile
import tempfile
import shutil
import json
import glob
import re
import csv

__author__ = 'Walker Lee <walkerlee@asustor.com>'
__copyright__ = 'Copyright (C) 2011-2013  ASUSTOR Systems, Inc.  All Rights Reserved.'
__version__ = '0.1'
__abs_path__ = os.path.abspath(sys.argv[0])
__program__ = os.path.basename(__abs_path__)


def find_developer(app):
    developer = None

    if os.path.exists('apkg-developer-mapping.csv'):
        with open('apkg-developer-mapping.csv', 'r') as f:
            for row in csv.reader(f):
                if row[0] == app:
                    developer = row[1]
                    break

    return developer


class Chdir:
    def __init__(self, newPath):
        self.newPath = newPath

    def __enter__(self):
        self.savedPath = os.getcwd()
        os.chdir(self.newPath)

    def __exit__(self, etype, value, traceback):
        os.chdir(self.savedPath)


class Apkg:
    umask = 0o022
    tmp_dir = '/tmp'

    tmp_prefix = 'APKG-'

    apk_format = {
        'version': '2.0',
        'format': 'zip',
        'suffix': 'apk'
    }

    apk_file_contents = {
        'version': 'apkg-version',
        'data': 'data.tar.gz',
        'control': 'control.tar.gz'
    }

    apk_special_folders = {
        'control': 'CONTROL',
        'webman': 'webman',
        'web': 'www'
    }

    apk_control_files = {
        'pkg-config': 'config.json',
        'changlog': 'changelog.txt',
        'description': 'description.txt',
        'icon': 'icon.png',
        'script-pre-install': 'pre-install.sh',
        'script-pre-uninstall': 'pre-uninstall.sh',
        'script-post-install': 'post-install.sh',
        'script-post-uninstall': 'post-uninstall.sh',
        'script-start-stop': 'start-stop.sh',
    }

    apk_web_settings = {
        'user': 'admin',
        'group': 'administrators',
        'uid': 999,
        'gid': 999,
        'perms': 0o770
    }

    def __init__(self):
        self.pid = os.getpid()
        self.cwd = os.getcwd()
        self.pkg_tmp_dir = self.tmp_dir + '/APKG.' + str(self.pid)

    def __del__(self):
        pass

    def pkg_misc_check(self):
        pass

    def compress_pkg(self):
        pass

    def __safe_chown(self, path, uid, gid):
        try:
            os.chown(path, uid, gid)
        except PermissionError:
            pass

    def __check_apk_format(self, apk_file):
        file_list = []

        try:
            with zipfile.ZipFile(apk_file, 'r') as apk_zip:
                file_list = apk_zip.namelist()
        except zipfile.BadZipFile:
            print('File is not a apk file: %s' % (apk_file))
            return False

        if not file_list:
            print('File is empty: %s' % (apk_file))
            return False

        result = True
        for (key, value) in self.apk_file_contents.items():
            if value not in file_list:
                print('Can\'t found file in apk file: %s' % (value))
                result = False

        return result

    def __excluded_files(self, path):
        return 'CONTROL' in path

    def __zip_archive(self, apk_file, file_list):
        with zipfile.ZipFile(apk_file, 'w') as apk_zip:
            for one_file in file_list:
                apk_zip.write(one_file)

    def __zip_extract(self, apk_file, member, path):
        with zipfile.ZipFile(apk_file, 'r') as apk_zip:
            apk_zip.extract(member, path)

    def __tar_archive(self, tar_file, path):
        with tarfile.open(tar_file, 'w:gz') as tar:
            if os.path.basename(tar_file) == self.apk_file_contents['data']:
                for name in os.listdir(path):
                    if self.__excluded_files(name):
                        continue
                    tar.add(os.path.join(path, name), arcname=name)
            else:
                for name in os.listdir(path):
                    tar.add(os.path.join(path, name), arcname=name)

    def __tar_extract(self, tar_file, path):
        with tarfile.open(tar_file, 'r:gz') as tar:
            tar.extractall(path)

    def __get_apkg_version(self, version_file):
        with open(version_file) as f:
            version = f.read().rstrip()
        return version

    def __get_app_info_v1(self, control_dir):
        with open(control_dir + '/' + self.apk_control_files['pkg-config']) as data_file:
            data = json.load(data_file)
        return data

    def __get_app_info_v2(self, control_dir):
        with open(control_dir + '/' + self.apk_control_files['pkg-config']) as data_file:
            data = json.load(data_file)
        return data

    def __get_app_info(self, control_dir, apkg_version):
        if apkg_version == '1.0':
            return self.__get_app_info_v1(control_dir)
        elif apkg_version == '2.0':
            return self.__get_app_info_v2(control_dir)
        else:
            return None

    def __check_app_layout(self, app_dir):
        control_dir = app_dir + '/' + self.apk_special_folders['control']

        if not os.path.isdir(control_dir):
            print('[Not found] CONTROL folder: %s' % (control_dir))
            return False

        config_file = control_dir + '/' + self.apk_control_files['pkg-config']

        if not os.path.isfile(config_file):
            print('[Not found] config file: %s' % (config_file))
            return False

        return True

    def __check_app_info_fields(self, app_info):
        require_fields = ['package', 'version', 'architecture', 'firmware']

        for field in require_fields:
            try:
                if app_info['general'][field].strip() == '':
                    print('Empty field: %s' % (field))
                    return False
            except KeyError:
                print('Missing field: %s' % (field))
                return False

        return True

    def __filter_special_chars(self, string, pattern):
        filter_string = re.sub(pattern, '', string)
        return filter_string

    def __check_app_package_name(self, package):
        return True if self.__filter_special_chars(package, '[a-zA-Z0-9.+-]') == '' else False

    def create(self, folder, dest_dir=None):
        app_dir = os.path.abspath(folder)
        if not os.path.isdir(app_dir):
            print('Not a directory: %s' % (app_dir))
            return -1

        control_dir = app_dir + '/' + self.apk_special_folders['control']
        config_file = control_dir + '/' + self.apk_control_files['pkg-config']

        if not self.__check_app_layout(app_dir):
            print('Invalid App layout: %s' % (app_dir))
            return -1

        os.chmod(control_dir, 0o755)
        self.__safe_chown(control_dir, 0, 0)

        all_files = glob.glob(control_dir + '/*')
        sh_files = glob.glob(control_dir + '/*.sh')
        py_files = glob.glob(control_dir + '/*.py')

        for one_file in all_files:
            os.chmod(one_file, 0o644)
            self.__safe_chown(one_file, 0, 0)

        for one_file in sh_files:
            os.chmod(one_file, 0o755)
            os.system('dos2unix %s > /dev/null 2>&1' % (one_file))

        for one_file in py_files:
            os.chmod(one_file, 0o755)

        app_info = self.__get_app_info(control_dir, self.apk_format['version'])

        if not self.__check_app_info_fields(app_info):
            print('Invalid App config: %s' % (config_file))
            return -1

        if not self.__check_app_package_name(app_info['general']['package']):
            print('Invalid App package field: %s (valid characters [a-zA-Z0-9.+-])' % ('package'))
            return -1

        tmp_dir = tempfile.mkdtemp(prefix=self.tmp_prefix)

        version_file = tmp_dir + '/' + self.apk_file_contents['version']
        control_tar_gz = tmp_dir + '/' + self.apk_file_contents['control']
        data_tar_gz = tmp_dir + '/' + self.apk_file_contents['data']

        if dest_dir is None:
            dest_dir = os.getcwd()
        else:
            dest_dir = os.path.abspath(dest_dir)

        os.makedirs(dest_dir, exist_ok=True)

        apk_file = dest_dir + '/' + app_info['general']['package'] + '_' + app_info['general']['version'] + '_' + app_info['general']['architecture'] + '.' + self.apk_format['suffix']

        with open(version_file, 'w') as apkg_version:
            apkg_version.write(self.apk_format['version'] + '\n')

        with Chdir(app_dir):
            self.__tar_archive(data_tar_gz, '.')

        with Chdir(control_dir):
            self.__tar_archive(control_tar_gz, '.')

        with Chdir(tmp_dir):
            self.__zip_archive(apk_file, [self.apk_file_contents['version'], self.apk_file_contents['control'], self.apk_file_contents['data']])

        shutil.rmtree(tmp_dir, ignore_errors=True)

        print('Created: %s' % (apk_file))
        return apk_file

    def extract(self, package, dest_dir=None):
        apk_file = os.path.abspath(package)
        if not os.path.isfile(apk_file):
            print('Not a file: %s' % (apk_file))
            return -1

        if not self.__check_apk_format(apk_file):
            return -1

        tmp_dir = tempfile.mkdtemp(prefix=self.tmp_prefix)
        tmp_contents_dir = tmp_dir + '/@contents@'
        os.mkdir(tmp_contents_dir)

        self.__zip_extract(apk_file, self.apk_file_contents['version'], tmp_contents_dir)
        self.__zip_extract(apk_file, self.apk_file_contents['control'], tmp_contents_dir)
        self.__zip_extract(apk_file, self.apk_file_contents['data'], tmp_contents_dir)

        tmp_control_dir = tmp_dir + '/' + self.apk_special_folders['control']
        os.mkdir(tmp_control_dir)

        self.__tar_extract(tmp_contents_dir + '/' + self.apk_file_contents['control'], tmp_control_dir)
        self.__tar_extract(tmp_contents_dir + '/' + self.apk_file_contents['data'], tmp_dir)

        apkg_version = self.__get_apkg_version(tmp_contents_dir + '/' + self.apk_file_contents['version'])

        shutil.rmtree(tmp_contents_dir, ignore_errors=True)

        apk_info = self.__get_app_info(tmp_control_dir, apkg_version)

        if apk_info is None:
            print('Extract error: %s' % (apk_file))
            shutil.rmtree(tmp_dir, ignore_errors=True)
            return -1

        if dest_dir is None:
            dest_dir = os.getcwd()
        else:
            dest_dir = os.path.abspath(dest_dir)

        if apkg_version == '1.0':
            app_dir = dest_dir + '/' + apk_info['app']['name'] + '_' + apk_info['app']['version'] + '_' + apk_info['app']['architecture']
        elif apkg_version == '2.0':
            app_dir = dest_dir + '/' + apk_info['general']['name'] + '_' + apk_info['general']['version'] + '_' + apk_info['general']['architecture']

        if os.path.isdir(app_dir):
            print('The folder is exist, please remove it: %s' % (app_dir))
            shutil.rmtree(tmp_dir, ignore_errors=True)
            return -1
        else:
            shutil.move(tmp_dir, app_dir)
            return app_dir


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='asustor package helper.')

    subparsers = parser.add_subparsers(help='sub-commands')

    parser_create = subparsers.add_parser('create', help='create package from folder')
    parser_create.add_argument('folder', help='select a package layout folder to pack')
    parser_create.add_argument('--destination', help='move apk to destination folder')
    parser_create.set_defaults(command='create')

    parser_extract = subparsers.add_parser('extract', help='extract package to folder')
    parser_extract.add_argument('package', help='select a package to extract')
    parser_extract.add_argument('--destination', help='extract apk to destination folder')
    parser_extract.set_defaults(command='extract')

    args = parser.parse_args()

    if not hasattr(args, 'command'):
        parser.print_help()
        sys.exit(1)

    apkg = Apkg()

    if args.command == 'create':
        result = apkg.create(args.folder, args.destination)
        sys.exit(0 if result != -1 else 1)

    elif args.command == 'extract':
        result = apkg.extract(args.package, args.destination)
        sys.exit(0 if result != -1 else 1)
