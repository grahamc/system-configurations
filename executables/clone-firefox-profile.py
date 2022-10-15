#!/bin/env python

import logging
import os
import shutil
import subprocess
import sys
import tempfile
from configparser import ConfigParser, SectionProxy
from logging import error, warning, critical
from pathlib import Path
from typing import Optional, Generator, TextIO, TypeVar
import re

PATH_KEY: str = 'Path'

T = TypeVar('T')


def main() -> None:
    if 'linux' not in sys.platform:
        abort('Sorry, the only supported platform is Linux.')

    backup_config: Path = backup(get_profiles_config_file())
    print(
        f'(Changes will be made to the profiles config file. If you notice any issues there is a backup in {backup_config.as_posix()})')

    profiles_by_name: dict[str, Path] = get_profiles_by_name()
    profile_names: list[str] = list(profiles_by_name.keys())

    source_profile_name: str = choose(profile_names, 'Choose the profile to clone:')
    source_profile: Path = profiles_by_name[source_profile_name]

    print('Enter the name for the new profile:', end=' ')
    while True:
        destination_profile_name: str = input()
        if destination_profile_name in profile_names:
            print('A profile with this name already exists, please enter a different name:', end=' ')
            continue
        # TODO: There are more valid characters for a file, but this should be fine for now
        if re.match(r'^[\w\- ]+$', destination_profile_name) is None:
            print('The given name is not a valid filename, please enter a different name:', end=' ')
            continue

        break
    destination_profile: Path = register_profile(destination_profile_name)

    print('Cloning...')
    try:
        clone_profile(source_profile, destination_profile)
    except Exception as _:
        # cleanup
        if destination_profile.exists():
            delete(destination_profile)
        deregister_profile(destination_profile)

        print('Failed to clone. Cause:')
        raise
    print('Cloning successful!')


def register_profile(profile_name: str) -> Path:
    profile: Path = create_profile(profile_name)
    delete(profile)

    return profile


def deregister_profile(target_profile: Path) -> None:
    profiles_config = get_profiles_config()
    target_section_name: Optional[str] = None
    for section_name in profiles_config.sections():
        if 'profile' not in section_name.lower():
            continue

        profile_section = profiles_config[section_name]
        if PATH_KEY not in profile_section:
            error(f'The profile section "{section_name}" does not have a "{PATH_KEY}" key')
            continue

        profile_directory_basename = profile_section[PATH_KEY]
        if profile_directory_basename == target_profile.name:
            target_section_name = section_name
            break

    if target_section_name is None:
        return

    profiles_config.remove_section(target_section_name)
    save_profiles_config(profiles_config)


def create_profile(name: str) -> Path:
    execute('firefox', '-CreateProfile', name)
    profiles_by_name: dict[str, Path] = get_profiles_by_name()
    if name not in profiles_by_name:
        message: str = f'Cannot find newly created profile with name "{name}"'
        critical(message)
        abort(message)

    return profiles_by_name[name]


def get_profiles_by_name() -> dict[str, Path]:
    profiles_by_name: dict[str, Path] = {}
    profiles: list[Path] = get_profiles()
    profile: Path
    for profile in profiles:
        profile_basename: str = profile.name
        separator_index: Optional[int] = None
        try:
            separator_index = profile_basename.index('.')
        except Exception as _:
            message: str = f'Profile basename does not have the format "<hash>.<profile name>". basename="{profile_basename}"'
            critical(message)
            abort(message)
        profile_name: str = profile_basename[separator_index + 1:]
        profiles_by_name[profile_name] = profile

    return profiles_by_name


def get_profiles() -> list[Path]:
    profiles_directory: Path = get_profiles_directory()
    profiles_config: ConfigParser = get_profiles_config()
    profile_directories: list[Path] = []
    section_name: str
    for section_name in profiles_config.sections():
        if 'profile' not in section_name.lower():
            continue

        profile_section: SectionProxy = profiles_config[section_name]
        if PATH_KEY not in profile_section:
            error(f'The profile section "{section_name}" does not have a "{PATH_KEY}" key')
            continue

        profile_directory_basename: str = profile_section[PATH_KEY]
        profile_directory: Path = profiles_directory / profile_directory_basename
        try:
            assert_directory_exists(profile_directory)
        except Exception as _:
            error(f'The profile directory {profile_directory.as_posix()} is not a directory. section="{section_name}"')
            continue

        profile_directories.append(profile_directory)

    if len(profile_directories) == 0:
        abort(f'No profiles found in the profiles directory: {profiles_directory}')

    return profile_directories


def get_profiles_config() -> ConfigParser:
    profiles_config_file: Path = get_profiles_config_file()
    profiles_config: ConfigParser = ConfigParser()
    # This sets the mapper for keys in the ini file. By setting this to str, they won't be changed in any way.
    # By default, keys are lowercased. The linter complains, but this should be fine. The link belows shows similar
    # code in the official python docs:
    # https://docs.python.org/3/library/configparser.html#configparser.ConfigParser.optionxform
    profiles_config.optionxform = str  # type: ignore
    profiles_config.read(profiles_config_file.as_posix())

    return profiles_config


def save_profiles_config(config: ConfigParser) -> None:
    profiles_config_file: Path = get_profiles_config_file()
    configfile: TextIO
    with open(profiles_config_file.as_posix(), 'w') as configfile:
        config.write(configfile, space_around_delimiters=False)


def clone_profile(source: Path, destination: Path) -> None:
    copy(source, destination)

    # replace any references to the source profile's path with the destination profile's path
    source_basename: str = source.name
    destination_basename: str = destination.name
    ignored_extensions: set[str] = {'jsonlz4', 'sqlite', 'lz4', 'db', 'mozlz4', 'so', 'files', 'final', 'sqlite-wal',
                                    'sqlite-shm', 'xpi'}
    files: Generator[Path] = (file for file in destination.glob("**/*")
                              if file.is_file and 'http' not in file.name and len(file.suffix) > 0 and file.suffix[
                                                                                                       1:] not in ignored_extensions)
    file: Path
    for file in files:
        try:
            file_contents: str = file.read_text()
            new_file_contents: str = file_contents.replace(source_basename, destination_basename)
            file.write_text(new_file_contents)
        except Exception as _:
            warning(f'Failed to update paths in file {file.as_posix()}')


def get_profiles_directory() -> Path:
    home_path: Optional[str] = os.getenv('HOME')
    if home_path is None:
        abort('The HOME environment variable is not defined')
    home_directory: Path = Path(home_path)
    assert_directory_exists(home_directory)

    profiles_directory: Path = home_directory / '.mozilla' / 'firefox'
    assert_directory_exists(profiles_directory)

    return profiles_directory


def get_profiles_config_file() -> Path:
    profiles_directory: Path = get_profiles_directory()
    profiles_config_file: Path = profiles_directory / 'profiles.ini'
    assert_file_exists(profiles_config_file)

    return profiles_config_file


def backup(file: Path) -> Path:
    file_basename: str = file.name
    backup_basename: str = f'.{file_basename}.backup'
    backup_file: Path = file.with_name(backup_basename)

    if backup_file.exists():
        delete(backup_file)
    copy(file, backup_file)

    return backup_file


def copy(source: Path, destination: Path) -> None:
    if source.is_dir():
        shutil.copytree(source, destination, symlinks=True, ignore_dangling_symlinks=True)
    else:
        shutil.copy2(source, destination, follow_symlinks=False)


def delete(file: Path) -> None:
    if file.is_dir():
        shutil.rmtree(file)
    else:
        file.unlink()


def assert_file_exists(file: Path) -> None:
    if not file.exists():
        raise Exception(f'The file "{file}" does not exist')
    if not file.is_file():
        raise Exception(f'The file "{file}" is not a regular file')


def assert_directory_exists(directory: Path) -> None:
    if not directory.exists():
        raise Exception(f'The directory "{directory}" does not exist')
    if not directory.is_dir():
        raise Exception(f'The file "{directory}" is not a directory')


def shell(command: str) -> str:
    return subprocess.check_output(command, text=True, shell=True)


def execute(*argv: str) -> str:
    return subprocess.check_output(argv, text=True)


def choose(choices: list[T], prompt: str) -> T:
    print(prompt)
    for index, choice in enumerate(choices):
        print(f'{index + 1}) {choice}')

    choice_number: Optional[int] = None
    while True:
        response: str = input('Choice: ')

        try:
            choice_number = int(response)
        except ValueError as _:
            print(f'"{response}" is not a number.')
            continue

        choices_count: int = len(choices)
        if choice_number < 1 or choice_number > choices_count:
            print(f'Number must be between 1 and {choices_count}.')
            continue

        break

    return choices[choice_number - 1]


def confirm(prompt: str) -> bool:
    print(f'{prompt} (y/n):', end=' ')
    choices: list[str] = ['y', 'n']
    while (response := input().lower()) not in choices:
        print(f'Please respond with "y" or "n".')

    return True if response == 'y' else False


def abort(message: str) -> None:
    sys.exit(f'Error: {message}')


def setup_logging() -> None:
    logfile_path: str = tempfile.NamedTemporaryFile().name
    logging.basicConfig(
        filename=logfile_path,
        encoding='utf=8',
        level=logging.DEBUG,
        format='%(asctime)s::%(levelname)s::%(message)s')
    print(f'(logs for this clone will be stored in {logfile_path})\n')


if __name__ == "__main__":
    setup_logging()
    main()
