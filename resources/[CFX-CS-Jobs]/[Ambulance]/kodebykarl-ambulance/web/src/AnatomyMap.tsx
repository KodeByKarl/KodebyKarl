import { useMemo, useState } from 'react';
import type { Injury } from './VitalsMonitor';

export type BodyPartId =
    | 'HEAD'
    | 'NECK'
    | 'SPINE'
    | 'UPPER_BODY'
    | 'LOWER_BODY'
    | 'LARM'
    | 'RARM'
    | 'LHAND'
    | 'RHAND'
    | 'LFINGER'
    | 'RFINGER'
    | 'LLEG'
    | 'RLEG'
    | 'LFOOT'
    | 'RFOOT';

type RegionDef = {
    id: BodyPartId;
    label: string;
    /** Approximate marker / label anchor in SVG space */
    cx: number;
    cy: number;
};

const REGIONS: RegionDef[] = [
    { id: 'HEAD', label: 'Head', cx: 100, cy: 28 },
    { id: 'NECK', label: 'Neck', cx: 100, cy: 58 },
    { id: 'UPPER_BODY', label: 'Upper Body', cx: 100, cy: 110 },
    { id: 'SPINE', label: 'Spine', cx: 100, cy: 145 },
    { id: 'LOWER_BODY', label: 'Lower Body', cx: 100, cy: 175 },
    { id: 'LARM', label: 'Left Arm', cx: 52, cy: 120 },
    { id: 'RARM', label: 'Right Arm', cx: 148, cy: 120 },
    { id: 'LHAND', label: 'Left Hand', cx: 38, cy: 178 },
    { id: 'RHAND', label: 'Right Hand', cx: 162, cy: 178 },
    { id: 'LFINGER', label: 'Left Fingers', cx: 32, cy: 198 },
    { id: 'RFINGER', label: 'Right Fingers', cx: 168, cy: 198 },
    { id: 'LLEG', label: 'Left Leg', cx: 78, cy: 255 },
    { id: 'RLEG', label: 'Right Leg', cx: 122, cy: 255 },
    { id: 'LFOOT', label: 'Left Foot', cx: 74, cy: 348 },
    { id: 'RFOOT', label: 'Right Foot', cx: 126, cy: 348 },
];

const LABEL_ALIASES: Record<string, BodyPartId> = {
    head: 'HEAD',
    neck: 'NECK',
    spine: 'SPINE',
    'upper body': 'UPPER_BODY',
    torso: 'UPPER_BODY',
    chest: 'UPPER_BODY',
    thorax: 'UPPER_BODY',
    'lower body': 'LOWER_BODY',
    abdomen: 'LOWER_BODY',
    pelvis: 'LOWER_BODY',
    'left arm': 'LARM',
    'right arm': 'RARM',
    'left hand': 'LHAND',
    'right hand': 'RHAND',
    'left hand fingers': 'LFINGER',
    'right hand fingers': 'RFINGER',
    'left fingers': 'LFINGER',
    'right fingers': 'RFINGER',
    'left leg': 'LLEG',
    'right leg': 'RLEG',
    'left foot': 'LFOOT',
    'right foot': 'RFOOT',
};

function resolvePartId(inj: Injury): BodyPartId | null {
    if (inj.id) {
        const up = inj.id.toUpperCase() as BodyPartId;
        if (REGIONS.some((r) => r.id === up)) return up;
    }
    const key = (inj.label || '').trim().toLowerCase();
    return LABEL_ALIASES[key] || null;
}

function severityTone(sev: number) {
    if (sev >= 3) return 'crit';
    if (sev >= 2) return 'severe';
    return 'mild';
}

function fillFor(sev: number | undefined, active: boolean) {
    if (!sev) return active ? 'rgba(255, 58, 58, 0.18)' : 'rgba(138, 128, 134, 0.14)';
    if (sev >= 3) return active ? 'rgba(255, 58, 58, 0.72)' : 'rgba(255, 58, 58, 0.55)';
    if (sev >= 2) return active ? 'rgba(255, 140, 66, 0.7)' : 'rgba(255, 140, 66, 0.5)';
    return active ? 'rgba(255, 210, 76, 0.65)' : 'rgba(255, 210, 76, 0.45)';
}

function strokeFor(sev: number | undefined) {
    if (!sev) return 'rgba(255, 58, 58, 0.28)';
    if (sev >= 3) return '#ff3a3a';
    if (sev >= 2) return '#ff8c42';
    return '#ffd24c';
}

type Props = {
    injuries: Injury[];
    fallbackArea?: string;
};

export default function AnatomyMap({ injuries, fallbackArea }: Props) {
    const byPart = useMemo(() => {
        const map = new Map<BodyPartId, Injury>();
        for (const inj of injuries) {
            const id = resolvePartId(inj);
            if (!id) continue;
            const prev = map.get(id);
            if (!prev || (inj.severity || 0) > (prev.severity || 0)) {
                map.set(id, { ...inj, id });
            }
        }
        // Map fingers onto hand if only fingers damaged — still show finger marker
        return map;
    }, [injuries]);

    const ordered = useMemo(() => {
        const list = [...injuries];
        list.sort((a, b) => (b.severity || 0) - (a.severity || 0));
        return list;
    }, [injuries]);

    const [selected, setSelected] = useState<BodyPartId | null>(null);

    const activeId = useMemo(() => {
        if (selected && byPart.has(selected)) return selected;
        const first = ordered[0] && resolvePartId(ordered[0]);
        return first || null;
    }, [selected, byPart, ordered]);

    const sevOf = (id: BodyPartId) => byPart.get(id)?.severity;

    // Hand severity inherits finger hits for fill
    const handSev = (side: 'L' | 'R') => {
        const hand = side === 'L' ? 'LHAND' : 'RHAND';
        const finger = side === 'L' ? 'LFINGER' : 'RFINGER';
        return Math.max(sevOf(hand) || 0, sevOf(finger) || 0) || undefined;
    };

    return (
        <div className="vm-anatomy">
            <div className="vm-anatomy-head">
                <div className="vm-cell-label">Trauma map</div>
                <div className="vm-anatomy-legend">
                    <span className="leg mild">Mild</span>
                    <span className="leg severe">Severe</span>
                    <span className="leg crit">Critical</span>
                </div>
            </div>

            <div className="vm-anatomy-body">
                <div className="vm-anatomy-stage">
                    <svg
                        className="vm-anatomy-svg"
                        viewBox="0 0 200 370"
                        role="img"
                        aria-label="Anatomical injury map"
                    >
                        <defs>
                            <radialGradient id="vmBodyGlow" cx="50%" cy="30%" r="65%">
                                <stop offset="0%" stopColor="rgba(255,58,58,0.12)" />
                                <stop offset="100%" stopColor="rgba(10,10,12,0)" />
                            </radialGradient>
                            <filter id="vmHitGlow" x="-50%" y="-50%" width="200%" height="200%">
                                <feGaussianBlur stdDeviation="2.2" result="b" />
                                <feMerge>
                                    <feMergeNode in="b" />
                                    <feMergeNode in="SourceGraphic" />
                                </feMerge>
                            </filter>
                            <pattern id="vmGrid" width="10" height="10" patternUnits="userSpaceOnUse">
                                <path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,58,58,0.06)" strokeWidth="1" />
                            </pattern>
                        </defs>

                        <rect width="200" height="370" fill="url(#vmBodyGlow)" />
                        <rect width="200" height="370" fill="url(#vmGrid)" />

                        {/* Silhouette base */}
                        <ellipse cx="100" cy="186" rx="78" ry="160" fill="rgba(55,10,14,0.35)" />

                        {/* HEAD */}
                        <ellipse
                            className={`vm-part ${sevOf('HEAD') ? 'hit' : ''} ${activeId === 'HEAD' ? 'on' : ''}`}
                            cx="100"
                            cy="28"
                            rx="22"
                            ry="26"
                            fill={fillFor(sevOf('HEAD'), activeId === 'HEAD')}
                            stroke={strokeFor(sevOf('HEAD'))}
                            strokeWidth="1.4"
                            onClick={() => byPart.has('HEAD') && setSelected('HEAD')}
                        />
                        {/* Jaw / face detail */}
                        <path
                            d="M86 36 Q100 48 114 36"
                            fill="none"
                            stroke="rgba(255,176,176,0.28)"
                            strokeWidth="1"
                            pointerEvents="none"
                        />

                        {/* NECK */}
                        <rect
                            className={`vm-part ${sevOf('NECK') ? 'hit' : ''} ${activeId === 'NECK' ? 'on' : ''}`}
                            x="90"
                            y="52"
                            width="20"
                            height="16"
                            rx="4"
                            fill={fillFor(sevOf('NECK'), activeId === 'NECK')}
                            stroke={strokeFor(sevOf('NECK'))}
                            strokeWidth="1.3"
                            onClick={() => byPart.has('NECK') && setSelected('NECK')}
                        />

                        {/* UPPER BODY / chest */}
                        <path
                            className={`vm-part ${sevOf('UPPER_BODY') ? 'hit' : ''} ${activeId === 'UPPER_BODY' ? 'on' : ''}`}
                            d="M68 70 C58 78 52 92 52 108 L52 138 C52 148 60 154 72 154 L128 154 C140 154 148 148 148 138 L148 108 C148 92 142 78 132 70 Z"
                            fill={fillFor(sevOf('UPPER_BODY'), activeId === 'UPPER_BODY')}
                            stroke={strokeFor(sevOf('UPPER_BODY'))}
                            strokeWidth="1.4"
                            onClick={() => byPart.has('UPPER_BODY') && setSelected('UPPER_BODY')}
                        />
                        {/* Pectoral split */}
                        <path
                            d="M100 78 L100 150"
                            fill="none"
                            stroke="rgba(255,58,58,0.2)"
                            strokeWidth="1"
                            strokeDasharray="3 3"
                            pointerEvents="none"
                        />

                        {/* SPINE overlay strip */}
                        <rect
                            className={`vm-part ${sevOf('SPINE') ? 'hit' : ''} ${activeId === 'SPINE' ? 'on' : ''}`}
                            x="96"
                            y="78"
                            width="8"
                            height="110"
                            rx="3"
                            fill={
                                sevOf('SPINE')
                                    ? fillFor(sevOf('SPINE'), activeId === 'SPINE')
                                    : 'rgba(255,58,58,0.08)'
                            }
                            stroke={strokeFor(sevOf('SPINE'))}
                            strokeWidth="1.1"
                            onClick={() => byPart.has('SPINE') && setSelected('SPINE')}
                        />

                        {/* LOWER BODY / abdomen-pelvis */}
                        <path
                            className={`vm-part ${sevOf('LOWER_BODY') ? 'hit' : ''} ${activeId === 'LOWER_BODY' ? 'on' : ''}`}
                            d="M72 154 L128 154 C142 154 148 168 146 184 L138 204 C132 214 118 218 100 218 C82 218 68 214 62 204 L54 184 C52 168 58 154 72 154 Z"
                            fill={fillFor(sevOf('LOWER_BODY'), activeId === 'LOWER_BODY')}
                            stroke={strokeFor(sevOf('LOWER_BODY'))}
                            strokeWidth="1.4"
                            onClick={() => byPart.has('LOWER_BODY') && setSelected('LOWER_BODY')}
                        />

                        {/* LEFT ARM (patient left = viewer's right in anatomical? Keep game convention: LARM = left side of screen for patient facing us = our right)
                            In medical diagrams facing patient: patient's right is on viewer's left.
                            Game labels "Left Arm" = patient's left = viewer's right.
                            So LARM goes on the RIGHT side of SVG (higher x).
                        */}
                        <path
                            className={`vm-part ${sevOf('LARM') || handSev('L') ? 'hit' : ''} ${activeId === 'LARM' ? 'on' : ''}`}
                            d="M148 78 C160 82 168 96 170 118 L174 158 C176 170 170 176 160 174 L152 154 L148 120 Z"
                            fill={fillFor(sevOf('LARM') || handSev('L'), activeId === 'LARM')}
                            stroke={strokeFor(sevOf('LARM') || handSev('L'))}
                            strokeWidth="1.3"
                            onClick={() => (byPart.has('LARM') || byPart.has('LHAND') || byPart.has('LFINGER')) && setSelected(byPart.has('LARM') ? 'LARM' : byPart.has('LHAND') ? 'LHAND' : 'LFINGER')}
                        />
                        {/* RIGHT ARM (patient right = viewer's left) */}
                        <path
                            className={`vm-part ${sevOf('RARM') || handSev('R') ? 'hit' : ''} ${activeId === 'RARM' ? 'on' : ''}`}
                            d="M52 78 C40 82 32 96 30 118 L26 158 C24 170 30 176 40 174 L48 154 L52 120 Z"
                            fill={fillFor(sevOf('RARM') || handSev('R'), activeId === 'RARM')}
                            stroke={strokeFor(sevOf('RARM') || handSev('R'))}
                            strokeWidth="1.3"
                            onClick={() => (byPart.has('RARM') || byPart.has('RHAND') || byPart.has('RFINGER')) && setSelected(byPart.has('RARM') ? 'RARM' : byPart.has('RHAND') ? 'RHAND' : 'RFINGER')}
                        />

                        {/* LEFT HAND */}
                        <ellipse
                            className={`vm-part ${handSev('L') ? 'hit' : ''} ${activeId === 'LHAND' || activeId === 'LFINGER' ? 'on' : ''}`}
                            cx="168"
                            cy="188"
                            rx="12"
                            ry="14"
                            fill={fillFor(handSev('L'), activeId === 'LHAND' || activeId === 'LFINGER')}
                            stroke={strokeFor(handSev('L'))}
                            strokeWidth="1.2"
                            onClick={() => (byPart.has('LHAND') || byPart.has('LFINGER') || byPart.has('LARM')) && setSelected(byPart.has('LHAND') ? 'LHAND' : byPart.has('LFINGER') ? 'LFINGER' : 'LARM')}
                        />
                        {/* RIGHT HAND */}
                        <ellipse
                            className={`vm-part ${handSev('R') ? 'hit' : ''} ${activeId === 'RHAND' || activeId === 'RFINGER' ? 'on' : ''}`}
                            cx="32"
                            cy="188"
                            rx="12"
                            ry="14"
                            fill={fillFor(handSev('R'), activeId === 'RHAND' || activeId === 'RFINGER')}
                            stroke={strokeFor(handSev('R'))}
                            strokeWidth="1.2"
                            onClick={() => (byPart.has('RHAND') || byPart.has('RFINGER') || byPart.has('RARM')) && setSelected(byPart.has('RHAND') ? 'RHAND' : byPart.has('RFINGER') ? 'RFINGER' : 'RARM')}
                        />

                        {/* Finger ticks */}
                        {[0, 1, 2, 3].map((i) => (
                            <line
                                key={`lf-${i}`}
                                x1={160 + i * 4}
                                y1="200"
                                x2={158 + i * 5}
                                y2="212"
                                stroke={sevOf('LFINGER') ? strokeFor(sevOf('LFINGER')) : 'rgba(255,176,176,0.28)'}
                                strokeWidth="1.5"
                                strokeLinecap="round"
                                pointerEvents="none"
                            />
                        ))}
                        {[0, 1, 2, 3].map((i) => (
                            <line
                                key={`rf-${i}`}
                                x1={40 - i * 4}
                                y1="200"
                                x2={42 - i * 5}
                                y2="212"
                                stroke={sevOf('RFINGER') ? strokeFor(sevOf('RFINGER')) : 'rgba(255,176,176,0.28)'}
                                strokeWidth="1.5"
                                strokeLinecap="round"
                                pointerEvents="none"
                            />
                        ))}

                        {/* LEFT LEG */}
                        <path
                            className={`vm-part ${sevOf('LLEG') ? 'hit' : ''} ${activeId === 'LLEG' ? 'on' : ''}`}
                            d="M108 214 L132 214 C140 214 144 230 144 250 L146 310 C146 322 138 328 128 326 L116 300 L112 250 Z"
                            fill={fillFor(sevOf('LLEG'), activeId === 'LLEG')}
                            stroke={strokeFor(sevOf('LLEG'))}
                            strokeWidth="1.3"
                            onClick={() => byPart.has('LLEG') && setSelected('LLEG')}
                        />
                        {/* RIGHT LEG */}
                        <path
                            className={`vm-part ${sevOf('RLEG') ? 'hit' : ''} ${activeId === 'RLEG' ? 'on' : ''}`}
                            d="M92 214 L68 214 C60 214 56 230 56 250 L54 310 C54 322 62 328 72 326 L84 300 L88 250 Z"
                            fill={fillFor(sevOf('RLEG'), activeId === 'RLEG')}
                            stroke={strokeFor(sevOf('RLEG'))}
                            strokeWidth="1.3"
                            onClick={() => byPart.has('RLEG') && setSelected('RLEG')}
                        />

                        {/* LEFT FOOT */}
                        <ellipse
                            className={`vm-part ${sevOf('LFOOT') ? 'hit' : ''} ${activeId === 'LFOOT' ? 'on' : ''}`}
                            cx="130"
                            cy="340"
                            rx="16"
                            ry="10"
                            fill={fillFor(sevOf('LFOOT'), activeId === 'LFOOT')}
                            stroke={strokeFor(sevOf('LFOOT'))}
                            strokeWidth="1.2"
                            onClick={() => byPart.has('LFOOT') && setSelected('LFOOT')}
                        />
                        {/* RIGHT FOOT */}
                        <ellipse
                            className={`vm-part ${sevOf('RFOOT') ? 'hit' : ''} ${activeId === 'RFOOT' ? 'on' : ''}`}
                            cx="70"
                            cy="340"
                            rx="16"
                            ry="10"
                            fill={fillFor(sevOf('RFOOT'), activeId === 'RFOOT')}
                            stroke={strokeFor(sevOf('RFOOT'))}
                            strokeWidth="1.2"
                            onClick={() => byPart.has('RFOOT') && setSelected('RFOOT')}
                        />

                        {/* Hit markers */}
                        {REGIONS.map((region) => {
                            const inj = byPart.get(region.id);
                            if (!inj) return null;
                            // Reposition markers for L/R anatomical view
                            let { cx, cy } = region;
                            if (region.id === 'LARM') {
                                cx = 160;
                                cy = 120;
                            }
                            if (region.id === 'RARM') {
                                cx = 40;
                                cy = 120;
                            }
                            if (region.id === 'LHAND' || region.id === 'LFINGER') {
                                cx = 168;
                                cy = 188;
                            }
                            if (region.id === 'RHAND' || region.id === 'RFINGER') {
                                cx = 32;
                                cy = 188;
                            }
                            if (region.id === 'LLEG') {
                                cx = 128;
                                cy = 270;
                            }
                            if (region.id === 'RLEG') {
                                cx = 72;
                                cy = 270;
                            }
                            if (region.id === 'LFOOT') {
                                cx = 130;
                                cy = 340;
                            }
                            if (region.id === 'RFOOT') {
                                cx = 70;
                                cy = 340;
                            }
                            const on = activeId === region.id;
                            return (
                                <g
                                    key={`hit-${region.id}`}
                                    className={`vm-hit-mark ${severityTone(inj.severity)} ${on ? 'on' : ''}`}
                                    transform={`translate(${cx} ${cy})`}
                                    filter="url(#vmHitGlow)"
                                    onClick={() => setSelected(region.id)}
                                    style={{ cursor: 'pointer' }}
                                >
                                    <circle r="9" className="vm-hit-ring" />
                                    <circle r="3.2" className="vm-hit-core" />
                                    <line x1="-6" y1="0" x2="6" y2="0" className="vm-hit-cross" />
                                    <line x1="0" y1="-6" x2="0" y2="6" className="vm-hit-cross" />
                                </g>
                            );
                        })}

                        {/* Side labels */}
                        <text x="18" y="120" className="vm-side-label" textAnchor="middle" transform="rotate(-90 18 120)">
                            R
                        </text>
                        <text x="182" y="120" className="vm-side-label" textAnchor="middle" transform="rotate(90 182 120)">
                            L
                        </text>
                    </svg>
                </div>

                <div className="vm-anatomy-dossier">
                    <div className="vm-cell-label">Injury dossier</div>
                    {ordered.length < 1 ? (
                        <div className="vm-dossier-empty">
                            {fallbackArea && fallbackArea !== 'NONE' && fallbackArea !== 'None'
                                ? `Reported area: ${fallbackArea}`
                                : 'No traumatic injury mapped'}
                        </div>
                    ) : (
                        <ul className="vm-dossier-list">
                            {ordered.map((inj) => {
                                const id = resolvePartId(inj);
                                const on = id && id === activeId;
                                return (
                                    <li key={`${inj.label}-${inj.wound}-${inj.severity}`}>
                                        <button
                                            type="button"
                                            className={`vm-dossier-item ${severityTone(inj.severity)}${on ? ' on' : ''}`}
                                            onClick={() => id && setSelected(id)}
                                        >
                                            <span className="vm-dossier-sev" data-sev={inj.severity} />
                                            <span className="vm-dossier-text">
                                                <strong>{inj.label}</strong>
                                                <em>{inj.wound}</em>
                                            </span>
                                            <span className="vm-dossier-meter">
                                                <i style={{ width: `${(Math.min(4, inj.severity) / 4) * 100}%` }} />
                                            </span>
                                        </button>
                                    </li>
                                );
                            })}
                        </ul>
                    )}

                    <div className="vm-anatomy-scan">
                        <span className="vm-scan-line" />
                        BODY SCAN · {ordered.length} SITE{ordered.length === 1 ? '' : 'S'}
                    </div>
                </div>
            </div>
        </div>
    );
}
