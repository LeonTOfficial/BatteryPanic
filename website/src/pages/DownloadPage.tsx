import { motion } from "motion/react";
import { Download, FolderInput, ShieldCheck, Settings, CheckCircle2 } from "lucide-react";
import { assets, links } from "../content";

const installSteps = [
  "Download the latest DMG.",
  "Open it and drag Battery Panic into Applications.",
  "Start the app from Applications.",
  "If macOS blocks the first launch, open Privacy & Security and click Open Anyway.",
];

export function DownloadPage() {
  return (
    <section className="relative min-h-screen overflow-hidden px-6 pb-28 pt-40">
      <div className="absolute left-1/2 top-0 h-[520px] w-[780px] -translate-x-1/2 rounded-full bg-brand-red/15 blur-[140px]" />
      <div className="absolute bottom-10 right-0 h-[420px] w-[520px] rounded-full bg-brand-teal/10 blur-[120px]" />

      <div className="relative z-10 mx-auto max-w-7xl">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          className="grid items-center gap-12 lg:grid-cols-[0.95fr_1.05fr]"
        >
          <div>
            <p className="mb-4 text-sm font-bold uppercase tracking-[0.28em] text-brand-red">
              Download
            </p>
            <h1 className="font-display text-5xl font-bold leading-tight tracking-tight text-white md:text-7xl">
              Get Battery Panic for macOS.
            </h1>
            <p className="mt-6 max-w-2xl text-xl font-light leading-relaxed text-white/60">
              Battery Panic is free, open source, and built as a native macOS menu bar app.
              Download the DMG, drag it into Applications, and approve the first launch if macOS asks.
            </p>

            <div className="mt-9 flex flex-col gap-4 sm:flex-row">
              <a
                href={links.directDmg}
                className="inline-flex items-center justify-center gap-3 rounded-full bg-brand-red px-8 py-4 text-lg font-semibold text-white shadow-[0_0_55px_rgba(255,64,80,0.35)] transition-all hover:-translate-y-0.5 hover:bg-brand-red-dark"
              >
                <Download className="h-5 w-5" />
                Download DMG
              </a>
              <a
                href={links.privacySettings}
                className="inline-flex items-center justify-center gap-3 rounded-full border border-white/10 bg-white/[0.05] px-8 py-4 text-lg font-semibold text-white/80 transition-all hover:bg-white/[0.09] hover:text-white"
              >
                <Settings className="h-5 w-5" />
                Privacy & Security
              </a>
            </div>

            <p className="mt-5 text-sm text-white/40">
              Latest public package: Battery Panic 0.5.13 DMG
            </p>
          </div>

          <div className="rounded-[2rem] border border-white/10 bg-white/[0.04] p-6 shadow-2xl shadow-black/40 md:p-8">
            <div className="mb-6 flex items-center gap-4">
              <img
                src={assets.icon}
                alt="Battery Panic"
                className="h-16 w-16 rounded-2xl border border-brand-red/30"
              />
              <div>
                <h2 className="font-display text-2xl font-bold text-white">Fast install</h2>
                <p className="text-white/50">No account. No setup wizard required.</p>
              </div>
            </div>

            <div className="space-y-4">
              {installSteps.map((step, index) => (
                <div key={step} className="flex gap-4 rounded-2xl border border-white/10 bg-black/20 p-4">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-brand-red/10 font-display font-bold text-brand-red">
                    {index + 1}
                  </div>
                  <p className="self-center text-white/70">{step}</p>
                </div>
              ))}
            </div>
          </div>
        </motion.div>

        <div className="mt-20 grid gap-6 md:grid-cols-3">
          {[
            { icon: FolderInput, title: "Drag-and-drop install", text: "Move the app into Applications from the DMG window." },
            { icon: ShieldCheck, title: "First-launch help", text: "Use Privacy & Security if macOS blocks the first open." },
            { icon: CheckCircle2, title: "Free and open source", text: "Battery Panic is MIT licensed and created by LeonTOfficial." },
          ].map((item, index) => (
            <motion.article
              key={item.title}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.55, delay: index * 0.08 }}
              className="rounded-[1.4rem] border border-white/10 bg-white/[0.035] p-7"
            >
              <item.icon className="mb-5 h-7 w-7 text-brand-red" />
              <h3 className="font-display text-xl font-bold text-white">{item.title}</h3>
              <p className="mt-3 leading-relaxed text-white/55">{item.text}</p>
            </motion.article>
          ))}
        </div>
      </div>
    </section>
  );
}
