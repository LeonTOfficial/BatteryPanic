import { motion } from "motion/react";
import { RefreshCw, Sparkles, Battery, LayoutPanelTop, ShieldCheck, FileText, Radio, History } from "lucide-react";
import { links } from "../content";

const latest = [
  "Charging reminders no longer fire immediately after app launch or login",
  "Reminders now wait for a real threshold crossing in the current charging session",
  "Animated overlays clear the transparent drawing surface before every frame",
  "Normal, preview, critical, and charging text regions stay separately aligned",
  "Charging reminder copy remains crisp at both 80% and 100%",
  "Added startup-policy and pixel-level overlay rendering regression tests",
];

const releaseHistory = [
  {
    version: "0.5.15",
    title: "Session-aware reminders",
    text: "Startup-safe charging reminders and crisp, ghost-free animated overlays.",
    href: `${import.meta.env.BASE_URL}sparkle-release-notes/0.5.15/`,
    current: true,
  },
  {
    version: "0.5.14",
    title: "Clear icons and automatic updates",
    text: "Retina-safe battery states, accurate fill levels, Sparkle 2.9.4, and secure background installation.",
    href: `${import.meta.env.BASE_URL}sparkle-release-notes/0.5.14/`,
    current: false,
  },
  {
    version: "0.5.13",
    title: "Overlay alignment",
    text: "Fixes the red warning card title spacing so battery percentages no longer crowd the icon.",
    href: `${import.meta.env.BASE_URL}sparkle-release-notes/0.5.13/`,
    current: false,
  },
  {
    version: "0.5.12",
    title: "Polish release",
    text: "Menu icon polish, larger welcome tiles, Settings scroll fix, cleaner Version History, and more reliable DMG packaging.",
    href: `${import.meta.env.BASE_URL}sparkle-release-notes/0.5.12/`,
    current: false,
  },
  {
    version: "0.5.11",
    title: "Charging reminders",
    text: "Charging reminder, critical 2% mode, improved preview timing, and better update delivery.",
    href: `${import.meta.env.BASE_URL}sparkle-release-notes/0.5.11/`,
    current: false,
  },
  {
    version: "0.5.9",
    title: "Launch fixes",
    text: "Menu bar reliability, estimated remaining time, first-launch behavior, and Sparkle update groundwork.",
    href: `${import.meta.env.BASE_URL}sparkle-release-notes/0.5.9/`,
    current: false,
  },
];

export function UpdatesPage() {
  return (
    <section className="relative min-h-screen overflow-hidden px-6 pb-28 pt-40">
      <div className="absolute right-1/4 top-10 h-[520px] w-[620px] rounded-full bg-brand-teal/10 blur-[140px]" />
      <div className="absolute bottom-0 left-1/4 h-[460px] w-[720px] rounded-full bg-brand-red/12 blur-[160px]" />

      <div className="relative z-10 mx-auto max-w-6xl">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          className="text-center"
        >
          <p className="mb-4 text-sm font-bold uppercase tracking-[0.28em] text-brand-teal">
            Updates
          </p>
          <h1 className="font-display text-5xl font-bold tracking-tight text-white md:text-7xl">
            Stay current without reinstalling manually.
          </h1>
          <p className="mx-auto mt-6 max-w-3xl text-xl font-light leading-relaxed text-white/60">
            Battery Panic includes Sparkle update support. Once a supported version is installed,
            users can check for updates directly from the menu bar.
          </p>
        </motion.div>

        <div className="mt-16 grid gap-6 lg:grid-cols-[0.92fr_1.08fr]">
          <div className="grid gap-6">
            <motion.div
              initial={{ opacity: 0, x: -26 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.7 }}
              className="rounded-[2rem] border border-white/10 bg-white/[0.04] p-8 shadow-2xl shadow-black/35"
            >
              <div className="mb-6 flex h-14 w-14 items-center justify-center rounded-2xl border border-brand-teal/30 bg-brand-teal/10 text-brand-teal">
                <RefreshCw className="h-7 w-7" />
              </div>
              <h2 className="font-display text-3xl font-bold text-white">How updates appear</h2>
              <p className="mt-4 leading-relaxed text-white/60">
                Open the Battery Panic menu bar item and choose <strong className="text-white">Check for Updates...</strong>.
                If a newer release is available, Sparkle shows the update window and handles the download.
              </p>
              <a
                href={links.latestRelease}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-8 inline-flex items-center justify-center rounded-full bg-brand-red px-7 py-4 font-semibold text-white transition-all hover:-translate-y-0.5 hover:bg-brand-red-dark"
              >
                View latest GitHub release
              </a>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: -26 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.7, delay: 0.08 }}
              className="rounded-[2rem] border border-brand-teal/20 bg-brand-teal/[0.045] p-8 shadow-2xl shadow-black/25"
            >
              <div className="mb-6 flex h-12 w-12 items-center justify-center rounded-2xl border border-brand-teal/30 bg-brand-teal/10 text-brand-teal">
                <Radio className="h-6 w-6" />
              </div>
              <h2 className="font-display text-2xl font-bold text-white">What gets checked</h2>
              <p className="mt-4 leading-relaxed text-white/60">
                Update checks only read the public GitHub appcast and release notes. Battery warnings
                stay local, and no analytics or personal battery data are sent.
              </p>
              <div className="mt-6 flex items-center gap-3 rounded-2xl border border-white/10 bg-black/20 p-4">
                <FileText className="h-5 w-5 text-brand-teal" />
                <span className="text-sm font-semibold text-white/70">Release notes remain available on this page.</span>
              </div>
            </motion.div>
          </div>

          <motion.div
            initial={{ opacity: 0, x: 26 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.7, delay: 0.08 }}
            className="rounded-[2rem] border border-white/10 bg-[#12090b]/80 p-8 shadow-2xl shadow-black/35"
          >
            <div className="mb-6 flex items-center gap-3">
              <Sparkles className="h-6 w-6 text-brand-red" />
              <p className="text-sm font-bold uppercase tracking-[0.22em] text-brand-red">Latest 0.5.15</p>
            </div>
            <h2 className="font-display text-3xl font-bold text-white">What's new</h2>
            <div className="mt-6 space-y-4">
              {latest.map((item, index) => (
                <div key={index} className="flex gap-3 rounded-2xl border border-white/10 bg-black/20 p-4">
                  <span className="mt-1 h-2.5 w-2.5 shrink-0 rounded-full bg-brand-red shadow-[0_0_18px_rgba(255,64,80,0.8)]" />
                  <p className="text-white/70">{item}</p>
                </div>
              ))}
            </div>
          </motion.div>
        </div>

        <div className="mt-8 grid gap-5 md:grid-cols-3">
          {[
            { icon: Battery, title: "Session-aware reminders", text: "Charging reminders wait for an observed threshold crossing instead of firing at startup." },
            { icon: LayoutPanelTop, title: "Crisp overlays", text: "Every pulse frame redraws cleanly without duplicated or distorted text." },
            { icon: ShieldCheck, title: "Regression coverage", text: "Policy and pixel-level tests protect both startup behavior and overlay rendering." },
          ].map((item, index) => (
            <motion.article
              key={item.title}
              initial={{ opacity: 0, y: 22 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.55, delay: index * 0.08 }}
              className="rounded-[1.4rem] border border-white/10 bg-white/[0.035] p-7"
            >
              <item.icon className="mb-5 h-7 w-7 text-brand-teal" />
              <h3 className="font-display text-xl font-bold text-white">{item.title}</h3>
              <p className="mt-3 leading-relaxed text-white/55">{item.text}</p>
            </motion.article>
          ))}
        </div>

        <motion.section
          initial={{ opacity: 0, y: 28 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          className="mt-12 rounded-[2rem] border border-white/10 bg-white/[0.04] p-8 shadow-2xl shadow-black/30"
        >
          <div className="mb-7 flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
              <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-2xl border border-brand-teal/30 bg-brand-teal/10 text-brand-teal">
                <History className="h-6 w-6" />
              </div>
              <p className="text-sm font-bold uppercase tracking-[0.24em] text-brand-teal">History</p>
              <h2 className="mt-2 font-display text-3xl font-bold tracking-tight text-white md:text-4xl">
                Follow every public update.
              </h2>
            </div>
            <p className="max-w-xl text-white/55">
              Each version has its own styled notes page, so users can see what changed before installing.
            </p>
          </div>

          <div className="grid gap-5 md:grid-cols-3">
            {releaseHistory.map((release, index) => (
              <motion.a
                key={release.version}
                href={release.href}
                initial={{ opacity: 0, y: 18 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.45, delay: index * 0.06 }}
                className={`rounded-[1.4rem] border p-6 transition-all hover:-translate-y-1 hover:bg-white/[0.07] ${
                  release.current
                    ? "border-brand-red/35 bg-brand-red/[0.09]"
                    : "border-white/10 bg-black/20"
                }`}
              >
                <span className="text-xs font-bold uppercase tracking-[0.2em] text-brand-teal">
                  {release.version}
                </span>
                <h3 className="mt-3 font-display text-xl font-bold text-white">{release.title}</h3>
                <p className="mt-3 leading-relaxed text-white/58">{release.text}</p>
              </motion.a>
            ))}
          </div>
        </motion.section>
      </div>
    </section>
  );
}
