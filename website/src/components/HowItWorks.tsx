import { motion } from "motion/react";
import { Activity, BellDot, Zap } from "lucide-react";

const steps = [
  {
    icon: Activity,
    title: "Silent Monitoring",
    description: "Runs natively in the background and checks battery state through macOS power APIs.",
  },
  {
    icon: BellDot,
    title: "Threshold Reached",
    description: "When your Mac is unplugged and drops below your chosen percentage, Battery Panic starts the warning.",
  },
  {
    icon: Zap,
    title: "Action Required",
    description: "A visible red overlay, menu bar state, and optional warning sound help you plug in before shutdown.",
  }
];

export function HowItWorks() {
  return (
    <section id="how-it-works" className="py-32 px-6 relative z-10 bg-black/20 border-y border-white/5">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-20">
          <h2 className="font-display font-bold text-4xl md:text-5xl text-white mb-6">
            How it works
          </h2>
          <p className="text-white/60 text-lg md:text-xl max-w-2xl mx-auto font-light">
            A simple loop designed to save your work before an unexpected shutdown.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
          <div className="hidden md:block absolute left-[17%] right-[17%] top-20 h-[1px] bg-gradient-to-r from-transparent via-brand-red/35 to-transparent" />
          
          {steps.map((step, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.6, delay: index * 0.2 }}
              className="relative flex flex-col items-center text-center p-8 rounded-2xl hover:bg-white/[0.02] transition-colors"
            >
              <div className="w-24 h-24 rounded-full bg-white/5 border border-white/10 flex items-center justify-center mb-8 relative z-10 shadow-xl">
                <step.icon className="w-10 h-10 text-brand-red" />
                <div className="absolute inset-0 rounded-full bg-brand-red/10 blur-xl -z-10" />
              </div>
              <h3 className="font-display font-bold text-2xl text-white mb-4">{step.title}</h3>
              <p className="text-white/60 leading-relaxed font-light">{step.description}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
