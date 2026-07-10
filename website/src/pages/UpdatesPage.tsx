import { motion } from "motion/react";
import { RefreshCw, Sparkles, BatteryCharging, BellRing, ShieldCheck, FileText, Radio } from "lucide-react";
import { links } from "../content";

const latest = [
  "Charging reminders and stronger critical alerts",
  "Charging reminder with adjustable threshold",
  <>Critical <span className="text-brand-red font-semibold">2%</span> battery mode</>,
  "Improved sound behavior and safer preview timing",
  "Battery Panic Siren keeps warning during a real alarm",
  "Better menu bar battery percentage display",
  "Updated installer and Privacy & Security guidance",
  "Thank you to Anni3 for the charging reminder idea",
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
              <p className="text-sm font-bold uppercase tracking-[0.22em] text-brand-red">Latest 0.5.11</p>
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
            { icon: BatteryCharging, title: "Charging", text: "The app can remind you when charging reaches your chosen level." },
            { icon: BellRing, title: <>Critical <span className="text-brand-red">2%</span> alerts</>, text: <>At <span className="text-brand-red font-medium">2%</span> or below, the alert becomes more urgent.</> },
            { icon: ShieldCheck, title: "Privacy", text: "Update checks are optional; battery warnings remain local." },
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
      </div>
    </section>
  );
}
