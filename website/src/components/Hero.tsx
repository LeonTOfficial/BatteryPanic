import { motion } from "motion/react";
import { Download, ShieldCheck, Cpu, RefreshCw } from "lucide-react";
import { assets, links } from "../content";

export function Hero() {
  return (
    <section className="relative pt-40 pb-32 px-6 min-h-[95vh] flex flex-col items-center justify-center overflow-hidden">
      {/* Background Gradients */}
      <div className="absolute top-1/4 left-1/4 w-[800px] h-[800px] bg-brand-red/10 rounded-full blur-[150px] -translate-x-1/2 -translate-y-1/2 pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/4 w-[600px] h-[600px] bg-brand-teal/10 rounded-full blur-[120px] translate-x-1/2 translate-y-1/2 pointer-events-none" />

      <div className="max-w-5xl mx-auto text-center z-10 flex flex-col items-center">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 text-white/80 text-sm mb-10 shadow-[0_0_30px_rgba(255,255,255,0.02)] backdrop-blur-md"
        >
          <span className="relative flex h-2.5 w-2.5">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-brand-red opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-brand-red"></span>
          </span>
          <span className="font-medium tracking-wide">Free and open source for macOS 13+</span>
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
          className="font-display font-bold text-6xl md:text-8xl tracking-tighter text-white mb-8 leading-[1.05]"
        >
          Never Ignore a <br />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-brand-red via-[#ff6b77] to-brand-orange">
            Low Battery
          </span>{" "}
          Again.
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
          className="text-lg md:text-2xl text-white/60 mb-12 max-w-3xl font-light leading-relaxed"
        >
          A native macOS menu bar app that forces you to plug in with highly visible
          pulsing red overlays, charging reminders, critical 2% mode, and customizable sound warnings.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.3, ease: [0.16, 1, 0.3, 1] }}
          className="flex flex-col sm:flex-row items-center gap-5 w-full sm:w-auto"
        >
          <a
            href={links.directDmg}
            className="group flex items-center justify-center gap-3 bg-brand-red hover:bg-brand-red-dark text-white px-10 py-5 rounded-full font-medium text-lg transition-all shadow-[0_0_40px_rgba(255,64,80,0.3)] hover:shadow-[0_0_60px_rgba(255,64,80,0.5)] hover:-translate-y-1 w-full sm:w-auto"
          >
            <Download className="w-5 h-5 group-hover:animate-bounce" />
            <span>Download for macOS</span>
          </a>
          <a
            href={links.install}
            className="flex items-center justify-center gap-3 bg-white/5 hover:bg-white/10 border border-white/10 text-white px-10 py-5 rounded-full font-medium text-lg transition-all w-full sm:w-auto hover:-translate-y-1"
          >
            <span>How to install</span>
          </a>
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1, delay: 0.6 }}
          className="mt-12 flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-white/40 text-sm font-medium"
        >
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-4 h-4" />
            <span>Privacy First</span>
          </div>
          <div className="flex items-center gap-2">
            <Cpu className="w-4 h-4" />
            <span>Native Performance</span>
          </div>
          <div className="flex items-center gap-2">
            <RefreshCw className="w-4 h-4" />
            <span>Sparkle Updates</span>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1.2, delay: 0.5, ease: [0.16, 1, 0.3, 1] }}
          className="mt-20 relative w-full max-w-4xl rounded-2xl overflow-hidden border border-white/10 shadow-[0_0_100px_rgba(0,0,0,0.8)]"
        >
          <div className="absolute inset-x-0 bottom-0 h-1/3 bg-gradient-to-t from-brand-bg/85 to-transparent z-10" />
          <img
            src={assets.overlay}
            alt="Battery Panic Overlay Preview"
            className="w-full h-auto object-cover rounded-2xl scale-[1.02] transform"
          />
        </motion.div>
      </div>
    </section>
  );
}
