import { useEffect, useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import AnatomyMap from './AnatomyMap';

export type Injury = {
    id?: string;
    label: string;
    severity: number;
    wound: string;
};

export type VitalsData = {
    name?: string;
    sid?: number;
    dead?: boolean;
    status?: string;
    hr?: number;
    hrStatus?: string;
    rhythm?: string;
    bpSys?: number;
    bpDia?: number;
    bpStatus?: string;
    spo2?: number;
    spo2Status?: string;
    rr?: number;
    rrStatus?: string;
    temp?: number;
    blood?: number;
    bloodStatus?: string;
    bleeding?: string;
    bleedLevel?: number;
    consciousness?: string;
    gcs?: number;
    injuries?: Injury[];
    area?: string;
    armor?: number;
    health?: number;
    duration?: number;
};

/** Normal QRS complex */
const ECG_NSR =
    'M0 40 H18 L22 40 L26 28 L30 52 L34 18 L38 62 L42 40 H62 L66 34 L70 40 H100';

/** Weak / irregular agonal complexes (still a pulse) */
const ECG_AGONAL =
    'M0 40 H20 L26 40 L30 34 L34 48 L38 30 L42 44 L46 40 H70 L74 36 L78 40 H100';

function tone(status?: string) {
    const s = (status || '').toLowerCase();
    if (
        s.includes('deceas') ||
        s.includes('asyst') ||
        s.includes('agonal') ||
        s.includes('pea') ||
        s.includes('critical') ||
        s.includes('severe') ||
        s.includes('exsangu')
    ) {
        return 'bad';
    }
    if (
        s.includes('unstable') ||
        s.includes('moderate') ||
        s.includes('tach') ||
        s.includes('brady') ||
        s.includes('hypot') ||
        s.includes('hypox') ||
        s.includes('low') ||
        s.includes('high') ||
        s.includes('elevat') ||
        s.includes('apnea') ||
        s.includes('no pressure') ||
        s.includes('no waveform')
    ) {
        return 'warn';
    }
    return 'ok';
}

function VitalCell({
    label,
    value,
    unit,
    status,
    large,
}: {
    label: string;
    value: string | number;
    unit?: string;
    status?: string;
    large?: boolean;
}) {
    return (
        <div className={`vm-cell ${tone(status)}`}>
            <div className="vm-cell-label">{label}</div>
            <div className={`vm-cell-value ${large ? 'lg' : ''}`}>
                {value}
                {unit ? <span className="vm-unit">{unit}</span> : null}
            </div>
            {status ? <div className="vm-cell-status">{status}</div> : null}
        </div>
    );
}

export default function VitalsMonitor({ data }: { data: VitalsData }) {
    const [remain, setRemain] = useState(data.duration || 12);
    const hr = Math.max(0, Number(data.hr) || 0);
    const deceased = !!data.dead;
    const hasPulse = hr > 0;
    const flatline = !hasPulse;
    const agonal = deceased && hasPulse;

    // Sweep speed tracks real BPM (agonal is slow)
    const durationSec = hasPulse
        ? Math.max(0.55, Math.min(3.2, 60 / hr))
        : 1;

    useEffect(() => {
        setRemain(data.duration || 12);
        const id = window.setInterval(() => {
            setRemain((v) => Math.max(0, v - 1));
        }, 1000);
        return () => window.clearInterval(id);
    }, [data]);

    const injuries = Array.isArray(data.injuries) ? data.injuries : [];
    const status = data.status || (deceased ? 'DECEASED' : 'STABLE');
    const ecgCopies = useMemo(() => Array.from({ length: 8 }, (_, i) => i), []);
    const ecgPath = agonal ? ECG_AGONAL : ECG_NSR;
    const hrTone = tone(data.hrStatus) || (agonal ? 'bad' : hasPulse ? 'ok' : 'bad');

    return (
        <div className="vitals-wrapper">
            <motion.div
                className={`vitals-monitor${deceased ? ' is-dead' : ''}${hasPulse ? ' has-pulse' : ' no-pulse'}`}
                initial={{ opacity: 0, x: 28, scale: 0.98 }}
                animate={{ opacity: 1, x: 0, scale: 1 }}
                exit={{ opacity: 0, x: 28, scale: 0.98 }}
                transition={{ duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
            >
                <header className="vm-header">
                    <div className="vm-brand">
                        <span className={`vm-dot${hasPulse ? '' : ' is-off'}`} />
                        <span>Grim City · EMS</span>
                    </div>
                    <div className="vm-title">Patient Monitor</div>
                    <div className="vm-clock">LIVE · {remain}s</div>
                </header>

                <div className="vm-patient">
                    <div>
                        <div className="vm-name">{data.name || 'Unknown patient'}</div>
                        <div className="vm-meta">
                            ID {data.sid ?? '—'} · GCS {data.gcs ?? '—'} {data.consciousness || ''}
                        </div>
                    </div>
                    <div className={`vm-badge ${tone(status)}`}>{status}</div>
                </div>

                <div className="vm-ecg">
                    <div className={`vm-ecg-label${flatline ? ' flat' : agonal ? ' agonal' : ''}`}>II</div>
                    <div className={`vm-ecg-track${flatline ? ' is-flat' : agonal ? ' is-agonal' : ''}`}>
                        <svg
                            viewBox="0 0 800 80"
                            preserveAspectRatio="none"
                            className={flatline ? 'flat' : agonal ? 'agonal' : ''}
                        >
                            {flatline ? (
                                <line x1="0" y1="40" x2="800" y2="40" />
                            ) : (
                                <g
                                    className="vm-ecg-wave"
                                    style={{ animationDuration: `${durationSec}s` }}
                                >
                                    {ecgCopies.map((i) => (
                                        <path key={i} d={ecgPath} transform={`translate(${i * 100} 0)`} />
                                    ))}
                                </g>
                            )}
                        </svg>
                    </div>
                    <div className="vm-hr-block">
                        <div className="vm-cell-label">HR</div>
                        <div className={`vm-hr ${hrTone}`}>{hr}</div>
                        <div className="vm-unit">BPM</div>
                    </div>
                </div>

                <div className="vm-grid">
                    <VitalCell
                        label="NIBP"
                        value={!hasPulse && deceased ? '— / —' : `${data.bpSys ?? 0}/${data.bpDia ?? 0}`}
                        unit={!hasPulse && deceased ? '' : 'mmHg'}
                        status={data.bpStatus}
                    />
                    <VitalCell
                        label="SpO₂"
                        value={!hasPulse && deceased ? '—' : data.spo2 ?? 0}
                        unit={!hasPulse && deceased ? '' : '%'}
                        status={data.spo2Status}
                    />
                    <VitalCell
                        label="RR"
                        value={data.rr ?? 0}
                        unit="/min"
                        status={data.rrStatus}
                    />
                    <VitalCell
                        label="TEMP"
                        value={(Number(data.temp) || 0).toFixed(1)}
                        unit="°C"
                    />
                </div>

                <div className="vm-row">
                    <div className="vm-blood">
                        <div className="vm-cell-label">Blood volume</div>
                        <div className="vm-bar">
                            <div
                                className={`vm-bar-fill ${tone(data.bloodStatus)}`}
                                style={{ width: `${Math.max(0, Math.min(100, Number(data.blood) || 0))}%` }}
                            />
                        </div>
                        <div className="vm-blood-val">
                            {data.blood ?? 0}% <span>{data.bloodStatus || ''}</span>
                        </div>
                    </div>
                    <div className={`vm-bleed ${Number(data.bleedLevel) > 0 ? 'bad' : 'ok'}`}>
                        <div className="vm-cell-label">Bleeding</div>
                        <div className="vm-bleed-val">{data.bleeding || 'None'}</div>
                    </div>
                </div>

                <AnatomyMap injuries={injuries} fallbackArea={data.area} />

                <footer className="vm-footer">
                    <span>Rhythm {data.rhythm || 'NSR'}</span>
                    <span>Health {data.health ?? 0}%</span>
                    <span>Armor {data.armor ?? 0}</span>
                </footer>
            </motion.div>
        </div>
    );
}
