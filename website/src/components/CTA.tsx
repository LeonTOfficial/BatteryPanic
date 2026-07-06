import { motion } from "motion/react";
import { Download, Github } from "lucide-react";
import { assets, links } from "../content";

export function CTA() {
  return (
    <section className="py-24 px-6 relative z-10 mb-10">
      <div className="max-w-5xl mx-auto">
        <motion.div 
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          className="relative rounded-[2.5rem] bg-gradient-to-b from-white/[0.08] to-transparent border border-white/10 p-12 md:p-20 text-center overflow-hidden"
        >
          {/* Background glows */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[80%] h-1/2 bg-brand-red/20 blur-[100px] pointer-events-none" />
          
          <div className="relative z-10 flex flex-col items-center">
            <img
              src={assets.icon}
              alt="Battery Panic"
              className="w-20 h-20 rounded-2xl border border-white/10 shadow-2xl mb-8"
            />
            <h2 className="font-display font-bold text-4xl md:text-6xl text-white mb-6 tracking-tight">
              Stop letting your Mac die.
            </h2>
            <p className="text-xl text-white/60 mb-12 max-w-2xl font-light">
              Download the latest DMG, drag Battery Panic into Applications, and keep the battery warning visible in your menu bar.
            </p>
            
            <div className="flex flex-col sm:flex-row items-center gap-4">
              <a
                href={links.directDmg}
                className="flex items-center justify-center gap-2 bg-brand-red hover:bg-brand-red-dark text-white px-8 py-4 rounded-full font-medium text-lg transition-all shadow-[0_0_30px_rgba(255,64,80,0.3)] hover:-translate-y-0.5 w-full sm:w-auto"
              >
                <Download className="w-5 h-5" />
                <span>Download Battery Panic</span>
              </a>
              <a
                href={links.github}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-2 bg-white/5 hover:bg-white/10 border border-white/10 text-white px-8 py-4 rounded-full font-medium text-lg transition-all w-full sm:w-auto"
              >
                <Github className="w-5 h-5" />
                <span>Star on GitHub</span>
              </a>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
