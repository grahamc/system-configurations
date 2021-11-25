import os, atexit, asyncio, sys, socket, time, signal

import dbus
from dbus.mainloop import glib
from gi.repository import GLib
from kasa import Discover

class SystemdInhibitor(object):
    def __init__(self,
                 what,
                 who,
                 why,
                 mode,
                 pre_sleep_handler=None,
                 post_sleep_handler=None,
                 pre_shutdown_handler=None):
        # Doing this as early as possible since the main loop provider must be set before
        # any communication over the bus occurs e.g. registering signal handlers, getting a bus object
        self._set_default_main_loop_provider()

        self._inhibitor_lock = None
        self.what = what
        self._who = who
        self._why = why
        self._mode = mode
        self._login1_manager = self._get_login1_manager()
        # This main loop set here must match the main loop provider that dbus is configured to use.
        # The dbus main loop provider is set in _set_default_main_loop_provider
        self._main_loop = GLib.MainLoop()

        self._register_sleep_signal_handler(pre_sleep_handler=pre_sleep_handler,
                                            post_sleep_handler=post_sleep_handler)
        self._register_shutdown_signal_handler(pre_shutdown_handler)
        self._acquire_inhibitor_lock()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, exc_tb):
        self.close()

    def run(self):
        self._main_loop.run()

    def close(self):
        self._release_inhibitor_lock()
        self._main_loop.quit()

    def _set_default_main_loop_provider(self):
        # The dbus package currently only supports the GLib main loop
        dbus.set_default_main_loop(glib.DBusGMainLoop())

    def _register_sleep_signal_handler(self, pre_sleep_handler, post_sleep_handler):
        def handler(is_pre_sleep):
            if is_pre_sleep:
                if pre_sleep_handler is not None:
                    pre_sleep_handler()
                self._release_inhibitor_lock()
            else: # post sleep
                if post_sleep_handler is not None:
                    post_sleep_handler()
                self._acquire_inhibitor_lock()

        self._login1_manager.connect_to_signal('PrepareForSleep', handler)

    def _register_shutdown_signal_handler(self, pre_shutdown_handler):
        # is_pre_shutdown is always true since false would signify that the system is 'post shutdown'
        # and there is no signal emitted for 'post shutdown'
        def handler(is_pre_shutdown):
            if pre_shutdown_handler is not None:
                pre_shutdown_handler()
            self._release_inhibitor_lock()

        self._login1_manager.connect_to_signal('PrepareForShutdown', handler)

    def _acquire_inhibitor_lock(self):
        self._inhibitor_lock = self._login1_manager.Inhibit(self.what, self._who, self._why, self._mode)

    def _release_inhibitor_lock(self):
        if self._inhibitor_lock is not None:
            inhibitor_lock_file_descriptor = self._inhibitor_lock.take()
            os.close(inhibitor_lock_file_descriptor)
            self._inhibitor_lock = None

    def _get_login1_manager(self):
        login1_proxy = dbus.SystemBus().get_object(bus_name='org.freedesktop.login1',
                                                   object_path='/org/freedesktop/login1')

        return dbus.Interface(login1_proxy, 'org.freedesktop.login1.Manager')
