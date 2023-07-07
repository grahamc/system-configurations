import asyncio
import sys
from collections.abc import Awaitable

from kasa import Discover
from kasa import SmartPlug
from kasa import SmartDeviceException
from diskcache import Cache
from platformdirs import user_cache_dir


class SmartPlugController(object):
    def __init__(self, plug_alias: str):
        self.plug = self._get_plug(plug_alias)

    def _get_plug(self, plug_alias):
        cache = Cache(user_cache_dir('my-speakers'))
        if plug_alias in cache:
            ip_address = cache[plug_alias]
            assert isinstance(ip_address, str)
            plug = SmartPlug(ip_address)
            try:
                self._block_until_complete(plug.update())
                return plug
            except SmartDeviceException as _:
                ip_address_to_device_map = self._block_until_complete(Discover.discover())
                for ip_address, device in ip_address_to_device_map.items():
                    if device.alias == plug_alias and device.is_plug:
                        cache[plug_alias] = ip_address
                        return plug

        raise Exception("Can't find plug with alias: " + plug_alias)

    def turn_off(self):
        self._block_until_complete(self.plug.turn_off())

    def turn_on(self):
        self._block_until_complete(self.plug.turn_on())

    def is_on(self):
        return self.plug.is_on

    def _block_until_complete(self, awaitable: Awaitable):
        return asyncio.get_event_loop().run_until_complete(awaitable)

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
