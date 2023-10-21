import asyncio
import sys
from collections.abc import Awaitable

from kasa import Discover
from kasa import SmartPlug
from kasa import SmartDeviceException
from diskcache import Cache
from platformdirs import user_cache_dir


class SmartPlugController(object):
    _cache = Cache(user_cache_dir('my-speakers'))

    def __init__(self, plug_alias: str):
        self._plug_alias = plug_alias
        self._plug = self._get_plug()

    def turn_off(self):
        self._block_until_complete(self._plug.turn_off())

    def turn_on(self):
        self._block_until_complete(self._plug.turn_on())

    def is_on(self):
        return self._plug.is_on

    def _get_plug(self):
        plug = self._get_plug_from_cache()
        if plug is not None:
            return plug

        plug = self._find_plug()
        if plug is not None:
            return plug

        raise Exception("Unable to find a plug with this alias: " + self._plug_alias)

    def _get_plug_from_cache(self):
        if self._plug_alias in SmartPlugController._cache:
            ip_address = SmartPlugController._cache[self._plug_alias]
            assert isinstance(ip_address, str)
            plug = SmartPlug(ip_address)
            try:
                # Creating a SmartPlug instance successfully does not necessarily mean that there is a smart plug
                # at that ip address since requests won't be made to the plug until you call a method on the
                # SmartPlug. To make sure there's still a smart plug at this ip address I'm calling SmartPlug.update().
                self._block_until_complete(plug.update())
                return plug
            except SmartDeviceException as _:
                return None

        return None

    def _find_plug(self):
        ip_address_to_device_map = self._block_until_complete(Discover.discover(), timeout=10)
        for ip_address, device in ip_address_to_device_map.items():
            if device.alias == self._plug_alias and device.is_plug:
                self._add_plug_address_to_cache(ip_address)
                return device

        return None

    def _add_plug_address_to_cache(self, ip_address):
        SmartPlugController._cache[self._plug_alias] = ip_address

    def _block_until_complete(self, awaitable: Awaitable, timeout=1):
        return asyncio.get_event_loop().run_until_complete(asyncio.wait_for(awaitable, timeout=timeout))

if __name__ == "__main__":
    try:
        plug_controller = SmartPlugController(plug_alias='plug')
    except Exception as exception:
        sys.exit(2)

    if len(sys.argv) == 1:
        sys.exit(0 if plug_controller.is_on() else 1)
    elif sys.argv[1] == 'on':
        plug_controller.turn_on()
    elif sys.argv[1] == 'off':
        plug_controller.turn_off()
