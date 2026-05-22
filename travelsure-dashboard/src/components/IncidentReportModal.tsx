import { X, Printer, MapPin, ShieldCheck, User as UserIcon, Clock, Activity, FileText } from 'lucide-react';
import { type Alert } from '../store/useAlertStore';
import { useTouristStore } from '../store/useTouristStore';
import { useFocusTrap } from '../hooks/useFocusTrap';
import { format } from 'date-fns';
import { useEffect, useState } from 'react';

interface Props {
  alert: Alert;
  onClose: () => void;
}

export default function IncidentReportModal({ alert, onClose }: Props) {
  const tourist = alert.touristId ? useTouristStore.getState().positions[alert.touristId] : null;
  const trapRef = useFocusTrap(true, onClose);
  const [mapUrl, setMapUrl] = useState<string>('');

  useEffect(() => {
    // Generate static map URL
    // Security Note: In production, proxy this through the backend to protect VITE_GOOGLE_MAPS_API_KEY
    if (tourist) {
      const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;
      const lat = tourist.lat;
      const lng = tourist.lng;
      const url = `https://maps.googleapis.com/maps/api/staticmap?center=${lat},${lng}&zoom=15&size=600x300&maptype=hybrid&markers=color:red%7C${lat},${lng}&key=${apiKey}`;
      setMapUrl(url);
    }
  }, [tourist]);

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4 print:p-0 print:bg-white print:block print:relative print:inset-auto">
      <div 
        ref={trapRef}
        role="dialog"
        aria-modal="true"
        className="bg-surface-card border border-surface-border w-full max-w-4xl max-h-[90vh] overflow-y-auto rounded-xl shadow-2xl print:max-w-none print:w-full print:h-auto print:max-h-none print:shadow-none print:border-none print:rounded-none print:text-black print:bg-white"
      >
        
        {/* Modal Actions (Hidden in print) */}
        <div className="sticky top-0 z-10 flex items-center justify-between p-4 bg-surface-card border-b border-surface-border print:hidden">
          <h2 className="font-outfit font-bold text-lg flex items-center space-x-2">
            <FileText className="h-5 w-5 text-indigo-400" />
            <span>Incident Report Generator</span>
          </h2>
          <div className="flex items-center space-x-2">
            <button 
              onClick={handlePrint}
              className="flex items-center space-x-2 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded text-sm font-medium transition"
            >
              <Printer className="h-4 w-4" />
              <span>Print / Save PDF</span>
            </button>
            <button 
              onClick={onClose}
              className="p-1.5 text-muted-text hover:bg-surface-border rounded transition"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>

        {/* Printable Content Area */}
        <div className="p-8 space-y-8 print:p-0">
          
          {/* Header */}
          <div className="border-b-2 border-slate-200 dark:border-surface-border pb-6 mb-6">
            <div className="flex justify-between items-start">
              <div>
                <h1 className="text-3xl font-outfit font-bold text-slate-800 dark:text-slate-100 print:text-black">
                  TRAVELTREK INCIDENT REPORT
                </h1>
                <p className="text-sm text-slate-500 dark:text-slate-400 mt-1 print:text-gray-600">
                  Official Record of Emergency Operation
                </p>
              </div>
              <div className="text-right">
                <p className="text-sm font-bold text-slate-700 dark:text-slate-300 print:text-black">
                  REF: TS-{alert.id.split('-')[0].toUpperCase()}
                </p>
                <p className="text-sm text-slate-500 dark:text-slate-400 print:text-gray-600">
                  {format(alert.timestamp, 'yyyy-MM-dd HH:mm:ss')}
                </p>
              </div>
            </div>
          </div>

          {/* Tourist Identity Section */}
          <section className="print-avoid-break">
            <h3 className="text-sm font-bold uppercase tracking-wider text-slate-400 mb-3 print:text-gray-500">
              <UserIcon className="inline-block h-4 w-4 mr-2" />
              Subject Identity
            </h3>
            {tourist ? (
              <div className="flex items-start space-x-6 bg-slate-50 dark:bg-surface-bg p-4 rounded-lg border border-slate-200 dark:border-surface-border print:bg-white print:border-gray-300">
                <div className="h-24 w-24 rounded bg-slate-200 dark:bg-surface-border shrink-0 overflow-hidden">
                  {tourist.photo ? (
                    <img src={tourist.photo} alt={tourist.name} className="h-full w-full object-cover" />
                  ) : (
                    <UserIcon className="h-full w-full p-4 text-slate-400" />
                  )}
                </div>
                <div className="flex-1 grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-slate-500 print:text-gray-500">Full Name</p>
                    <p className="font-bold text-slate-800 dark:text-slate-100 print:text-black">{tourist.name || 'Unknown'}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500 print:text-gray-500">Nationality</p>
                    <p className="font-medium text-slate-700 dark:text-slate-200 print:text-gray-800">{tourist.nationality || 'Unknown'}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500 print:text-gray-500">System ID</p>
                    <p className="font-mono text-sm text-slate-600 dark:text-slate-400 print:text-gray-700">{tourist.id}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500 print:text-gray-500">Verification Status</p>
                    <div className="flex items-center space-x-1 mt-0.5">
                      {tourist.isIdentityVerified ? (
                        <span className="flex items-center text-emerald-600 dark:text-emerald-400 text-sm font-bold">
                          <ShieldCheck className="h-4 w-4 mr-1" /> Blockchain Verified
                        </span>
                      ) : (
                        <span className="text-amber-600 dark:text-amber-400 text-sm font-bold">Unverified</span>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <p className="text-slate-500 italic">No tourist context available for this alert.</p>
            )}
          </section>

          {/* SOS Timeline & Details */}
          <section className="print-avoid-break">
            <h3 className="text-sm font-bold uppercase tracking-wider text-slate-400 mb-3 print:text-gray-500">
              <Clock className="inline-block h-4 w-4 mr-2" />
              Incident Details
            </h3>
            <div className="bg-slate-50 dark:bg-surface-bg p-4 rounded-lg border border-slate-200 dark:border-surface-border print:bg-white print:border-gray-300">
              <div className="grid grid-cols-3 gap-4 mb-4">
                <div>
                  <p className="text-xs text-slate-500 print:text-gray-500">Priority Level</p>
                  <p className="font-bold text-rose-600 dark:text-rose-400 print:text-red-700">{alert.priority} SOS</p>
                </div>
                <div>
                  <p className="text-xs text-slate-500 print:text-gray-500">Alert Trigger Time</p>
                  <p className="font-medium text-slate-700 dark:text-slate-200 print:text-black">
                    {format(alert.timestamp, 'HH:mm:ss')} (Local)
                  </p>
                </div>
                <div>
                  <p className="text-xs text-slate-500 print:text-gray-500">Final Status</p>
                  <p className="font-bold text-slate-800 dark:text-slate-100 uppercase print:text-black">{alert.status}</p>
                </div>
              </div>
              <div className="pt-4 border-t border-slate-200 dark:border-surface-border print:border-gray-300">
                <p className="text-xs text-slate-500 print:text-gray-500">Original Alert Message</p>
                <p className="text-slate-800 dark:text-slate-100 font-medium mt-1 print:text-black">{alert.message}</p>
              </div>
            </div>
          </section>

          {/* Location Snapshot */}
          {tourist && mapUrl && (
            <section className="print-avoid-break">
              <h3 className="text-sm font-bold uppercase tracking-wider text-slate-400 mb-3 print:text-gray-500">
                <MapPin className="inline-block h-4 w-4 mr-2" />
                Location Snapshot
              </h3>
              <div className="bg-slate-50 dark:bg-surface-bg p-4 rounded-lg border border-slate-200 dark:border-surface-border print:bg-white print:border-gray-300">
                <div className="flex justify-between items-center mb-3">
                  <p className="text-sm font-mono text-slate-600 dark:text-slate-300 print:text-gray-700">
                    LAT: {tourist.lat.toFixed(6)} | LNG: {tourist.lng.toFixed(6)}
                  </p>
                  <p className="text-xs text-slate-500 print:text-gray-500">Generated via Google Maps API</p>
                </div>
                <div className="w-full h-[300px] bg-slate-200 dark:bg-surface-border rounded overflow-hidden border border-slate-300 dark:border-surface-border print:border-gray-300">
                  <img src={mapUrl} alt="Static Map Snapshot" className="w-full h-full object-cover" />
                </div>
              </div>
            </section>
          )}

          {/* Resolution & Notes */}
          <section className="print-avoid-break">
            <h3 className="text-sm font-bold uppercase tracking-wider text-slate-400 mb-3 print:text-gray-500">
              <Activity className="inline-block h-4 w-4 mr-2" />
              Resolution Notes
            </h3>
            <div className="bg-slate-50 dark:bg-surface-bg p-4 rounded-lg border border-slate-200 dark:border-surface-border min-h-[100px] print:bg-white print:border-gray-300">
              {alert.resolutionNotes ? (
                <p className="text-slate-800 dark:text-slate-200 whitespace-pre-wrap print:text-black">
                  {alert.resolutionNotes}
                </p>
              ) : (
                <p className="text-slate-400 italic print:text-gray-500">No official resolution notes were recorded for this incident.</p>
              )}
            </div>
          </section>

          {/* Footer Signatures */}
          <div className="pt-16 mt-8 border-t border-slate-200 dark:border-surface-border print:border-gray-300 grid grid-cols-2 gap-8 print-avoid-break">
            <div>
              <div className="border-b border-slate-400 dark:border-slate-500 print:border-gray-500 mb-2"></div>
              <p className="text-xs text-slate-500 text-center uppercase tracking-wide print:text-gray-500">Responder Signature</p>
            </div>
            <div>
              <div className="border-b border-slate-400 dark:border-slate-500 print:border-gray-500 mb-2"></div>
              <p className="text-xs text-slate-500 text-center uppercase tracking-wide print:text-gray-500">Authority Approval</p>
            </div>
          </div>
          
        </div>
      </div>
    </div>
  );
}
