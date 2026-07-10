import { motion } from "motion/react";
import { BellRing, Shield, Settings2, Zap } from "lucide-react";
import { assets } from "../content";

export function Features() {
  return (
    <section id="features" className="py-32 px-6 relative z-10">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-32">
          <motion.h2 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="font-display font-bold text-4xl md:text-6xl tracking-tight text-white mb-6"
          >
            Everything you need. <br className="hidden md:block" />
            <span className="text-white/40">Nothing you don't.</span>
          </motion.h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-white/60 text-xl max-w-2xl mx-auto font-light"
          >
            Designed to be lightweight, native, and direct when your Mac needs power.
          </motion.p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-[1.15fr_0.85fr] gap-14 lg:gap-20 items-center mb-32">
          <motion.div 
            initial={{ opacity: 0, x: -40 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            className="order-2 lg:order-1 relative rounded-3xl border border-white/10 bg-white/[0.02] p-1.5 overflow-hidden shadow-2xl shadow-black/50 lg:scale-[1.04]"
          >
            <img 
              src={assets.settings} 
              alt="Battery Panic Settings" 
              className="w-full h-auto rounded-[1.35rem]"
            />
            <div className="absolute inset-0 bg-gradient-to-tr from-brand-red/5 to-transparent pointer-events-none rounded-3xl" />
          </motion.div>
          
          <div className="order-1 lg:order-2 space-y-12">
            <motion.div
              initial={{ opacity: 0, x: 40 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.8, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
            >
              <div className="w-14 h-14 rounded-2xl bg-white/5 flex items-center justify-center mb-6 border border-white/10 text-white shadow-inner">
                <Settings2 className="w-7 h-7" />
              </div>
              <h3 className="font-display font-bold text-3xl text-white mb-4">Fully Customizable</h3>
              <p className="text-white/60 text-lg leading-relaxed font-light">
                Set exact low-battery and charging reminder thresholds. Adjust pulse speed, pulse intensity, warning sounds, launch at login, and temporary alarm pauses.
              </p>
            </motion.div>
            
            <motion.div
              initial={{ opacity: 0, x: 40 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.8, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
            >
              <div className="w-14 h-14 rounded-2xl bg-brand-teal/10 flex items-center justify-center mb-6 border border-brand-teal/20 text-brand-teal shadow-inner">
                <Shield className="w-7 h-7" />
              </div>
              <h3 className="font-display font-bold text-3xl text-white mb-4">100% Offline & Private</h3>
              <p className="text-white/60 text-lg leading-relaxed font-light">
                Battery Panic runs locally on your Mac. No tracking, no analytics, no accounts, and no network access is needed for the battery warning itself.
              </p>
            </motion.div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-[0.85fr_1.15fr] gap-14 lg:gap-20 items-center">
          <div className="space-y-12">
            <motion.div
              initial={{ opacity: 0, x: -40 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.8, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
            >
              <div className="w-14 h-14 rounded-2xl bg-orange-500/10 flex items-center justify-center mb-6 border border-orange-500/20 text-orange-400 shadow-inner">
                <Zap className="w-7 h-7" />
              </div>
              <h3 className="font-display font-bold text-3xl text-white mb-4">Modern Menu Bar Status</h3>
              <p className="text-white/60 text-lg leading-relaxed font-light">
                Built natively in Swift for macOS. The menu bar icon shows battery percentage and charging state without opening a full window.
              </p>
            </motion.div>
            
            <motion.div
              initial={{ opacity: 0, x: -40 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.8, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
            >
              <div className="w-14 h-14 rounded-2xl bg-brand-red/10 flex items-center justify-center mb-6 border border-brand-red/20 text-brand-red shadow-inner">
                <BellRing className="w-7 h-7" />
              </div>
              <h3 className="font-display font-bold text-3xl text-white mb-4">Unignorable Alerts</h3>
              <p className="text-white/60 text-lg leading-relaxed font-light">
                When panic mode hits, standard notifications are easy to miss. Battery Panic uses a visible overlay, critical wording at <span className="text-brand-red font-medium">2%</span>, and optional sound alerts.
              </p>
            </motion.div>
          </div>

          <motion.div 
            initial={{ opacity: 0, x: 40 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            className="relative rounded-3xl border border-white/10 bg-white/[0.02] p-5 md:p-8 flex items-center justify-center min-h-[480px] overflow-hidden shadow-2xl shadow-black/50 lg:scale-[1.04]"
          >
            <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(255,255,255,0.03),transparent_70%)]" />
            <img 
              src={assets.statusBar} 
              alt="Status Bar Preview" 
              className="w-full max-w-[760px] h-auto rounded-2xl shadow-[0_22px_60px_rgba(0,0,0,0.55)] border border-white/20 relative z-10"
            />
          </motion.div>
        </div>

      </div>
    </section>
  );
}
