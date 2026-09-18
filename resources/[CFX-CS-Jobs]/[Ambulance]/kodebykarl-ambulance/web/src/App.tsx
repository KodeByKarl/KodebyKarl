import { useEffect, useMemo, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { onNuiEvent } from './utils/onNui';
import { sendNuiEvent } from './utils/sendNui';
import VitalsMonitor, { type VitalsData } from './VitalsMonitor';

import './index.css';

type RespawnPoint = {
    id: string;
    label: string;
    area: string;
    cost: number;
};

type DeathUiMode = 'full' | 'short';

function formatTime(seconds: number) {
    const mins = Math.floor(Math.max(0, seconds) / 60);
    const secs = Math.max(0, seconds) % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

function App() {
    const [isDead, setIsDead] = useState(false);
    const [timer, setTimer] = useState(300);
    const [totalTime, setTotalTime] = useState(300);
    const [isBleedout, setIsBleedout] = useState(false);
    const [dispatched, setDispatched] = useState(false);
    const [freecam, setFreecam] = useState(false);
    const [vitals, setVitals] = useState<VitalsData | null>(null);
    const [mode, setMode] = useState<DeathUiMode>('full');
    const [locations, setLocations] = useState<RespawnPoint[]>([]);
    const [selectedId, setSelectedId] = useState<string | null>(null);
    const [bpm, setBpm] = useState(37);

    const progress = useMemo(() => {
        if (totalTime <= 0) return 1;
        return Math.min(1, Math.max(0, 1 - timer / totalTime));
    }, [timer, totalTime]);

    const canRespawn = timer <= 0 || isBleedout;
    const selected = locations.find((l) => l.id === selectedId) || null;

    useEffect(() => {
        onNuiEvent('ShowUI', (data) => {
            setIsDead(true);
            setIsBleedout(!!data?.bleedout);
            setDispatched(false);
            setFreecam(false);
            const startMode: DeathUiMode = data?.mode === 'short' ? 'short' : 'full';
            setMode(startMode);
            const t = typeof data?.time === 'number' ? data.time : 300;
            setTimer(t);
            setTotalTime(typeof data?.totalTime === 'number' ? data.totalTime : t);
            const locs = Array.isArray(data?.locations) ? (data.locations as RespawnPoint[]) : [];
            setLocations(locs);
            const preferred = typeof data?.selectedId === 'string' ? data.selectedId : null;
            setSelectedId(preferred && locs.some((l) => l.id === preferred) ? preferred : (locs[0]?.id ?? null));
            setBpm(32 + Math.floor(Math.random() * 12));
            // Client owns NUI focus — don't re-request focus from React (focus races can crash CEF).
        });

        onNuiEvent('HideUI', () => {
            setIsDead(false);
            setFreecam(false);
            setMode('full');
            setSelectedId(null);
        });

        onNuiEvent('updateDeathScreen', (data) => {
            if (data.update === 'text') {
                setIsBleedout(!!data.bleedout);
            }
            if (data.update === 'time' && data.time >= 0) {
                setTimer(data.time);
            }
            if (data.update === 'dispatch') {
                setDispatched(!!data.dispatched);
            }
            if (data.update === 'freecam') {
                setFreecam(!!data.freecam);
            }
            if (data.update === 'mode' && (data.mode === 'full' || data.mode === 'short')) {
                setMode(data.mode);
            }
            if (data.update === 'bpm' && typeof data.bpm === 'number') {
                setBpm(data.bpm);
            }
        });

        onNuiEvent('ShowVitals', (data) => {
            setVitals(data as VitalsData);
        });

        onNuiEvent('HideVitals', () => {
            setVitals(null);
        });
    }, []);

    useEffect(() => {
        if (!isDead || mode !== 'full' || isBleedout) return;
        const id = window.setInterval(() => {
            setBpm((prev) => Math.max(28, Math.min(48, prev + (Math.random() > 0.5 ? 1 : -1))));
        }, 1800);
        return () => window.clearInterval(id);
    }, [isDead, mode, isBleedout]);

    const minimize = () => {
        setMode('short');
        void sendNuiEvent('ems:setDeathUiMode', { mode: 'short' });
    };

    const expand = () => {
        setMode('full');
        void sendNuiEvent('ems:setDeathUiMode', { mode: 'full' });
    };

    const selectLocation = (id: string) => {
        setSelectedId(id);
        void sendNuiEvent('ems:selectRespawn', { id });
    };

    const sendDistress = () => {
        if (dispatched) return;
        void sendNuiEvent('ems:sendDistress', {});
    };

    const confirmRespawn = () => {
        if (!canRespawn || !selectedId) return;
        void sendNuiEvent('ems:confirmRespawn', { id: selectedId });
    };

    return (
        <>
            <AnimatePresence>
                {isDead && mode === 'full' && (
                    <div className="grim-ems-wrap">
                        <motion.div
                            className="grim-ems-panel"
                            initial={{ opacity: 0, y: 16, scale: 0.98 }}
                            animate={{ opacity: 1, y: 0, scale: 1 }}
                            exit={{ opacity: 0, y: 10, scale: 0.98 }}
                            transition={{ duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
                        >
                            <div className="grim-ems-top">
                                <div className="grim-ems-brand">
                                    <span className="grim-ems-accent" />
                                    <div className="grim-ems-logo">
                                        <img src="./logo.png" alt="" />
                                    </div>
                                    <div>
                                        <p className="grim-ems-kicker">Grim City · EMS</p>
                                        <h1>{isBleedout ? 'Bleedout' : 'Downed'}</h1>
                                    </div>
                                </div>

                                <div className="grim-ems-pulse">
                                    <strong>{isBleedout ? '0' : bpm}</strong>
                                    <span>{isBleedout ? 'NO PULSE' : 'BPM'}</span>
                                </div>

                                <button type="button" className="grim-ems-min" onClick={minimize} title="Compress">
                                    ▬
                                </button>
                            </div>

                            <div className="grim-ems-timer-row">
                                <div>
                                    <p className="grim-ems-label">
                                        {canRespawn ? 'Respawn Ready' : 'Respawn In'}
                                    </p>
                                    <div className="grim-ems-clock">{formatTime(timer)}</div>
                                </div>
                                <p className="grim-ems-hint">
                                    {canRespawn ? 'Pick a hospital & confirm' : 'Choose a hospital — EMS can still revive you'}
                                </p>
                            </div>

                            <div className="grim-ems-bar">
                                <div className="grim-ems-bar-fill" style={{ width: `${progress * 100}%` }} />
                            </div>

                            <p className="grim-ems-label grim-ems-loc-label">Respawn Point</p>
                            <div className="grim-ems-grid">
                                {locations.map((loc) => {
                                    const active = loc.id === selectedId;
                                    return (
                                        <button
                                            key={loc.id}
                                            type="button"
                                            className={`grim-ems-card${active ? ' is-on' : ''}`}
                                            onClick={() => selectLocation(loc.id)}
                                        >
                                            <span className={`grim-ems-radio${active ? ' is-on' : ''}`} />
                                            <strong>{loc.label}</strong>
                                            <em>{loc.area}</em>
                                            <span className="grim-ems-cost">${loc.cost.toLocaleString()}</span>
                                        </button>
                                    );
                                })}
                            </div>

                            <div className="grim-ems-actions">
                                <button
                                    type="button"
                                    className={`grim-ems-confirm${canRespawn && selected ? '' : ' is-off'}`}
                                    disabled={!canRespawn || !selected}
                                    onClick={confirmRespawn}
                                >
                                    {canRespawn
                                        ? selected
                                            ? `Respawn · ${selected.label}`
                                            : 'Select point'
                                        : 'Waiting for EMS window…'}
                                </button>
                                <button
                                    type="button"
                                    className={`grim-ems-distress${dispatched ? ' is-sent' : ''}`}
                                    onClick={sendDistress}
                                    disabled={dispatched}
                                >
                                    {dispatched ? 'Sent' : 'Distress'}
                                </button>
                            </div>

                            <p className="grim-ems-foot">
                                {dispatched
                                    ? 'Distress active — EMS notified'
                                    : 'EMS notified automatically while down'}
                            </p>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            <AnimatePresence>
                {isDead && mode === 'short' && (
                    <div className="death-screen-wrapper">
                        <motion.div
                            className="death-bar-container"
                            initial={{ opacity: 0, y: 25 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: 25 }}
                            transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
                        >
                            <div className="accent-line" />

                            <div className="logo-badge">
                                <img src="./logo.png" alt="Grim City" className="logo-img" />
                            </div>

                            <div className="title-group">
                                <span className="subtitle">{isBleedout ? 'BLEEDOUT' : 'DEATH CAM'}</span>
                                <h1 className="main-title">{isBleedout ? 'Critical Condition' : 'Incapacitated'}</h1>
                            </div>

                            <div className="timer-badge">
                                <svg className="clock-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                                    <circle cx="12" cy="12" r="10" />
                                    <polyline points="12 6 12 12 16 14" />
                                </svg>
                                <span className="timer-text">{formatTime(timer)}</span>
                            </div>

                            <div className={`action-pill ${freecam ? 'is-active' : ''}`}>
                                <div className="key-box">G</div>
                                <div className="label-box">{freecam ? 'Exit Freecam' : 'Freecam'}</div>
                            </div>
                            <button type="button" className="action-pill action-pill-btn" onClick={expand}>
                                <div className="key-box">H</div>
                                <div className="label-box">EMS Panel</div>
                            </button>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            <AnimatePresence>
                {vitals && <VitalsMonitor key="vitals-monitor" data={vitals} />}
            </AnimatePresence>
        </>
    );
}

export default App;
