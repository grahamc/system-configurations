module.exports = {
  // This setting is required, though it won't ever be used since my URL matcher matches all URLs.
  defaultBrowser: "Safari",
  options: {
    hideIcon: true,
    checkForUpdate: true,
  },
  handlers: [
    {
      // Match all URLs
      match: (_) => true,
      // Opens the first running browser in the list. If none are running, the first one will be started.
      browser: ["Firefox Developer Edition", "Firefox"],
    },
  ],
};
