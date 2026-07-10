import { Github } from "lucide-react";
import { motion } from "motion/react";
import { assets, links } from "../content";

export function Header() {
  return (
    <motion.header 
      initial={{ y: -20, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.6 }}
      className="fixed top-0 left-0 right-0 z-50 px-6 py-4 mx-auto max-w-7xl"
    >
      <div className="flex items-center justify-between backdrop-blur-xl bg-brand-bg/70 border border-white/10 rounded-3xl px-6 py-3 shadow-[0_4px_30px_rgba(0,0,0,0.5)]">
        <div className="flex items-center gap-3">
          <img
            src={assets.icon}
            alt="Battery Panic Icon"
            className="w-8 h-8 rounded-[10px] border border-white/10 shadow-[0_0_10px_rgba(255,64,80,0.15)]"
          />
          <span className="font-display font-bold text-lg tracking-tight text-white">
            Battery Panic
          </span>
        </div>
        
        <nav className="hidden lg:flex items-center gap-6 absolute left-1/2 -translate-x-1/2">
          <a href={links.features} className="text-sm font-medium text-white/60 hover:text-white transition-colors">
            Features
          </a>
          <a href={links.downloadPage} className="text-sm font-medium text-white/60 hover:text-white transition-colors">
            Download
          </a>
          <a href={links.updatesPage} className="text-sm font-medium text-white/60 hover:text-white transition-colors">
            Updates
          </a>
          <a href={links.install} className="text-sm font-medium text-white/60 hover:text-white transition-colors">
            Install
          </a>
          <a href={links.privacy} className="text-sm font-medium text-white/60 hover:text-white transition-colors">
            Privacy
          </a>
          <a href={links.faq} className="text-sm font-medium text-white/60 hover:text-white transition-colors">
            FAQ
          </a>
        </nav>

        <div className="flex items-center gap-3">
          <span className="hidden md:inline-flex rounded-full border border-brand-green/25 bg-brand-green/10 px-3 py-1 text-xs font-bold uppercase tracking-[0.14em] text-brand-green">
            Free
          </span>
          <a
            href={links.directDmg}
            className="hidden sm:inline-flex items-center rounded-full bg-brand-red px-4 py-2 text-sm font-semibold text-white shadow-[0_0_24px_rgba(255,64,80,0.24)] transition-all hover:-translate-y-0.5 hover:bg-brand-red-dark"
          >
            Download
          </a>
          <a
            href={links.github}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 text-sm font-medium bg-white/5 border border-white/10 hover:bg-white/10 px-4 py-2 rounded-full transition-all text-white"
          >
            <Github className="w-4 h-4" />
            <span className="hidden sm:inline">GitHub</span>
          </a>
        </div>
      </div>
    </motion.header>
  );
}
