import { motion } from "motion/react";
import { Download, FolderInput, ShieldCheck } from "lucide-react";
import { links } from "../content";

const steps = [
  {
    icon: Download,
    title: "Mount the DMG",
    description: "Download the latest Battery Panic DMG and double-click it to open the installer window.",
  },
  {
    icon: FolderInput,
    title: "Drag to Applications",
    description: "Move Battery Panic into your Applications folder. That is the complete install.",
  },
  {
    icon: ShieldCheck,
    title: "Approve first launch",
    description: "If macOS blocks the first open, approve Battery Panic once in Privacy & Security.",
  },
];

export function InstallGuide() {
  return (
    <section id="install" className="relative z-10 px-6 py-28">
      <div className="mx-auto max-w-7xl">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-120px" }}
          transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          className="mb-16 text-center"
        >
          <p className="mb-4 text-sm font-bold uppercase tracking-[0.28em] text-brand-red">
            Install
          </p>
          <h2 className="font-display text-4xl font-bold tracking-tight text-white md:text-6xl">
            Up and running in 60 seconds.
          </h2>
          <p className="mx-auto mt-6 max-w-2xl text-lg font-light leading-relaxed text-white/55">
            Battery Panic installs like a normal Mac app: open the DMG, drag it to Applications,
            then allow the first launch if macOS asks.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
          {steps.map((step, index) => (
            <motion.article
              key={step.title}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.65, delay: index * 0.12, ease: [0.16, 1, 0.3, 1] }}
              className="group relative min-h-[245px] overflow-hidden rounded-[1.6rem] border border-white/10 bg-white/[0.035] p-8 shadow-2xl shadow-black/30 transition-all duration-500 hover:-translate-y-1 hover:border-brand-red/35 hover:bg-white/[0.055]"
            >
              <div className="absolute right-8 top-6 font-display text-6xl font-bold text-white/[0.035]">
                {index + 1}
              </div>
              <div className="mb-7 flex h-12 w-12 items-center justify-center rounded-2xl border border-brand-red/35 bg-brand-red/10 text-brand-red shadow-[0_0_30px_rgba(255,64,80,0.12)]">
                <step.icon className="h-6 w-6" />
              </div>
              <h3 className="mb-4 font-display text-2xl font-bold text-white">{step.title}</h3>
              <p className="max-w-[19rem] text-base leading-relaxed text-white/55">{step.description}</p>
            </motion.article>
          ))}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="mt-12 flex flex-col items-center justify-center gap-4 sm:flex-row"
        >
          <a
            href={links.directDmg}
            className="inline-flex items-center justify-center gap-3 rounded-full bg-brand-red px-8 py-4 font-semibold text-white shadow-[0_0_45px_rgba(255,64,80,0.32)] transition-all hover:-translate-y-0.5 hover:bg-brand-red-dark"
          >
            <Download className="h-5 w-5" />
            Download the DMG
          </a>
          <a
            href="#first-launch"
            className="inline-flex items-center justify-center rounded-full border border-white/10 bg-white/[0.04] px-8 py-4 font-semibold text-white/80 transition-all hover:bg-white/[0.08] hover:text-white"
          >
            First launch help
          </a>
        </motion.div>
      </div>
    </section>
  );
}
