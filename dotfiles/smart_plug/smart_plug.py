import asyncio
import sys
from collections.abc import Awaitable
from typing import TypeVar
from typing_extensions import cast


from kasa import Discover, SmartDevice
from kasa import SmartPlug
from kasa import SmartDeviceException
from diskcache import Cache  # pyright: ignore [reportMissingTypeStubs]
from platformdirs import user_cache_dir
import psutil


class SmartPlugController(object):
    _cache = Cache(user_cache_dir("my-speakers"))

    def __init__(self, plug_alias: str):
        super().__init__()
        self._plug_alias = plug_alias
        self._plug = self._get_plug()

    def turn_off(self):
        self._block_until_complete(
            self._plug.turn_off()  # pyright: ignore [reportUnknownArgumentType, reportUnknownMemberType]
        )

    def turn_on(self):
        self._block_until_complete(
            self._plug.turn_on()  # pyright: ignore [reportUnknownArgumentType, reportUnknownMemberType]
        )

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
            ip_address = cast(str, SmartPlugController._cache[self._plug_alias])
            assert isinstance(ip_address, str)
            plug = SmartPlug(ip_address)
            try:
                # Creating a SmartPlug instance successfully does not necessarily mean
                # that there is a smart plug at that ip address since requests won't
                # be made to the plug until you call a method on the SmartPlug. To
                # make sure there's still a smart plug at this ip address I'm calling
                # SmartPlug.update().
                self._block_until_complete(plug.update())
                return plug
            except (SmartDeviceException, TimeoutError) as _:
                return None

        return None

    def _find_plug(self):
        for ip_address, device in self._discover_devices().items():
            if device.alias == self._plug_alias and device.is_plug:
                self._add_plug_address_to_cache(ip_address)
                return device

        return None

    # TODO: Kasa's discovery fails when I'm connected to a VPN. I don't completely
    # understand why, but I know that it has something to do with the broadcast address
    # that they use, 255.255.255.255. I'm guessing this is because that IP is supposed
    # to be an alias for 'this network' which will mean that of the VPN network when I'm
    # connected to it and not that of my actual wifi/ethernet network. To get around
    # this, I look for the correct broadcast address myself using psutil which gives me
    # all addresses assigned to each NIC on my machine. I then try discovery using all
    # the addresses that are marked as broadcast addresses until I find a Kasa device.
    def _discover_devices(self) -> dict[str, SmartDevice]:
        # return the first non-empty map of devices
        return next(
            filter(
                bool,
                map(
                    self._discover_devices_for_broadcast_address,
                    self._get_broadcast_addresses(),
                ),
            ),
            cast(dict[str, SmartDevice], {}),
        )

    def _discover_devices_for_broadcast_address(
        self, broadcast_address: str
    ) -> dict[str, SmartDevice]:
        # discover() has its own timeout of 5 seconds so I don't need to set a timeout
        return self._block_until_complete(
            Discover.discover(  # pyright: ignore [reportUnknownMemberType]
                target=broadcast_address
            ),
            timeout=None,
        )

    def _get_broadcast_addresses(self) -> set[str]:
        return {
            address.broadcast
            for addresses in psutil.net_if_addrs().values()
            for address in addresses
            if address.broadcast is not None
        }

    def _add_plug_address_to_cache(self, ip_address: str) -> None:
        SmartPlugController._cache[self._plug_alias] = ip_address

    T = TypeVar("T")

    def _block_until_complete(
        self, awaitable: Awaitable[T], timeout: int | None = 1
    ) -> T:
        return asyncio.get_event_loop().run_until_complete(
            asyncio.wait_for(awaitable, timeout=timeout)
        )


if __name__ == "__main__":
    try:
        plug_controller = SmartPlugController(plug_alias="plug")
    except Exception as exception:
        sys.exit(2)

    if len(sys.argv) == 1:
        sys.exit(0 if plug_controller.is_on() else 1)
    elif sys.argv[1] == "on":
        plug_controller.turn_on()
    elif sys.argv[1] == "off":
        plug_controller.turn_off()
