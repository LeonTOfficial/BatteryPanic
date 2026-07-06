import { motion } from "motion/react";
import { Lock, ShieldCheck, ExternalLink } from "lucide-react";
import { assets, links } from "../content";

const privacyBadges = [
  "No analytics",
  "No telemetry",
  "No tracking",
  "No accounts",
  "No API keys",
  "Works offline",
];

export function PrivacySecurity() {
  return (
    <section id="privacy" className="relative z-10 px-6 py-28">
      <div className="mx-auto max-w-7xl space-y-24">
        <motion.div
          initial={{ opacity: 0, y: 26 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-120px" }}
          transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          className="rounded-[2rem] border border-white/10 bg-gradient-to-b from-white/[0.055] to-white/[0.015] p-10 text-center shadow-2xl shadow-black/35 md:p-14"
        >
          <div className="mx-auto mb-6 flex h-14 w-14 items-center justify-center rounded-2xl border border-brand-red/30 bg-brand-red/10 text-brand-red">
            <Lock className="h-7 w-7" />
          </div>
          <h2 className="font-display text-4xl font-bold tracking-tight text-white md:text-5xl">
            Local-first, always.
          </h2>
          <p className="mx-auto mt-5 max-w-3xl text-lg font-light leading-relaxed text-white/60">
            Battery Panic reads battery status through macOS power APIs. Nothing about your
            device or usage leaves your Mac. The only optional network call is checking for updates.
          </p>
          <div className="mt-9 flex flex-wrap justify-center gap-3">
            {privacyBadges.map((badge) => (
              <span
                key={badge}
                className="rounded-full border border-brand-red/30 bg-brand-red/10 px-4 py-2 text-sm font-semibold text-brand-red shadow-[0_0_20px_rgba(255,64,80,0.08)]"
              >
                {badge}
              </span>
            ))}
          </div>
        </motion.div>

        <motion.div
          id="first-launch"
          initial={{ opacity: 0, y: 34 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-120px" }}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          className="grid items-center gap-12 rounded-[2rem] border border-white/10 bg-[#12090b]/80 p-8 shadow-2xl shadow-black/40 md:p-12 lg:grid-cols-[0.88fr_1.12fr]"
        >
          <div>
            <p className="mb-4 text-sm font-bold uppercase tracking-[0.28em] text-brand-red">
              First launch
            </p>
            <h2 className="font-display text-4xl font-bold leading-tight tracking-tight text-white md:text-5xl">
              "Cannot be opened" on first launch?
            </h2>
            <p className="mt-6 text-lg font-light leading-relaxed text-white/60">
              Battery Panic is open source and ad-hoc signed, but not yet Apple-notarized.
              macOS may block the first open. You can approve it once in Privacy & Security.
            </p>

            <ol className="mt-8 space-y-4 text-white/70">
              <li className="flex gap-3">
                <span className="font-display font-bold text-brand-red">1.</span>
                <span>Open <strong className="text-white">System Settings -&gt; Privacy & Security</strong>.</span>
              </li>
              <li className="flex gap-3">
                <span className="font-display font-bold text-brand-red">2.</span>
                <span>Scroll to the bottom until you see the Battery Panic notice.</span>
              </li>
              <li className="flex gap-3">
                <span className="font-display font-bold text-brand-red">3.</span>
                <span>Click <strong className="text-white">Open Anyway</strong>, then confirm.</span>
              </li>
            </ol>

            <div className="mt-9 flex flex-col gap-4 sm:flex-row">
              <a
                href={links.privacySettings}
                className="inline-flex items-center justify-center gap-2 rounded-full bg-brand-red px-7 py-4 font-semibold text-white transition-all hover:-translate-y-0.5 hover:bg-brand-red-dark"
              >
                <ShieldCheck className="h-5 w-5" />
                Open Privacy & Security
              </a>
              <a
                href={links.latestRelease}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 rounded-full border border-white/10 bg-white/[0.04] px-7 py-4 font-semibold text-white/80 transition-all hover:bg-white/[0.08] hover:text-white"
              >
                Latest release
                <ExternalLink className="h-4 w-4" />
              </a>
            </div>
          </div>

          <div className="relative">
            <div className="absolute inset-6 rounded-[2rem] bg-brand-red/15 blur-[60px]" />
            <img
              src={assets.privacySecurity}
              alt="macOS Privacy & Security Open Anyway instructions"
              className="relative z-10 w-full rounded-[1.6rem] border border-white/10 shadow-[0_30px_100px_rgba(0,0,0,0.55)]"
            />
          </div>
        </motion.div>
      </div>
    </section>
  );
}
