export const links = {
  home: `${import.meta.env.BASE_URL}`,
  features: `${import.meta.env.BASE_URL}#features`,
  install: `${import.meta.env.BASE_URL}#install`,
  privacy: `${import.meta.env.BASE_URL}#privacy`,
  faq: `${import.meta.env.BASE_URL}#faq`,
  downloadPage: `${import.meta.env.BASE_URL}download/`,
  updatesPage: `${import.meta.env.BASE_URL}updates/`,
  releaseNotes: `${import.meta.env.BASE_URL}release-notes/0.5.15/`,
  github: "https://github.com/LeonTOfficial/BatteryPanic",
  latestRelease: "https://github.com/LeonTOfficial/BatteryPanic/releases/latest",
  directDmg: "https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.5.15/Battery.Panic.0.5.15.dmg",
  privacySettings: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension",
};

export const assets = {
  icon: "https://raw.githubusercontent.com/LeonTOfficial/BatteryPanic/main/docs/assets/battery-panic-icon.png",
  overlay: "https://raw.githubusercontent.com/LeonTOfficial/BatteryPanic/main/docs/screenshots/overlay-preview.png",
  settings: "https://raw.githubusercontent.com/LeonTOfficial/BatteryPanic/main/docs/screenshots/settings-preview.jpg",
  statusBar: "https://raw.githubusercontent.com/LeonTOfficial/BatteryPanic/main/docs/screenshots/status-bar-preview.png",
  privacySecurity: "https://raw.githubusercontent.com/LeonTOfficial/BatteryPanic/main/docs/screenshots/macos-privacy-security-open-anyway.jpg",
};

export function getCurrentPage(pathname = window.location.pathname) {
  const normalized = pathname.toLowerCase();
  if (normalized.endsWith("/download/") || normalized.endsWith("/download")) {
    return "download";
  }
  if (
    normalized.endsWith("/updates/") ||
    normalized.endsWith("/updates") ||
    normalized.endsWith("/release-notes/0.5.15/") ||
    normalized.endsWith("/release-notes/0.5.15")
  ) {
    return "updates";
  }
  return "home";
}
