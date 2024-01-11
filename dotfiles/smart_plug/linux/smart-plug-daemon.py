import atexit
import signal
import socket
import sys
import time
from collections.abc import Callable

sys.path.append("..")

import dbus
from dbus.mainloop import glib
from gi.repository import GLib
from smart_plug import SmartPlugController


class SleepWakeShutdownListener(object):
    def __init__(
        self,
        sleep_handler: Callable = None,
        wake_handler: Callable = None,
        shutdown_handler: Callable = None,
    ):
        # Doing this as early as possible since the main loop provider must be set
        # before any communication over the bus occurs e.g. registering signal handlers,
        # getting a bus object
        self._set_default_main_loop_provider()

        self._login1_manager = self._get_login1_manager()
        # This main loop set here must match the main loop provider that dbus is
        # configured to use. The dbus main loop provider is set in
        # _set_default_main_loop_provider
        self._main_loop = GLib.MainLoop()

        self._register_sleep_signal_handlers(
            sleep_handler=sleep_handler, wake_handler=wake_handler
        )
        self._register_shutdown_signal_handler(shutdown_handler)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, exc_tb):
        self.stop_listening()

    def listen(self):
        self._main_loop.run()

    def stop_listening(self):
        self._main_loop.quit()

    def _set_default_main_loop_provider(self):
        # The dbus package currently only supports the GLib main loop
        dbus.set_default_main_loop(glib.DBusGMainLoop())

    def _register_sleep_signal_handlers(
        self, sleep_handler: Callable | None, wake_handler: Callable | None
    ):
        def handler(is_pre_sleep: bool):
            if is_pre_sleep:
                if sleep_handler is not None:
                    sleep_handler()
            else:  # post sleep
                if wake_handler is not None:
                    wake_handler()

        self._login1_manager.connect_to_signal("PrepareForSleep", handler)

    def _register_shutdown_signal_handler(self, shutdown_handler: Callable | None):
        # is_pre_shutdown is always true since false would signify that the system is 'post shutdown'
        # and there is no signal emitted for 'post shutdown'
        def handler(is_pre_shutdown: bool):
            if shutdown_handler is not None:
                shutdown_handler()

        self._login1_manager.connect_to_signal("PrepareForShutdown", handler)

    def _get_login1_manager(self):
        login1_proxy = dbus.SystemBus().get_object(
            bus_name="org.freedesktop.login1", object_path="/org/freedesktop/login1"
        )
        return dbus.Interface(login1_proxy, "org.freedesktop.login1.Manager")


def register_exit_handler(handler: Callable, listener: SleepWakeShutdownListener):
    atexit.register(handler)
    exit_signals = [signal.SIGTERM, signal.SIGINT]

    # the handler calls sys.exit so that the function registered via atexit get run
    def signal_handler(signal_number, stack_frame):
        # TODO: Stopping the dbus listener here because if we raise SystemExit while a dbus message
        # handler is running, dbus will swallow the exception and continue listening.
        # Ideally, I'd want dbus to not catch SystemExit and let it keep bubbling up
        # until the program exited, but there doesn't seem to be a way to configure that.
        # The code that swallows SystemExit is in 'maybe_handle_message' in 'connection.py':
        # https://gitlab.freedesktop.org/dbus/dbus-python/-/blob/master/dbus/connection.py#L222
        listener.stop_listening()
        sys.exit()

    for exit_signal in exit_signals:
        signal.signal(exit_signal, signal_handler)


def wait_for_network_online(timeout: int = 120):
    start_time = time.time()
    while True:
        current_time = time.time()
        elapsed_time = current_time - start_time
        if elapsed_time >= timeout:
            break

        if is_network_online():
            break

        time.sleep(1)


# TODO: I really only need to be connected to my local internet to control the smart plug,
# but this check depends on DNS and 'example.com'.
def is_network_online():
    try:
        host = socket.gethostbyname("www.example.com")
        port = 80
        socket_timeout = 2
        socket.create_connection((host, port), socket_timeout)
        return True
    except:
        pass

    return False


def call_after_network_is_online(callable: Callable):
    wait_for_network_online()
    callable()


if __name__ == "__main__":
    # Expecting this script to be run at startup so need to wait for an internet connection.
    wait_for_network_online()
    plug_controller = SmartPlugController(plug_alias="plug")
    plug_controller.turn_on()

    def turn_on_plug_after_network_is_online():
        return call_after_network_is_online(plug_controller.turn_on)

    with SleepWakeShutdownListener(
        sleep_handler=plug_controller.turn_off,
        wake_handler=turn_on_plug_after_network_is_online,
        shutdown_handler=plug_controller.turn_off,
    ) as listener:
        register_exit_handler(plug_controller.turn_off, listener)
        listener.listen()
