import type { LucideIcon } from 'lucide-react';

interface EmptyStateProps {
  icon: LucideIcon;
  title: string;
  description: string;
  action?: React.ReactNode;
}

export default function EmptyState({ icon: Icon, title, description, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center h-full p-8 text-center bg-surface-card/30 rounded-xl border border-surface-border/50 backdrop-blur border-dashed">
      <div className="bg-surface-bg p-4 rounded-full mb-4 ring-1 ring-surface-border">
        <Icon className="h-8 w-8 text-indigo-400 opacity-80" />
      </div>
      <h3 className="text-lg font-outfit font-semibold text-slate-200 mb-2">{title}</h3>
      <p className="text-sm text-slate-400 max-w-sm mb-6">{description}</p>
      {action && <div>{action}</div>}
    </div>
  );
}
