import { useEffect, useRef, useState } from 'react';
import { Html5Qrcode } from 'html5-qrcode';
import { X, Upload, CheckCircle, AlertTriangle } from 'lucide-react';
import { useTouristStore } from '../store/useTouristStore';

interface QRScannerModalProps {
  touristId: string;
  onClose: () => void;
}

export default function QRScannerModal({ touristId, onClose }: QRScannerModalProps) {
  const [error, setError] = useState<string>('');
  const [status, setStatus] = useState<'scanning' | 'verifying' | 'verified' | 'tampered'>('scanning');
  const fileInputRef = useRef<HTMLInputElement>(null);
  const scannerRef = useRef<Html5Qrcode | null>(null);
  const { setIdentityVerified } = useTouristStore();

  useEffect(() => {
    scannerRef.current = new Html5Qrcode('qr-reader');

    const startScanner = async () => {
      try {
        await scannerRef.current?.start(
          { facingMode: 'environment' },
          { fps: 10, qrbox: { width: 250, height: 250 } },
          (decodedText) => handleScan(decodedText),
          () => {} // Ignore scan errors
        );
      } catch (err) {
        console.warn('Camera failed to start:', err);
        setError('Camera access denied or unavailable. Please use file upload fallback.');
      }
    };

    startScanner();

    return () => {
      if (scannerRef.current?.isScanning) {
        scannerRef.current.stop().catch(console.error);
      }
    };
  }, []);

  const handleScan = async (decodedText: string) => {
    if (status !== 'scanning') return;
    
    if (scannerRef.current?.isScanning) {
      await scannerRef.current.stop().catch(console.error);
    }
    
    setStatus('verifying');
    
    // Mock blockchain verification
    setTimeout(() => {
      if (decodedText.includes('tampered') || decodedText === 'invalid') {
        setStatus('tampered');
      } else {
        setStatus('verified');
        setIdentityVerified(touristId, true);
        setTimeout(onClose, 2000);
      }
    }, 1500);
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setStatus('scanning');
    setError('');

    try {
      const html5QrCode = new Html5Qrcode('qr-reader');
      const decodedText = await html5QrCode.scanFile(file, true);
      handleScan(decodedText);
    } catch (err) {
      setError('Could not find or decode QR code in image.');
      setStatus('scanning');
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div className="bg-surface-card border border-surface-border rounded-xl shadow-2xl w-full max-w-md overflow-hidden flex flex-col">
        <div className="flex items-center justify-between p-4 border-b border-surface-border bg-surface-bg/50">
          <h2 className="font-outfit font-semibold text-lg text-slate-200">Verify Identity</h2>
          <button onClick={onClose} className="p-1 rounded hover:bg-surface-border text-muted-text hover:text-slate-200 transition">
            <X className="h-5 w-5" />
          </button>
        </div>
        
        <div className="p-6 flex flex-col items-center space-y-4 relative">
          
          {status === 'scanning' && (
            <>
              <div id="qr-reader" className="w-full max-w-[300px] overflow-hidden rounded-lg bg-black" />
              {error && <p className="text-sm text-amber-400 text-center font-medium">{error}</p>}
              
              <div className="w-full pt-4 border-t border-surface-border flex flex-col items-center">
                <p className="text-xs text-muted-text mb-2 uppercase font-semibold">Fallback Method</p>
                <input 
                  type="file" 
                  accept="image/*" 
                  ref={fileInputRef} 
                  className="hidden" 
                  onChange={handleFileUpload} 
                />
                <button 
                  onClick={() => fileInputRef.current?.click()}
                  className="flex items-center space-x-2 px-4 py-2 bg-surface-bg hover:bg-surface-border border border-surface-border rounded-lg text-sm font-medium transition text-slate-300"
                >
                  <Upload className="h-4 w-4" />
                  <span>Upload QR Image</span>
                </button>
              </div>
            </>
          )}

          {status === 'verifying' && (
            <div className="py-12 flex flex-col items-center space-y-4">
              <div className="h-12 w-12 border-4 border-indigo-500/30 border-t-indigo-500 rounded-full animate-spin" />
              <p className="text-indigo-400 font-semibold animate-pulse">Verifying via Blockchain...</p>
            </div>
          )}

          {status === 'verified' && (
            <div className="py-10 flex flex-col items-center space-y-4 text-emerald-400">
              <CheckCircle className="h-16 w-16" />
              <p className="font-bold text-xl uppercase tracking-wider">Identity Verified</p>
            </div>
          )}

          {status === 'tampered' && (
            <div className="py-10 flex flex-col items-center space-y-4 text-rose-400">
              <AlertTriangle className="h-16 w-16" />
              <div className="text-center">
                <p className="font-bold text-xl uppercase tracking-wider">Tampered Data</p>
                <p className="text-sm text-rose-300 mt-1">Blockchain signature mismatch.</p>
              </div>
              <button 
                onClick={() => setStatus('scanning')}
                className="mt-4 px-4 py-2 bg-rose-500/10 hover:bg-rose-500/20 rounded-lg text-sm font-medium transition"
              >
                Scan Again
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
