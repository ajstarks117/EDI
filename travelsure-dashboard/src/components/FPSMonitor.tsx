import { useEffect, useState } from 'react';

export default function FPSMonitor() {
  const [fps, setFps] = useState(0);
  const [memory, setMemory] = useState<number | null>(null);

  useEffect(() => {
    let frameCount = 0;
    let lastTime = performance.now();
    let animationFrameId: number;

    const loop = () => {
      const now = performance.now();
      frameCount++;

      if (now - lastTime >= 1000) {
        setFps(Math.round((frameCount * 1000) / (now - lastTime)));
        frameCount = 0;
        lastTime = now;

        // @ts-ignore - performance.memory is non-standard but useful where supported
        if (performance.memory) {
          // @ts-ignore
          setMemory(Math.round(performance.memory.usedJSHeapSize / 1048576));
        }
      }

      animationFrameId = requestAnimationFrame(loop);
    };

    animationFrameId = requestAnimationFrame(loop);

    return () => {
      cancelAnimationFrame(animationFrameId);
    };
  }, []);

  return (
    <div className="fixed bottom-4 right-4 z-[9999] bg-black/80 backdrop-blur text-white p-2 rounded text-xs font-mono border border-surface-border shadow-lg flex flex-col pointer-events-none">
      <div className="flex justify-between space-x-4">
        <span className="text-slate-400">FPS</span>
        <span className={fps < 30 ? 'text-rose-400 font-bold' : fps < 50 ? 'text-amber-400' : 'text-emerald-400'}>
          {fps}
        </span>
      </div>
      {memory !== null && (
        <div className="flex justify-between space-x-4 mt-1">
          <span className="text-slate-400">MEM</span>
          <span>{memory} MB</span>
        </div>
      )}
    </div>
  );
}
