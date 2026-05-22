import { Play, RotateCcw, ArrowRight, ArrowLeft, Radio, Check } from 'lucide-react';
import { useDemoStore } from '../store/useDemoStore';

export default function DemoOverlay() {
  const { 
    currentStep, 
    steps, 
    nextStep, 
    prevStep, 
    setStep,
    triggerSimulatedSos, 
    resetDemo, 
    toggle 
  } = useDemoStore();

  const step = steps[currentStep];

  return (
    <div className="fixed bottom-6 left-6 z-50 max-w-md w-full glass-panel border border-indigo-500/30 shadow-2xl rounded-2xl theme-transition overflow-hidden animate-in slide-in-from-bottom-5 duration-300">
      {/* Premium Gradient Header */}
      <div className="bg-gradient-to-r from-indigo-600 to-purple-600 p-4 text-white flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <Radio className="h-5 w-5 animate-pulse text-indigo-200" />
          <span className="font-outfit font-bold tracking-wide uppercase text-sm">TravelTrek Demo Guide</span>
        </div>
        <button 
          onClick={toggle}
          className="text-xs px-2.5 py-1 bg-white/10 hover:bg-white/20 rounded font-semibold transition"
          aria-label="Exit Demo Mode"
        >
          Exit Demo
        </button>
      </div>

      <div className="p-5 space-y-4">
        {/* Step Badge & Progress */}
        <div className="flex items-center justify-between">
          <span className="px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider rounded bg-indigo-500/10 border border-indigo-500/20 text-indigo-400">
            {step.badge || "Walkthrough"}
          </span>
          <span className="text-xs font-semibold text-slate-400">
            Act {currentStep + 1} of {steps.length}
          </span>
        </div>

        {/* Step Title & Description */}
        <div className="space-y-1">
          <h4 className="text-base font-bold text-slate-100">{step.title}</h4>
          <p className="text-xs text-slate-400 leading-relaxed">{step.description}</p>
        </div>

        {/* Script Specific Action Buttons */}
        {currentStep === 1 && (
          <div className="bg-indigo-500/5 border border-indigo-500/10 p-3 rounded-lg flex items-center justify-between animate-in fade-in duration-200">
            <span className="text-xs font-medium text-slate-300">Start Distress Simulation:</span>
            <button
              id="simulate-sos-btn"
              onClick={triggerSimulatedSos}
              className="flex items-center space-x-1.5 px-3 py-1.5 bg-rose-600 hover:bg-rose-700 text-white rounded text-xs font-bold transition shadow-md shadow-rose-900/20"
            >
              <Play className="h-3.5 w-3.5 fill-white" />
              <span>Trigger SOS</span>
            </button>
          </div>
        )}

        {currentStep === 2 && (
          <div className="bg-emerald-500/5 border border-emerald-500/10 p-3 rounded-lg flex items-center space-x-2 animate-in fade-in duration-200">
            <Check className="h-4 w-4 text-emerald-400 shrink-0" />
            <span className="text-xs font-medium text-emerald-300">SOS distress packets routing successfully! Mesh network hops are now visible in the incident panel.</span>
          </div>
        )}

        {/* Timeline Progress bar */}
        <div className="flex space-x-1.5 pt-1">
          {steps.map((_, idx) => (
            <button
              key={idx}
              onClick={() => setStep(idx)}
              className={`h-1.5 flex-1 rounded-full transition-all duration-300 ${idx === currentStep ? 'bg-indigo-500' : idx < currentStep ? 'bg-indigo-500/40' : 'bg-slate-700'}`}
              aria-label={`Go to step ${idx + 1}`}
            />
          ))}
        </div>

        {/* Controls / Navigation Footer */}
        <div className="flex items-center justify-between pt-2 border-t border-surface-border/40">
          <button
            onClick={resetDemo}
            className="flex items-center space-x-1 py-1.5 px-3 bg-surface-bg hover:bg-surface-border border border-surface-border rounded-lg text-slate-300 hover:text-slate-100 transition text-xs font-semibold"
          >
            <RotateCcw className="h-3.5 w-3.5" />
            <span>Reset</span>
          </button>
          
          <div className="flex space-x-2">
            <button
              onClick={prevStep}
              disabled={currentStep === 0}
              className="p-2 bg-surface-bg hover:bg-surface-border disabled:opacity-40 disabled:cursor-not-allowed border border-surface-border rounded-lg text-slate-300 transition"
              aria-label="Previous step"
            >
              <ArrowLeft className="h-4 w-4" />
            </button>
            <button
              onClick={nextStep}
              disabled={currentStep === steps.length - 1}
              className="flex items-center space-x-1 py-1.5 px-3 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 disabled:cursor-not-allowed text-white rounded-lg transition text-xs font-bold shadow-md shadow-indigo-900/10"
              aria-label="Next step"
            >
              <span>Next</span>
              <ArrowRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
